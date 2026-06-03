# Plan Tích Hợp Trợ Lý Tài Chính AI Trong Tab Báo Cáo

## Mục tiêu

Thêm card **Trợ lý tài chính AI** trong tab **Báo cáo**, mở màn chat riêng để người dùng hỏi bằng tiếng Việt về thu chi, ngân sách, tài khoản và vay nợ dựa trên dữ liệu CoinNest tháng hiện tại.

## Phạm vi đã chốt

- Flutter gọi `POST /api/ai/financial-assistant` trong `featureAI-API`.
- Backend tiếp tục stateless, không thêm database backend, SQL Server, DbContext hoặc migration.
- Không đổi SQLite schema, không bump `AppConstants.dbVersion`, không yêu cầu clear app data.
- Chat history lưu cục bộ bằng `SharedPreferences`, giới hạn số tin nhắn gửi lên backend.
- Backend và prompt chỉ cho phép câu hỏi tài chính cá nhân trong CoinNest; câu hỏi code, website, script, SQL hoặc ngoài phạm vi sẽ bị từ chối an toàn.
- Không commit API key hoặc dữ liệu tài chính thật.

## Phase 1 - Backend Assistant API

- Thêm model `FinancialAssistantRequest`, `AssistantReportSummary`, `AssistantChatMessage` và `FinancialAssistantResponse`.
- Thêm endpoint `POST /api/ai/financial-assistant`.
- Mở rộng `OpenRouterService` để dùng lại danh sách provider/model hiện có.
- Prompt assistant yêu cầu JSON-only với `answer` và `suggestedQuestions`.
- Validate câu hỏi rỗng, câu hỏi quá dài, quá nhiều category hoặc history.
- Guardrail backend từ chối sớm câu hỏi code/website ngoài phạm vi và reject response có dấu hiệu code/script.

## Phase 2 - Flutter Service, Provider Và Context

- Thêm `FinancialAssistantService` dùng `AI_API_BASE_URL`.
- Thêm model request/response/message cho chat.
- Thêm `FinancialAssistantProvider` build context từ `ReportProvider`, `TransactionProvider`, `LoanProvider`, `BudgetProvider` và `AccountProvider`.
- Payload chỉ gửi tóm tắt tháng, top danh mục thu/chi, debt summary, budget summary và tối đa vài tin nhắn gần nhất.
- Lịch sử chat lưu cục bộ theo user bằng `SharedPreferences`.

## Phase 3 - UI Trong Tab Báo Cáo

- Thêm card **Trợ lý tài chính AI** trong `ReportScreen`.
- Thêm `FinancialAssistantScreen` với header, danh sách tin nhắn, gợi ý câu hỏi nhanh, ô nhập, nút gửi, loading và error state.
- UI dùng `Theme.of(context).colorScheme`, `AppTheme.colors(context)` và token spacing/radius của `AppTheme`.
- Response AI chỉ render bằng `Text`, không render markdown hoặc code block.

## Phase 4 - Test Và Validation

- Thêm test service parse response và gọi đúng endpoint assistant.
- Thêm test provider build context, không gửi toàn bộ transactions và lưu/nạp history.
- Build backend bằng `dotnet build`.
- Chạy request guardrail mẫu cho endpoint assistant local nếu môi trường cho phép.
- Format các file Dart đã sửa và chạy `flutter analyze` ngoài sandbox theo policy repo.
