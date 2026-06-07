using System.Text.Json.Serialization;

namespace featureAI_API.Models;

public sealed record SpendingInsightRequest(
    [property: JsonPropertyName("userId")] string UserId,
    [property: JsonPropertyName("period")] string Period,
    [property: JsonPropertyName("totalIncome")] decimal TotalIncome,
    [property: JsonPropertyName("totalExpense")] decimal TotalExpense,
    [property: JsonPropertyName("balance")] decimal Balance,
    [property: JsonPropertyName("topExpenseCategories")] IReadOnlyList<CategoryExpenseSummary> TopExpenseCategories,
    [property: JsonPropertyName("debtSummary")] DebtSummary? DebtSummary,
    [property: JsonPropertyName("budgetSummary")] BudgetSummary? BudgetSummary);

public sealed record CategoryExpenseSummary(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("percent")] decimal Percent);

public sealed record DebtSummary(
    [property: JsonPropertyName("borrowedRemaining")] decimal BorrowedRemaining,
    [property: JsonPropertyName("lentRemaining")] decimal LentRemaining,
    [property: JsonPropertyName("borrowedPrincipalRemaining")] decimal BorrowedPrincipalRemaining,
    [property: JsonPropertyName("borrowedInterestOutstanding")] decimal BorrowedInterestOutstanding,
    [property: JsonPropertyName("borrowedTotalOutstanding")] decimal BorrowedTotalOutstanding,
    [property: JsonPropertyName("lentPrincipalRemaining")] decimal LentPrincipalRemaining,
    [property: JsonPropertyName("lentInterestOutstanding")] decimal LentInterestOutstanding,
    [property: JsonPropertyName("lentTotalOutstanding")] decimal LentTotalOutstanding,
    [property: JsonPropertyName("overdueCount")] int OverdueCount);

public sealed record BudgetSummary(
    [property: JsonPropertyName("activeCount")] int ActiveCount,
    [property: JsonPropertyName("exceededCount")] int ExceededCount,
    [property: JsonPropertyName("highestUsagePercent")] decimal HighestUsagePercent);

public sealed record SpendingInsightResponse(
    [property: JsonPropertyName("title")] string Title,
    [property: JsonPropertyName("summary")] string Summary,
    [property: JsonPropertyName("severity")] string Severity,
    [property: JsonPropertyName("alerts")] IReadOnlyList<string> Alerts,
    [property: JsonPropertyName("savingTips")] IReadOnlyList<string> SavingTips,
    [property: JsonPropertyName("model")] string Model,
    [property: JsonPropertyName("generatedAt")] DateTimeOffset GeneratedAt);

public sealed record FinancialAssistantRequest(
    [property: JsonPropertyName("userId")] string UserId,
    [property: JsonPropertyName("question")] string Question,
    [property: JsonPropertyName("period")] string Period,
    [property: JsonPropertyName("reportSummary")] AssistantReportSummary ReportSummary,
    [property: JsonPropertyName("topExpenseCategories")] IReadOnlyList<CategoryExpenseSummary> TopExpenseCategories,
    [property: JsonPropertyName("topIncomeCategories")] IReadOnlyList<CategoryExpenseSummary> TopIncomeCategories,
    [property: JsonPropertyName("debtSummary")] DebtSummary? DebtSummary,
    [property: JsonPropertyName("budgetSummary")] BudgetSummary? BudgetSummary,
    [property: JsonPropertyName("recentMessages")] IReadOnlyList<AssistantChatMessage>? RecentMessages);

public sealed record AssistantReportSummary(
    [property: JsonPropertyName("totalIncome")] decimal TotalIncome,
    [property: JsonPropertyName("totalExpense")] decimal TotalExpense,
    [property: JsonPropertyName("netBalance")] decimal NetBalance,
    [property: JsonPropertyName("accountBalance")] decimal AccountBalance);

public sealed record AssistantChatMessage(
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("content")] string Content);

public sealed record FinancialAssistantResponse(
    [property: JsonPropertyName("answer")] string Answer,
    [property: JsonPropertyName("suggestedQuestions")] IReadOnlyList<string> SuggestedQuestions,
    [property: JsonPropertyName("model")] string Model,
    [property: JsonPropertyName("generatedAt")] DateTimeOffset GeneratedAt);
