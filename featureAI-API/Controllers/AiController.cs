using featureAI_API.Models;
using featureAI_API.Services;
using Microsoft.AspNetCore.Mvc;

namespace featureAI_API.Controllers;

[ApiController]
[Route("api/ai")]
public sealed class AiController : ControllerBase
{
    private readonly IOpenRouterService _openRouterService;
    private readonly ILogger<AiController> _logger;
    private readonly IWebHostEnvironment _environment;

    public AiController(
        IOpenRouterService openRouterService,
        ILogger<AiController> logger,
        IWebHostEnvironment environment)
    {
        _openRouterService = openRouterService;
        _logger = logger;
        _environment = environment;
    }

    [HttpPost("spending-insight")]
    public async Task<ActionResult<SpendingInsightResponse>> CreateSpendingInsight(
        [FromBody] SpendingInsightRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var insight = await _openRouterService.GenerateSpendingInsightAsync(request, cancellationToken);
            return Ok(insight);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "AI spending insight failed");
            return StatusCode(StatusCodes.Status502BadGateway, new
            {
                message = "Không thể tạo gợi ý tiết kiệm lúc này. Vui lòng thử lại sau.",
                detail = _environment.IsDevelopment() ? BuildDebugDetail(ex) : null
            });
        }
    }

    private static string BuildDebugDetail(Exception exception)
    {
        var messages = new List<string>();
        var current = exception;

        while (current != null)
        {
            messages.Add(current.Message);
            current = current.InnerException;
        }

        return string.Join(" | ", messages);
    }
}
