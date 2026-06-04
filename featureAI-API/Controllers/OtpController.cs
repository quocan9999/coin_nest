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
            return Ok(await _otpService.SendOtpAsync(request, cancellationToken));
        }
        catch (ArgumentException ex)
        {
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
            return Ok(await _otpService.VerifyOtpAsync(request, cancellationToken));
        }
        catch (ArgumentException ex)
        {
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
}
