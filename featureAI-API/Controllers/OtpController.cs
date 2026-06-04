using featureAI_API.Models;
using featureAI_API.Services;
using Microsoft.AspNetCore.Mvc;

namespace featureAI_API.Controllers;

[ApiController]
[Route("api")]
public sealed class OtpController : ControllerBase
{
    private readonly IOtpService _otpService;
    private readonly ILogger<OtpController> _logger;
    private readonly IWebHostEnvironment _environment;

    public OtpController(
        IOtpService otpService,
        ILogger<OtpController> logger,
        IWebHostEnvironment environment)
    {
        _otpService = otpService;
        _logger = logger;
        _environment = environment;
    }

    [HttpPost("otp/send")]
    public async Task<ActionResult<SendOtpResponse>> SendOtp(
        [FromBody] SendOtpRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("Sending OTP for purpose {Purpose} to {Phone}", request.Purpose, MaskPhone(request.Phone));
            var response = await _otpService.SendOtpAsync(request, cancellationToken);
            _logger.LogInformation("OTP sent with verification id {VerificationId}", MaskVerificationId(response.VerificationId));
            return Ok(response);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Send OTP request is invalid for {Phone}", MaskPhone(request.Phone));
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Send OTP failed");
            return StatusCode(StatusCodes.Status502BadGateway, BuildError("Không thể gửi mã OTP lúc này.", ex));
        }
    }

    [HttpPost("otp/verify")]
    public async Task<ActionResult<VerifyOtpResponse>> VerifyOtp(
        [FromBody] VerifyOtpRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("Verifying OTP for {VerificationId}", MaskVerificationId(request.VerificationId));
            var response = await _otpService.VerifyOtpAsync(request, cancellationToken);
            _logger.LogInformation(
                "OTP verification result for {VerificationId}: {Verified}",
                MaskVerificationId(request.VerificationId),
                response.Verified);
            return Ok(response);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Verify OTP request is invalid for {VerificationId}", MaskVerificationId(request.VerificationId));
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("auth/reset-password-by-phone")]
    public async Task<ActionResult<ResetPasswordByPhoneResponse>> ResetPasswordByPhone(
        [FromBody] ResetPasswordByPhoneRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("Reset password by phone requested for {VerificationId}", MaskVerificationId(request.VerificationId));
            return Ok(await _otpService.ResetPasswordByPhoneAsync(request, cancellationToken));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Reset password by phone failed");
            return StatusCode(StatusCodes.Status401Unauthorized, BuildError(ex.Message, ex));
        }
    }

    private object BuildError(string message, Exception exception)
    {
        return new
        {
            message,
            detail = _environment.IsDevelopment() ? exception.Message : null
        };
    }

    private static string MaskVerificationId(string? verificationId)
    {
        if (string.IsNullOrWhiteSpace(verificationId)) return "(empty)";
        var parts = verificationId.Split(':', 3);
        if (parts.Length != 3) return "(invalid)";
        return $"{parts[0]}:{parts[1]}:{MaskPhone(parts[2])}";
    }

    private static string MaskPhone(string? phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return "(empty)";
        var digits = new string(phone.Where(char.IsDigit).ToArray());
        if (digits.Length <= 4) return "***";
        return $"***{digits[^4..]}";
    }
}
