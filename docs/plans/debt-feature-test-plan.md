# Plan Thiết Lập Và Mở Rộng Test Cho Feature Debt

## Mục tiêu

- Nhánh làm việc: `test/feature-debt`.
- Phạm vi: các luồng debt trong màn vay/cho vay, điều hướng từ giao dịch liên kết và màn theo dõi vay nợ; không kiểm thử toàn app.
- Phân bổ: hành vi dữ liệu/lỗi biên ưu tiên trong `test/`, thao tác UI chính được thể hiện trong `integration_test/`.
- Integration test chỉ chạy trên Android: Genymotion và điện thoại Android thật; không chạy Windows, Linux, macOS, iOS hoặc web.
- Không chạy lệnh `flutter`/`dart` từ agent; người dùng chạy thủ công các lệnh xác minh.

## Phase 0-4: Baseline hiện có

- Tạo nhánh, plan và changelog riêng cho debt testing.
- Thêm `integration_test`, `sqflite_common_ffi`, API test-only cho `DatabaseHelper`, fixture SQLite in-memory, fake auth và widget harness.
- Bao phủ model/utils, DAO, provider và widget tests cho tạo vay/cho vay, trả một phần, update, rollback delete, summary, category và validation cơ bản.
- Bao phủ integration theo UI thật cho `LoanListScreen` -> `AddEditLoanScreen` -> `LoanDetailScreen` -> `PaymentScreen`, sau đó tạo khoản cho vay; dùng theme thật, checkpoint async và delay quan sát.
- Commit baseline dự kiến: `test(debt): thiết lập kiểm thử tự động cho luồng vay và cho vay`.

## Phase 5: Mở rộng small tests

- Mở rộng fixture với tài khoản thứ hai, user thứ hai, trạng thái active/paid/overdue và transaction debt liên kết/không còn loan.
- DAO/provider tests bao phủ full payment, thu nợ khoản `lend`, lỗi ngày thanh toán, lỗi khoản đã paid, invariant sau payment, đổi loại/tài khoản và cách ly user.
- Widget tests bao phủ edit, delete dialog, trạng thái/lịch sử detail, list states, transaction-linked navigation và `LoanTrackingScreen`.
- Nếu case mới chứng minh bug runtime, không commit test executable đang đỏ; ghi expected/actual và log vào `docs/test-reports/debt-feature-known-failures.md`.

## Phase 6: Mở rộng integration Android

- Tách các flow độc lập trong `integration_test/debt_flow_test.dart`, mỗi flow dùng fixture riêng và giữ delay quan sát bên ngoài timeout/predicate:
  - Tạo/sửa/trả một phần/trả hết khoản vay.
  - Tạo/thu nợ/xóa hoàn tác khoản cho vay.
  - Đổi loại khoản debt và tài khoản liên kết.
  - Mở chi tiết từ transaction loan-linked và hiển thị lỗi khi liên kết thiếu.
  - Hiển thị/refresh trạng thái từ `LoanTrackingScreen`.
  - Validation UI không ghi dữ liệu sai.
- Guard Android hiện có tiếp tục loại trừ mọi target không phải Android, đồng thời chấp nhận Genymotion và điện thoại thật.

## Verification và handoff

- Agent chỉ kiểm tra tĩnh: `git status`, `git diff --check`, rà danh sách file và title/log bằng `rg`.
- Người dùng chạy thủ công:
  - `flutter pub get` nếu cần đồng bộ dependency.
  - `flutter test test`.
  - `flutter devices`.
  - `flutter test integration_test/debt_flow_test.dart -d <genymotion-device-id>`.
  - `flutter test integration_test/debt_flow_test.dart -d <physical-android-device-id>`.
- Acceptance integration: pass trên cả Genymotion và điện thoại Android thật.
- Không chạy `dart format` hoặc `flutter analyze`.
- Commit coverage mở rộng dự kiến: `test(debt): mở rộng kiểm thử thao tác và điều hướng khoản vay`.
