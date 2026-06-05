namespace featureAI_API.Models;

public sealed record SendOtpRequest(string Phone, string Purpose);

public sealed record SendOtpResponse(string VerificationId);

public sealed record VerifyOtpRequest(string VerificationId, string OtpCode);

public sealed record VerifyOtpResponse(bool Verified);

public sealed record ResetPasswordByPhoneRequest(
    string VerificationId,
    string OtpCode,
    string NewPassword);

public sealed record ResetPasswordByPhoneResponse(bool Ok);
