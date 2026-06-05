using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using featureAI_API.Models;
using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Caching.Memory;

namespace featureAI_API.Services;

public interface IOtpService
{
    Task<SendOtpResponse> SendOtpAsync(
        SendOtpRequest request,
        string clientIp,
        CancellationToken cancellationToken);

    Task<VerifyOtpResponse> VerifyOtpAsync(VerifyOtpRequest request, CancellationToken cancellationToken);

    Task<ResetPasswordByPhoneResponse> ResetPasswordByPhoneAsync(
        ResetPasswordByPhoneRequest request,
        CancellationToken cancellationToken);
}

public sealed class OtpService : IOtpService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private static readonly Regex OtpRegex = new(@"^\d{6}$", RegexOptions.Compiled);
    private static readonly TimeSpan OtpTtl = TimeSpan.FromMinutes(5);

    // Các ngưỡng này bảo vệ chi phí SMS trước các hành vi bấm gửi liên tục.
    // Khi chạy production nhiều instance, chuyển counter sang Redis hoặc DB.
    private static readonly TimeSpan SendCooldown = TimeSpan.FromSeconds(60);
    private static readonly TimeSpan PhoneDailyWindow = TimeSpan.FromDays(1);
    private static readonly TimeSpan IpHourlyWindow = TimeSpan.FromHours(1);
    private static readonly TimeSpan IpPhoneBurstWindow = TimeSpan.FromMinutes(10);

    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly IMemoryCache _cache;
    private readonly ILogger<OtpService> _logger;

    public OtpService(
        HttpClient httpClient,
        IConfiguration configuration,
        IMemoryCache cache,
        ILogger<OtpService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _cache = cache;
        _logger = logger;
    }

    public async Task<SendOtpResponse> SendOtpAsync(
        SendOtpRequest request,
        string clientIp,
        CancellationToken cancellationToken)
    {
        var purpose = NormalizePurpose(request.Purpose);
        var phone = NormalizeVnPhone(request.Phone);
        EnforceSendRateLimits(purpose, phone, clientIp);

        var otp = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var contentTemplate =
            _configuration["SpeedSms:OtpContent"] ??
            "Ma xac thuc CoinNest cua ban la {pin_code}. Ma co hieu luc trong 5 phut.";

        await SendSmsAsync(
            phone.Local,
            contentTemplate.Replace("{pin_code}", otp, StringComparison.Ordinal),
            cancellationToken);

        _cache.Set(
            BuildOtpCacheKey(purpose, phone.Digits),
            new OtpEntry(HashOtp(purpose, phone.E164, otp), 5),
            OtpTtl);

        return new SendOtpResponse($"speedsms:{purpose.Value}:{phone.E164}");
    }

    private void EnforceSendRateLimits(OtpPurpose purpose, VnPhone phone, string clientIp)
    {
        var normalizedIp = string.IsNullOrWhiteSpace(clientIp) ? "unknown" : clientIp.Trim();
        var phoneKey = $"{purpose.Value}:{phone.Digits}";
        var ipKey = $"{purpose.Value}:{normalizedIp}";
        var ipPhoneKey = $"{purpose.Value}:{normalizedIp}:{phone.Digits}";

        // Cooldown theo số điện thoại giúp chặn gửi lại ngay lập tức,
        // kể cả khi người dùng spam nút trong app hoặc gọi thẳng API.
        if (_cache.TryGetValue(BuildCooldownCacheKey(phoneKey), out _))
        {
            throw new InvalidOperationException("Vui lòng chờ 60 giây trước khi gửi lại mã OTP.");
        }

        // Giới hạn theo số điện thoại kiểm soát chi phí trực tiếp cho từng người nhận.
        if (IncrementCounter(BuildPhoneDailyCacheKey(phoneKey), PhoneDailyWindow) > 5)
        {
            throw new InvalidOperationException("Số điện thoại này đã yêu cầu quá nhiều mã OTP trong hôm nay.");
        }

        // Giới hạn theo IP chặn một nguồn gửi thử nhiều số điện thoại khác nhau.
        if (IncrementCounter(BuildIpHourlyCacheKey(ipKey), IpHourlyWindow) > 20)
        {
            throw new InvalidOperationException("Thiết bị hoặc mạng này đang gửi quá nhiều yêu cầu OTP. Vui lòng thử lại sau.");
        }

        // Giới hạn theo cặp IP + số điện thoại chặn spam ngắn hạn trước khi
        // chạm tới ngưỡng ngày của số điện thoại.
        if (IncrementCounter(BuildIpPhoneBurstCacheKey(ipPhoneKey), IpPhoneBurstWindow) > 3)
        {
            throw new InvalidOperationException("Bạn đã yêu cầu OTP quá nhiều lần trong thời gian ngắn. Vui lòng thử lại sau 10 phút.");
        }

        _cache.Set(BuildCooldownCacheKey(phoneKey), true, SendCooldown);
    }

    private int IncrementCounter(string key, TimeSpan ttl)
    {
        // IMemoryCache không bền qua restart backend
        var next = _cache.TryGetValue<RateLimitCounter>(key, out var counter) && counter is not null
            ? counter.Count + 1
            : 1;
        _cache.Set(key, new RateLimitCounter(next), ttl);
        return next;
    }

    public Task<VerifyOtpResponse> VerifyOtpAsync(
        VerifyOtpRequest request,
        CancellationToken cancellationToken)
    {
        var (purpose, phone) = ParseVerificationId(request.VerificationId);
        var verified = VerifyOtp(purpose, phone, request.OtpCode);

        if (verified && purpose == OtpPurpose.ForgotPassword)
        {
            _cache.Set(BuildVerifiedCacheKey(purpose, phone.Digits), true, OtpTtl);
        }

        return Task.FromResult(new VerifyOtpResponse(verified));
    }

    public async Task<ResetPasswordByPhoneResponse> ResetPasswordByPhoneAsync(
        ResetPasswordByPhoneRequest request,
        CancellationToken cancellationToken)
    {
        var (purpose, phone) = ParseVerificationId(request.VerificationId);
        if (purpose != OtpPurpose.ForgotPassword)
        {
            throw new ArgumentException("VerificationId không đúng luồng quên mật khẩu.");
        }

        if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 8)
        {
            throw new ArgumentException("Mật khẩu mới phải có ít nhất 8 ký tự.");
        }

        var hasRecentVerification = _cache.TryGetValue(
            BuildVerifiedCacheKey(purpose, phone.Digits),
            out bool verifiedMarker) && verifiedMarker;
        var verified = hasRecentVerification || VerifyOtp(purpose, phone, request.OtpCode);
        if (!verified)
        {
            throw new InvalidOperationException("Mã OTP không hợp lệ hoặc đã hết hạn.");
        }

        var auth = GetFirebaseAuth();
        var syntheticEmail = $"{phone.Digits}@phone.coinnest.app";
        try
        {
            var user = await auth.GetUserByEmailAsync(syntheticEmail, cancellationToken);
            await auth.UpdateUserAsync(
                new UserRecordArgs
                {
                    Uid = user.Uid,
                    Password = request.NewPassword
                },
                cancellationToken);
            await auth.RevokeRefreshTokensAsync(user.Uid, cancellationToken);
            _cache.Remove(BuildVerifiedCacheKey(purpose, phone.Digits));

            return new ResetPasswordByPhoneResponse(true);
        }
        catch (FirebaseAuthException ex)
        {
            _logger.LogWarning(ex, "Firebase password reset by phone failed for {Phone}", phone.E164);
            throw new InvalidOperationException(
                "Đặt lại mật khẩu thất bại. Vui lòng thử lại.",
                ex);
        }
    }

    private async Task SendSmsAsync(
        string phone,
        string content,
        CancellationToken cancellationToken)
    {
        var accessToken = _configuration["SpeedSms:AccessToken"];
        var sender = _configuration["SpeedSms:SmsSender"];
        var smsType = int.TryParse(_configuration["SpeedSms:SmsType"], out var parsedSmsType)
            ? parsedSmsType
            : 5;

        if (string.IsNullOrWhiteSpace(accessToken))
        {
            throw new InvalidOperationException("SpeedSms:AccessToken chưa được cấu hình.");
        }

        if (string.IsNullOrWhiteSpace(sender))
        {
            throw new InvalidOperationException("SpeedSms:SmsSender chưa được cấu hình.");
        }

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "sms/send");
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue(
            "Basic",
            Convert.ToBase64String(Encoding.UTF8.GetBytes($"{accessToken}:x")));
        httpRequest.Content = new StringContent(
            JsonSerializer.Serialize(
                new
                {
                    to = new[] { phone },
                    content,
                    sms_type = smsType,
                    sender
                },
                JsonOptions),
            Encoding.UTF8,
            "application/json");

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"SpeedSMS returned {(int)response.StatusCode}: {TrimForLog(responseBody)}");
        }

        using var document = JsonDocument.Parse(responseBody);
        if (document.RootElement.TryGetProperty("status", out var status) &&
            string.Equals(status.GetString(), "error", StringComparison.OrdinalIgnoreCase))
        {
            var message = document.RootElement.TryGetProperty("message", out var messageElement)
                ? messageElement.GetString()
                : "SpeedSMS không gửi được OTP.";
            throw new InvalidOperationException(message);
        }
    }

    private bool VerifyOtp(OtpPurpose purpose, VnPhone phone, string otpCode)
    {
        var code = otpCode?.Trim() ?? string.Empty;
        if (!OtpRegex.IsMatch(code)) return false;

        var cacheKey = BuildOtpCacheKey(purpose, phone.Digits);
        if (!_cache.TryGetValue<OtpEntry>(cacheKey, out var entry) || entry is null)
        {
            return false;
        }

        if (entry.AttemptsLeft <= 0)
        {
            _cache.Remove(cacheKey);
            return false;
        }

        var verified = string.Equals(
            entry.OtpHash,
            HashOtp(purpose, phone.E164, code),
            StringComparison.Ordinal);
        if (verified)
        {
            _cache.Remove(cacheKey);
            return true;
        }

        _cache.Set(cacheKey, entry with { AttemptsLeft = entry.AttemptsLeft - 1 }, OtpTtl);
        return false;
    }

    private FirebaseAuth GetFirebaseAuth()
    {
        var app = FirebaseApp.DefaultInstance ?? InitializeFirebaseApp();
        return FirebaseAuth.GetAuth(app);
    }

    private FirebaseApp InitializeFirebaseApp()
    {
        var credentialJson = _configuration["Firebase:ServiceAccountJson"];
        var credentialPath = _configuration["Firebase:ServiceAccountPath"];
        GoogleCredential credential;

        if (!string.IsNullOrWhiteSpace(credentialJson))
        {
            credential = GoogleCredential.FromJson(credentialJson);
        }
        else if (!string.IsNullOrWhiteSpace(credentialPath))
        {
            credential = GoogleCredential.FromFile(credentialPath);
        }
        else
        {
            throw new InvalidOperationException(
                "Firebase:ServiceAccountJson hoặc Firebase:ServiceAccountPath chưa được cấu hình.");
        }

        return FirebaseApp.Create(new AppOptions { Credential = credential });
    }

    private string HashOtp(OtpPurpose purpose, string phoneE164, string otp)
    {
        var secret =
            _configuration["SpeedSms:OtpHashSecret"] ??
            _configuration["SpeedSms:AccessToken"] ??
            throw new InvalidOperationException("SpeedSms:AccessToken chưa được cấu hình.");
        var payload = $"{purpose.Value}:{phoneE164}:{otp}";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(payload)));
    }

    private static (OtpPurpose Purpose, VnPhone Phone) ParseVerificationId(string verificationId)
    {
        var parts = (verificationId ?? string.Empty).Split(':', 3);
        if (parts.Length != 3 || parts[0] != "speedsms")
        {
            throw new ArgumentException("VerificationId không hợp lệ.");
        }

        return (NormalizePurpose(parts[1]), NormalizeVnPhone(parts[2]));
    }

    private static OtpPurpose NormalizePurpose(string purpose)
    {
        return purpose?.Trim() switch
        {
            "register_phone" => OtpPurpose.RegisterPhone,
            "forgot_password" => OtpPurpose.ForgotPassword,
            _ => throw new ArgumentException("Mục đích OTP không hợp lệ.")
        };
    }

    private static VnPhone NormalizeVnPhone(string rawPhone)
    {
        var clean = Regex.Replace(rawPhone ?? string.Empty, @"[^\d+]", string.Empty);
        string local;

        if (clean.StartsWith("+84", StringComparison.Ordinal))
        {
            local = clean[3..];
        }
        else if (clean.StartsWith("84", StringComparison.Ordinal))
        {
            local = clean[2..];
        }
        else
        {
            local = clean;
        }

        if (local.StartsWith('0'))
        {
            local = local[1..];
        }

        if (!Regex.IsMatch(local, @"^\d{9}$"))
        {
            throw new ArgumentException("Số điện thoại không hợp lệ.");
        }

        return new VnPhone($"+84{local}", $"0{local}", $"84{local}");
    }

    private static string BuildOtpCacheKey(OtpPurpose purpose, string phoneDigits) =>
        $"otp:{purpose.Value}:{phoneDigits}";

    private static string BuildVerifiedCacheKey(OtpPurpose purpose, string phoneDigits) =>
        $"otp-verified:{purpose.Value}:{phoneDigits}";

    private static string BuildCooldownCacheKey(string key) => $"otp-send-cooldown:{key}";

    private static string BuildPhoneDailyCacheKey(string key) => $"otp-send-phone-day:{key}";

    private static string BuildIpHourlyCacheKey(string key) => $"otp-send-ip-hour:{key}";

    private static string BuildIpPhoneBurstCacheKey(string key) => $"otp-send-ip-phone-burst:{key}";

    private static string TrimForLog(string value) =>
        value.Length <= 600 ? value : value[..600];

    private sealed record VnPhone(string E164, string Local, string Digits);

    private sealed record OtpPurpose(string Value)
    {
        public static readonly OtpPurpose RegisterPhone = new("register_phone");
        public static readonly OtpPurpose ForgotPassword = new("forgot_password");
    }

    private sealed record OtpEntry(string OtpHash, int AttemptsLeft);

    private sealed record RateLimitCounter(int Count);
}
