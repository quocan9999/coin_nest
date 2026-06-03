using System.Net.Http.Headers;
using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using featureAI_API.Models;

namespace featureAI_API.Services;

public interface IOpenRouterService
{
    Task<SpendingInsightResponse> GenerateSpendingInsightAsync(
        SpendingInsightRequest request,
        CancellationToken cancellationToken);

    Task<FinancialAssistantResponse> GenerateFinancialAssistantAsync(
        FinancialAssistantRequest request,
        CancellationToken cancellationToken);
}

public sealed class OpenRouterService : IOpenRouterService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private static readonly object ModelLock = new();
    private static string? _preferredProvider;
    private static string? _preferredModel;

    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<OpenRouterService> _logger;

    public OpenRouterService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<OpenRouterService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<SpendingInsightResponse> GenerateSpendingInsightAsync(
        SpendingInsightRequest request,
        CancellationToken cancellationToken)
    {
        ValidateRequest(request);

        Exception? lastError = null;

        var attempts = BuildProviderAttempts();
        for (var attempt = 0; attempt < attempts.Count; attempt++)
        {
            var providerModel = attempts[attempt];
            try
            {
                var insight = await CallProviderAsync(providerModel, request, cancellationToken);
                MarkModelSuccessful(providerModel.Provider, providerModel.Model);
                return insight;
            }
            catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or InvalidOperationException or JsonException)
            {
                _logger.LogWarning(
                    ex,
                    "AI provider {Provider} model {Model} failed on attempt {Attempt}",
                    providerModel.Provider,
                    providerModel.Model,
                    attempt + 1);
                lastError = ex;
            }
        }

        throw new InvalidOperationException("AI spending insight could not be generated.", lastError);
    }

    public async Task<FinancialAssistantResponse> GenerateFinancialAssistantAsync(
        FinancialAssistantRequest request,
        CancellationToken cancellationToken)
    {
        ValidateAssistantRequest(request);

        if (IsLikelyOutOfScopeQuestion(request.Question))
        {
            return BuildSafeAssistantRefusal();
        }

        Exception? lastError = null;

        var attempts = BuildProviderAttempts();
        for (var attempt = 0; attempt < attempts.Count; attempt++)
        {
            var providerModel = attempts[attempt];
            try
            {
                var response = await CallProviderForAssistantAsync(providerModel, request, cancellationToken);
                MarkModelSuccessful(providerModel.Provider, providerModel.Model);
                return response;
            }
            catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or InvalidOperationException or JsonException)
            {
                _logger.LogWarning(
                    ex,
                    "AI assistant provider {Provider} model {Model} failed on attempt {Attempt}",
                    providerModel.Provider,
                    providerModel.Model,
                    attempt + 1);
                lastError = ex;
            }
        }

        throw new InvalidOperationException("AI financial assistant could not be generated.", lastError);
    }

    private Task<SpendingInsightResponse> CallProviderAsync(
        ProviderModel providerModel,
        SpendingInsightRequest request,
        CancellationToken cancellationToken)
    {
        return providerModel.Provider switch
        {
            "Groq" => CallOpenAiCompatibleAsync(
                providerModel,
                _configuration["Groq:ApiKey"],
                new Uri("https://api.groq.com/openai/v1/chat/completions"),
                request,
                cancellationToken),
            "GitHub Models" => CallOpenAiCompatibleAsync(
                providerModel,
                _configuration["GitHubModels:Token"],
                new Uri("https://models.github.ai/inference/chat/completions"),
                request,
                cancellationToken,
                requestMessage =>
                {
                    requestMessage.Headers.TryAddWithoutValidation("Accept", "application/vnd.github+json");
                    requestMessage.Headers.TryAddWithoutValidation("X-GitHub-Api-Version", "2026-03-10");
                }),
            "Gemini" => CallGeminiAsync(providerModel, request, cancellationToken),
            "OpenRouter" => CallOpenAiCompatibleAsync(
                providerModel,
                _configuration["OpenRouter:ApiKey"],
                new Uri("https://openrouter.ai/api/v1/chat/completions"),
                request,
                cancellationToken,
                requestMessage =>
                {
                    requestMessage.Headers.TryAddWithoutValidation("HTTP-Referer", "https://coinnest.local");
                    requestMessage.Headers.TryAddWithoutValidation("X-Title", "CoinNest");
                }),
            _ => throw new InvalidOperationException($"Unsupported AI provider: {providerModel.Provider}")
        };
    }

    private Task<FinancialAssistantResponse> CallProviderForAssistantAsync(
        ProviderModel providerModel,
        FinancialAssistantRequest request,
        CancellationToken cancellationToken)
    {
        return providerModel.Provider switch
        {
            "Groq" => CallOpenAiCompatibleAssistantAsync(
                providerModel,
                _configuration["Groq:ApiKey"],
                new Uri("https://api.groq.com/openai/v1/chat/completions"),
                request,
                cancellationToken),
            "GitHub Models" => CallOpenAiCompatibleAssistantAsync(
                providerModel,
                _configuration["GitHubModels:Token"],
                new Uri("https://models.github.ai/inference/chat/completions"),
                request,
                cancellationToken,
                requestMessage =>
                {
                    requestMessage.Headers.TryAddWithoutValidation("Accept", "application/vnd.github+json");
                    requestMessage.Headers.TryAddWithoutValidation("X-GitHub-Api-Version", "2026-03-10");
                }),
            "Gemini" => CallGeminiAssistantAsync(providerModel, request, cancellationToken),
            "OpenRouter" => CallOpenAiCompatibleAssistantAsync(
                providerModel,
                _configuration["OpenRouter:ApiKey"],
                new Uri("https://openrouter.ai/api/v1/chat/completions"),
                request,
                cancellationToken,
                requestMessage =>
                {
                    requestMessage.Headers.TryAddWithoutValidation("HTTP-Referer", "https://coinnest.local");
                    requestMessage.Headers.TryAddWithoutValidation("X-Title", "CoinNest");
                }),
            _ => throw new InvalidOperationException($"Unsupported AI provider: {providerModel.Provider}")
        };
    }

    private async Task<SpendingInsightResponse> CallOpenAiCompatibleAsync(
        ProviderModel providerModel,
        string? apiKey,
        Uri endpoint,
        SpendingInsightRequest request,
        CancellationToken cancellationToken,
        Action<HttpRequestMessage>? configureRequest = null)
    {
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException($"{providerModel.Provider} API key is not configured.");
        }

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "chat/completions");
        httpRequest.RequestUri = endpoint;
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        configureRequest?.Invoke(httpRequest);

        var promptPayload = JsonSerializer.Serialize(request, JsonOptions);
        var payload = new
        {
            model = providerModel.Model,
            messages = BuildChatMessages(promptPayload),
            temperature = 0.2,
            max_tokens = 700
        };

        httpRequest.Content = new StringContent(
            JsonSerializer.Serialize(payload, JsonOptions),
            Encoding.UTF8,
            "application/json");

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"{providerModel.Provider} model '{providerModel.Model}' returned {(int)response.StatusCode}: {TrimForLog(responseJson)}");
        }

        using var document = JsonDocument.Parse(responseJson);
        var root = document.RootElement;
        var actualModel = root.TryGetProperty("model", out var modelElement)
            ? modelElement.GetString() ?? providerModel.Model
            : providerModel.Model;
        var content = root
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(content) ||
            content.Contains("<script", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"AI response was outside the allowed JSON format: {TrimForLog(content)}");
        }

        var jsonContent = ExtractJsonObject(content);
        using var insightDocument = JsonDocument.Parse(jsonContent);
        var insight = ParseAiContent(insightDocument.RootElement);

        return NormalizeInsight(insight, $"{providerModel.Provider}: {actualModel}");
    }

    private async Task<SpendingInsightResponse> CallGeminiAsync(
        ProviderModel providerModel,
        SpendingInsightRequest request,
        CancellationToken cancellationToken)
    {
        var apiKey = _configuration["Gemini:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("Gemini API key is not configured.");
        }

        var endpoint = new Uri(
            $"https://generativelanguage.googleapis.com/v1beta/models/{providerModel.Model}:generateContent?key={Uri.EscapeDataString(apiKey)}");
        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, endpoint);
        var promptPayload = JsonSerializer.Serialize(request, JsonOptions);
        var payload = new
        {
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new[]
                    {
                        new
                        {
                            text = $"{SystemPrompt}\n\n{BuildUserPrompt(promptPayload)}"
                        }
                    }
                }
            },
            generationConfig = new
            {
                temperature = 0.2,
                maxOutputTokens = 700
            }
        };

        httpRequest.Content = new StringContent(
            JsonSerializer.Serialize(payload, JsonOptions),
            Encoding.UTF8,
            "application/json");

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Gemini model '{providerModel.Model}' returned {(int)response.StatusCode}: {TrimForLog(responseJson)}");
        }

        using var document = JsonDocument.Parse(responseJson);
        var content = document.RootElement
            .GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString();

        if (string.IsNullOrWhiteSpace(content) ||
            content.Contains("<script", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"AI response was outside the allowed JSON format: {TrimForLog(content)}");
        }

        var jsonContent = ExtractJsonObject(content);
        using var insightDocument = JsonDocument.Parse(jsonContent);
        var insight = ParseAiContent(insightDocument.RootElement);

        return NormalizeInsight(insight, $"Gemini: {providerModel.Model}");
    }

    private async Task<FinancialAssistantResponse> CallOpenAiCompatibleAssistantAsync(
        ProviderModel providerModel,
        string? apiKey,
        Uri endpoint,
        FinancialAssistantRequest request,
        CancellationToken cancellationToken,
        Action<HttpRequestMessage>? configureRequest = null)
    {
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException($"{providerModel.Provider} API key is not configured.");
        }

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "chat/completions");
        httpRequest.RequestUri = endpoint;
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        configureRequest?.Invoke(httpRequest);

        var promptPayload = JsonSerializer.Serialize(request, JsonOptions);
        var payload = new
        {
            model = providerModel.Model,
            messages = BuildAssistantChatMessages(promptPayload),
            temperature = 0.25,
            max_tokens = 900
        };

        httpRequest.Content = new StringContent(
            JsonSerializer.Serialize(payload, JsonOptions),
            Encoding.UTF8,
            "application/json");

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"{providerModel.Provider} model '{providerModel.Model}' returned {(int)response.StatusCode}: {TrimForLog(responseJson)}");
        }

        using var document = JsonDocument.Parse(responseJson);
        var root = document.RootElement;
        var actualModel = root.TryGetProperty("model", out var modelElement)
            ? modelElement.GetString() ?? providerModel.Model
            : providerModel.Model;
        var content = root
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        return NormalizeAssistantResponse(content, $"{providerModel.Provider}: {actualModel}");
    }

    private async Task<FinancialAssistantResponse> CallGeminiAssistantAsync(
        ProviderModel providerModel,
        FinancialAssistantRequest request,
        CancellationToken cancellationToken)
    {
        var apiKey = _configuration["Gemini:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("Gemini API key is not configured.");
        }

        var endpoint = new Uri(
            $"https://generativelanguage.googleapis.com/v1beta/models/{providerModel.Model}:generateContent?key={Uri.EscapeDataString(apiKey)}");
        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, endpoint);
        var promptPayload = JsonSerializer.Serialize(request, JsonOptions);
        var payload = new
        {
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new[]
                    {
                        new
                        {
                            text = $"{AssistantSystemPrompt}\n\n{BuildAssistantUserPrompt(promptPayload)}"
                        }
                    }
                }
            },
            generationConfig = new
            {
                temperature = 0.25,
                maxOutputTokens = 900
            }
        };

        httpRequest.Content = new StringContent(
            JsonSerializer.Serialize(payload, JsonOptions),
            Encoding.UTF8,
            "application/json");

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var responseJson = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Gemini model '{providerModel.Model}' returned {(int)response.StatusCode}: {TrimForLog(responseJson)}");
        }

        using var document = JsonDocument.Parse(responseJson);
        var content = document.RootElement
            .GetProperty("candidates")[0]
            .GetProperty("content")
            .GetProperty("parts")[0]
            .GetProperty("text")
            .GetString();

        return NormalizeAssistantResponse(content, $"Gemini: {providerModel.Model}");
    }

    private static SpendingInsightResponse NormalizeInsight(AiContent insight, string model)
    {
        var title = string.IsNullOrWhiteSpace(insight.Title)
            ? "Gợi ý tiết kiệm tháng này"
            : FormatMoneyText(insight.Title.Trim());
        var summary = string.IsNullOrWhiteSpace(insight.Summary)
            ? "CoinNest đã phân tích tóm tắt tài chính tháng này và đưa ra một số gợi ý cần chú ý."
            : FormatMoneyText(insight.Summary.Trim());

        var severity = insight.Severity?.Trim().ToLowerInvariant();
        severity = severity switch
        {
            "safe" or "stable" or "normal" => "low",
            "warning" or "moderate" or "caution" => "medium",
            "critical" or "danger" or "urgent" => "high",
            _ => severity
        };

        if (severity is not ("low" or "medium" or "high"))
        {
            severity = "medium";
        }

        var alerts = (insight.Alerts ?? Array.Empty<string>())
            .Select(item => item.Trim())
            .Where(item => item.Length > 0)
            .Select(FormatMoneyText)
            .Take(5)
            .ToArray();
        var savingTips = (insight.SavingTips ?? Array.Empty<string>())
            .Select(item => item.Trim())
            .Where(item => item.Length > 0)
            .Select(FormatMoneyText)
            .Take(5)
            .ToArray();

        if (LooksUnsafe(title) || LooksUnsafe(summary) ||
            alerts.Any(LooksUnsafe) || savingTips.Any(LooksUnsafe))
        {
            throw new InvalidOperationException("AI response contains unsupported content.");
        }

        return new SpendingInsightResponse(
            title,
            summary,
            severity,
            alerts,
            savingTips,
            model,
            DateTimeOffset.UtcNow);
    }

    private static bool LooksUnsafe(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return false;

        return value.Contains("```", StringComparison.Ordinal) ||
               value.Contains("function ", StringComparison.OrdinalIgnoreCase) ||
               value.Contains("class ", StringComparison.OrdinalIgnoreCase) ||
               value.Contains("import ", StringComparison.OrdinalIgnoreCase) ||
               value.Contains("SELECT ", StringComparison.OrdinalIgnoreCase) ||
               value.Contains("<html", StringComparison.OrdinalIgnoreCase) ||
               value.Contains("<script", StringComparison.OrdinalIgnoreCase);
    }

    private static string TrimForLog(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return "(empty)";

        return value.Length <= 600 ? value : value[..600];
    }

    private static string SystemPrompt =>
        "You are CoinNest finance insight AI. Only analyze Vietnamese personal finance summaries. Return exactly one JSON object, no markdown, no code fence, no prose. Required keys: title, summary, severity, alerts, savingTips. severity must be low, medium, or high. alerts and savingTips must be arrays of Vietnamese strings. Format every money value as Vietnamese currency with dot thousands and the đ suffix, for example 2850000 must be written as 2.850.000 đ. Refuse non-finance or coding tasks by returning a finance-safe warning in the same JSON schema.";

    private static string BuildUserPrompt(string promptPayload) =>
        $"Analyze this monthly finance summary and return Vietnamese JSON only. Example shape: {{\"title\":\"...\",\"summary\":\"...\",\"severity\":\"medium\",\"alerts\":[\"...\"],\"savingTips\":[\"...\"]}}. Data: {promptPayload}";

    private static string AssistantSystemPrompt =>
        "You are CoinNest financial assistant for Vietnamese personal finance. Only answer questions about the user's CoinNest report, spending, income, budgets, accounts, debts, loans, saving, and cash-flow. Refuse coding, website, HTML, scripts, SQL, legal, medical, investing speculation, and unrelated tasks. Return exactly one JSON object, no markdown, no code fence, no prose. Required keys: answer, suggestedQuestions. answer must be natural Vietnamese, concise, and based only on the provided CoinNest summaries. suggestedQuestions must be 2 to 4 Vietnamese finance questions. Never output code, HTML, CSS, JavaScript, SQL, or step-by-step programming instructions. Format every money value as Vietnamese currency with dot thousands and the đ suffix.";

    private static string BuildAssistantUserPrompt(string promptPayload) =>
        $"Answer the user's finance question using only this CoinNest context. Return Vietnamese JSON only. Example shape: {{\"answer\":\"...\",\"suggestedQuestions\":[\"...\",\"...\"]}}. Data: {promptPayload}";

    private static object[] BuildChatMessages(string promptPayload)
    {
        return new object[]
        {
            new
            {
                role = "system",
                content = SystemPrompt
            },
            new
            {
                role = "user",
                content = BuildUserPrompt(promptPayload)
            }
        };
    }

    private static object[] BuildAssistantChatMessages(string promptPayload)
    {
        return new object[]
        {
            new
            {
                role = "system",
                content = AssistantSystemPrompt
            },
            new
            {
                role = "user",
                content = BuildAssistantUserPrompt(promptPayload)
            }
        };
    }

    private static FinancialAssistantResponse NormalizeAssistantResponse(string? content, string model)
    {
        if (string.IsNullOrWhiteSpace(content) ||
            content.Contains("<script", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"AI response was outside the allowed assistant JSON format: {TrimForLog(content)}");
        }

        var jsonContent = ExtractJsonObject(content);
        using var document = JsonDocument.Parse(jsonContent);
        var root = document.RootElement;
        var answer = GetString(root, "answer", "message", "reply")?.Trim();
        var suggestions = GetStringList(root, "suggestedQuestions", "suggested_questions", "suggestions")
            .Select(item => FormatMoneyText(item.Trim()))
            .Where(item => item.Length > 0)
            .Take(4)
            .ToArray();

        if (string.IsNullOrWhiteSpace(answer))
        {
            throw new InvalidOperationException("AI response does not contain an answer.");
        }

        answer = FormatMoneyText(answer);
        if (LooksUnsafe(answer) || suggestions.Any(LooksUnsafe))
        {
            throw new InvalidOperationException("AI response contains unsupported content.");
        }

        if (suggestions.Length == 0)
        {
            suggestions = DefaultAssistantQuestions;
        }

        return new FinancialAssistantResponse(
            answer,
            suggestions,
            model,
            DateTimeOffset.UtcNow);
    }

    private static string FormatMoneyText(string value)
    {
        return Regex.Replace(
            value,
            @"(?<![\w.])(\d{5,})(?:\s*(?:VND|VNĐ|đ|d))?(?![\w.]|\s*%)",
            match =>
            {
                if (!long.TryParse(match.Groups[1].Value, out var amount))
                {
                    return match.Value;
                }

                return amount.ToString("N0", CultureInfo.GetCultureInfo("vi-VN")) + " đ";
            },
            RegexOptions.IgnoreCase);
    }

    private static string ExtractJsonObject(string content)
    {
        var trimmed = content.Trim();
        var fenceStart = trimmed.IndexOf("```", StringComparison.Ordinal);

        if (fenceStart >= 0)
        {
            var afterFence = trimmed[(fenceStart + 3)..].TrimStart();
            if (afterFence.StartsWith("json", StringComparison.OrdinalIgnoreCase))
            {
                afterFence = afterFence[4..].TrimStart();
            }

            var fenceEnd = afterFence.IndexOf("```", StringComparison.Ordinal);
            if (fenceEnd >= 0)
            {
                trimmed = afterFence[..fenceEnd].Trim();
            }
        }

        var start = trimmed.IndexOf('{');
        var end = trimmed.LastIndexOf('}');
        if (start < 0 || end <= start)
        {
            throw new JsonException($"AI response does not contain a JSON object: {TrimForLog(content)}");
        }

        return trimmed[start..(end + 1)];
    }

    private static AiContent ParseAiContent(JsonElement root)
    {
        return new AiContent(
            GetString(root, "title", "headline"),
            GetString(root, "summary", "analysis", "message", "description"),
            GetString(root, "severity", "risk", "level"),
            GetStringList(root, "alerts", "warnings", "warning"),
            GetStringList(root, "savingTips", "saving_tips", "tips", "recommendations"));
    }

    private static string? GetString(JsonElement root, params string[] names)
    {
        foreach (var name in names)
        {
            if (!TryGetProperty(root, name, out var value)) continue;

            if (value.ValueKind == JsonValueKind.String)
            {
                return value.GetString();
            }

            if (value.ValueKind is JsonValueKind.Number or JsonValueKind.True or JsonValueKind.False)
            {
                return value.ToString();
            }
        }

        return null;
    }

    private static IReadOnlyList<string> GetStringList(JsonElement root, params string[] names)
    {
        foreach (var name in names)
        {
            if (!TryGetProperty(root, name, out var value)) continue;

            if (value.ValueKind == JsonValueKind.Array)
            {
                return value.EnumerateArray()
                    .Select(item => item.ValueKind == JsonValueKind.String ? item.GetString() : item.ToString())
                    .Where(item => !string.IsNullOrWhiteSpace(item))
                    .Select(item => item!)
                    .ToArray();
            }

            if (value.ValueKind == JsonValueKind.String)
            {
                var text = value.GetString();
                return string.IsNullOrWhiteSpace(text) ? Array.Empty<string>() : new[] { text };
            }
        }

        return Array.Empty<string>();
    }

    private static bool TryGetProperty(JsonElement root, string name, out JsonElement value)
    {
        if (root.TryGetProperty(name, out value)) return true;

        foreach (var property in root.EnumerateObject())
        {
            if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }

    private static void ValidateRequest(SpendingInsightRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserId) || string.IsNullOrWhiteSpace(request.Period))
        {
            throw new ArgumentException("userId and period are required.");
        }

        if (request.TopExpenseCategories.Count > 8)
        {
            throw new ArgumentException("Too many expense categories.");
        }
    }

    private static void ValidateAssistantRequest(FinancialAssistantRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserId) ||
            string.IsNullOrWhiteSpace(request.Period) ||
            string.IsNullOrWhiteSpace(request.Question))
        {
            throw new ArgumentException("userId, period and question are required.");
        }

        if (request.Question.Trim().Length > 600)
        {
            throw new ArgumentException("Question is too long.");
        }

        if (request.TopExpenseCategories.Count > 8 || request.TopIncomeCategories.Count > 8)
        {
            throw new ArgumentException("Too many category summaries.");
        }

        if ((request.RecentMessages?.Count ?? 0) > 8)
        {
            throw new ArgumentException("Too many recent messages.");
        }

        if ((request.RecentMessages ?? Array.Empty<AssistantChatMessage>())
            .Any(message => message.Content.Length > 800))
        {
            throw new ArgumentException("Recent message is too long.");
        }
    }

    private static bool IsLikelyOutOfScopeQuestion(string question)
    {
        var normalized = question.ToLowerInvariant();
        var blocked = new[]
        {
            "code", "html", "css", "javascript", "script", "website", "web site",
            "sql", "python", "flutter", "dart", "api", "function", "class"
        };
        var finance = new[]
        {
            "chi", "thu", "tiết kiệm", "tài chính", "ngân sách", "vay", "nợ",
            "tiền", "lương", "danh mục", "giao dịch", "số dư", "cash", "budget",
            "income", "expense", "debt", "loan", "saving"
        };

        return blocked.Any(normalized.Contains) && !finance.Any(normalized.Contains);
    }

    private static FinancialAssistantResponse BuildSafeAssistantRefusal()
    {
        return new FinancialAssistantResponse(
            "Mình chỉ hỗ trợ phân tích tài chính cá nhân dựa trên dữ liệu CoinNest. Bạn có thể hỏi về chi tiêu, thu nhập, ngân sách, khoản vay hoặc cách tiết kiệm trong tháng này.",
            DefaultAssistantQuestions,
            "guardrail",
            DateTimeOffset.UtcNow);
    }

    private static string[] DefaultAssistantQuestions => new[]
    {
        "Tháng này tôi chi nhiều nhất vào đâu?",
        "Tôi có đang chi quá nhiều không?",
        "Tôi nên tiết kiệm ở khoản nào?"
    };

    private IReadOnlyList<ProviderModel> BuildProviderAttempts()
    {
        var attempts = new List<ProviderModel>();
        attempts.AddRange(GetProviderModels("Groq", "Groq:Models", new[]
        {
            "llama-3.3-70b-versatile",
            "llama-3.1-8b-instant",
            "openai/gpt-oss-120b",
            "openai/gpt-oss-20b"
        }));
        attempts.AddRange(GetProviderModels("GitHub Models", "GitHubModels:Models", new[]
        {
            "openai/gpt-4.1-mini",
            "openai/gpt-4o-mini",
            "meta/Meta-Llama-3.1-8B-Instruct"
        }));
        attempts.AddRange(GetProviderModels("Gemini", "Gemini:Models", new[]
        {
            "gemini-2.5-flash",
            "gemini-2.0-flash",
            "gemini-1.5-flash"
        }));
        attempts.AddRange(GetProviderModels("OpenRouter", "OpenRouter:Models", new[]
        {
            "poolside/laguna-m.1:free",
            "poolside/laguna-xs.2:free",
            "z-ai/glm-4.5-air:free",
            "openrouter/free"
        }));

        lock (ModelLock)
        {
            if (!string.IsNullOrWhiteSpace(_preferredProvider) &&
                !string.IsNullOrWhiteSpace(_preferredModel))
            {
                var preferred = attempts.FirstOrDefault(
                    item =>
                        item.Provider == _preferredProvider &&
                        item.Model == _preferredModel);

                if (preferred != null)
                {
                    attempts.Remove(preferred);
                    attempts.Insert(0, preferred);
                }
            }

            return attempts;
        }
    }

    private IReadOnlyList<ProviderModel> GetProviderModels(
        string provider,
        string configPath,
        IReadOnlyList<string> fallbackModels)
    {
        var configured = _configuration.GetSection(configPath).Get<string[]>();
        var models = configured?.Where(model => !string.IsNullOrWhiteSpace(model)).ToArray();

        return (models is { Length: > 0 } ? models : fallbackModels)
            .Select(model => new ProviderModel(provider, model))
            .ToArray();
    }

    private static void MarkModelSuccessful(string provider, string model)
    {
        lock (ModelLock)
        {
            _preferredProvider = provider;
            _preferredModel = model;
        }
    }

    private sealed record ProviderModel(string Provider, string Model);

    private sealed record AiContent(
        string? Title,
        string? Summary,
        string? Severity,
        IReadOnlyList<string>? Alerts,
        IReadOnlyList<string>? SavingTips);
}
