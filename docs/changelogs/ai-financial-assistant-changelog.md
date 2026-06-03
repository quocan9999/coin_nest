# Changelog Trợ Lý Tài Chính AI

## Phase 1 - Backend Assistant API

- Thêm endpoint `POST /api/ai/financial-assistant` trong `featureAI-API`.
- Thêm request/response contract cho trợ lý chat tài chính.
- Tái sử dụng hạ tầng AI provider hiện có trong `OpenRouterService`.
- Thêm prompt finance-only, JSON-only cho assistant.
- Thêm validate câu hỏi, giới hạn history/category và guardrail chặn câu hỏi code/website ngoài phạm vi.
- Không thêm database backend, SQL Server hoặc schema mới.

## Phase 2 - Flutter Service, Provider Và Context

- Thêm model `FinancialAssistantMessage`, `FinancialAssistantRequest` và `FinancialAssistantResponse`.
- Thêm `FinancialAssistantService` gọi endpoint assistant bằng `AI_API_BASE_URL`.
- Thêm `FinancialAssistantProvider` để build payload tóm tắt từ dữ liệu app hiện có.
- Lưu lịch sử chat cục bộ theo user bằng `SharedPreferences`.
- Đăng ký provider trong `MultiProvider`.
- Không thay đổi SQLite schema, không bump `dbVersion`.

## Phase 3 - UI Trong Tab Báo Cáo

- Thêm card **Trợ lý tài chính AI** vào `ReportScreen`.
- Thêm màn `FinancialAssistantScreen` cho chat riêng.
- Hiển thị câu hỏi gợi ý mặc định, loading, error và message bubble.
- UI dùng token `AppTheme`, `Theme.of(context).colorScheme` và `AppTheme.colors(context)`.
- Chỉ render response bằng text thường, không render markdown/code.

## Phase 4 - Test Và Validation

- Thêm `test/services/financial_assistant_service_test.dart`.
- Thêm `test/providers/financial_assistant_provider_test.dart`.
- Validation backend: `dotnet build featureAI-API/featureAI-API.csproj`.
- Validation Flutter: format scoped, chạy test liên quan và `flutter analyze` ngoài sandbox theo policy.
- File ngoài scope như `test.md`, build/cache và ảnh tạm không được stage.
