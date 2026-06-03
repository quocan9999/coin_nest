# Changelog Gợi Ý Tiết Kiệm AI

## Phase 1 - Backend OpenRouter API

- Xóa template WeatherForecast khỏi `featureAI-API`.
- Thêm endpoint `POST /api/ai/spending-insight`.
- Thêm request/response contract cho tóm tắt tài chính tháng.
- Thêm `OpenRouterService` gọi OpenRouter bằng danh sách model free theo round-robin.
- Thêm guardrail JSON-only, finance-only và reject phản hồi có markdown/code.
- Loại bỏ package Entity Framework/SQL Server khỏi project API vì v1 backend stateless.

## Phase 2 - Flutter Service, Provider Và Cấu Hình

- Thêm dependency `http`.
- Thêm model `AiSpendingInsight` và `AiSpendingInsightRequest`.
- Thêm `AiSpendingInsightService` dùng `AI_API_BASE_URL`.
- Thêm `AiSpendingInsightProvider` build payload tháng và cache insight bằng `SharedPreferences`.
- Đăng ký provider trong `MultiProvider`.
- Bật cleartext HTTP trong debug Android để gọi API local.

## Phase 3 - Dashboard UI Theo DESIGN.md

- Thêm card **Gợi ý tiết kiệm AI** dưới **Tổng số dư** và trước **Ghi chép gần đây**.
- Thêm trạng thái chưa cập nhật, loading, lỗi kết nối và insight thành công.
- UI dùng token `AppTheme`, `Theme.of(context).colorScheme` và `AppTheme.colors(context)`.
- Chỉ render text từ JSON hợp lệ, loại bỏ markdown/code trước khi hiển thị.

## Phase 4 - Test Và Validation

- Thêm test provider cho payload tóm tắt tháng.
- Thêm test service cho endpoint và response JSON.
- Không thay đổi SQLite schema, không bump `dbVersion`, không yêu cầu clear app data.
