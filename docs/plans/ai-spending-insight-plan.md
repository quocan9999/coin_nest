# Plan Tích Hợp AI Gợi Ý Tiết Kiệm / Cảnh Báo Chi Tiêu

## Mục tiêu

Thêm card **Gợi ý tiết kiệm AI** vào màn **Tổng quan**, dùng API ASP.NET Core trong `featureAI-API` để gọi OpenRouter và trả về gợi ý/cảnh báo tài chính cá nhân theo JSON cố định.

## Phạm vi đã chốt

- AI chỉ phân tích tóm tắt tài chính tháng, không nhận lịch sử giao dịch đầy đủ.
- Không triển khai chatbot tự do hoặc tác vụ ngoài phạm vi tài chính CoinNest.
- Backend stateless, không thêm SQL Server, DbContext, migration hoặc bảng mới.
- API key OpenRouter chỉ cấu hình qua environment/user-secrets, không commit key.
- Flutter chỉ gọi API khi người dùng bấm **Cập nhật** để tiết kiệm quota.
- Không thay đổi SQLite schema, không bump `AppConstants.dbVersion`.

## Backend

- Thay WeatherForecast bằng `POST /api/ai/spending-insight`.
- Request gồm `userId`, `period`, tổng thu/chi, số dư, top danh mục chi tiêu, tóm tắt vay nợ và budget.
- Response gồm `title`, `summary`, `severity`, `alerts`, `savingTips`, `model`, `generatedAt`.
- `OpenRouterService` dùng `HttpClientFactory`, timeout ngắn, retry tối đa 3 model theo round-robin.
- Guardrail backend dùng system prompt finance-only, JSON-only và reject phản hồi có markdown/code/schema sai.

## Flutter

- Thêm `AiSpendingInsightService`, `AiSpendingInsightProvider` và model request/response.
- Base URL đọc từ `--dart-define=AI_API_BASE_URL=...`.
- Debug Android bật cleartext HTTP để gọi API local.
- Provider build payload tháng từ `TransactionProvider`, `LoanProvider`, `BudgetProvider`, `AccountProvider`.
- Cache insight theo user bằng `SharedPreferences`.

## UI

- Chèn card **Gợi ý tiết kiệm AI** dưới card **Tổng số dư** và trước **Ghi chép gần đây**.
- Các trạng thái: chưa cập nhật, đang tải, lỗi kết nối, insight thành công.
- UI dùng `AppTheme`, `Theme.of(context).colorScheme` và `AppTheme.colors(context)`.
- Không render markdown/code từ model, chỉ render text đã làm sạch trong field JSON hợp lệ.

## Validation

- Test provider build payload tóm tắt tháng.
- Test service gọi đúng endpoint và parse response.
- Build backend bằng `dotnet build`.
- Format các file Dart đã sửa.
- Chạy `flutter analyze` ngoài sandbox theo policy repo nếu môi trường cho phép.
