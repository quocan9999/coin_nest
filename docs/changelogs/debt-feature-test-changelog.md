# Debt Feature Test Changelog

## 2026-05-24 23:33:15 +07:00 - Phase 0

- Thay đổi chính:
  - Đã chuyển sang nhánh `test/feature-debt`.
  - Tạo plan kiểm thử debt tại `docs/plans/debt-feature-test-plan.md`.
  - Tạo changelog kiểm thử debt tại `docs/changelogs/debt-feature-test-changelog.md`.
- File/module ảnh hưởng:
  - `docs/plans/debt-feature-test-plan.md`
  - `docs/changelogs/debt-feature-test-changelog.md`
- Verification:
  - `git switch -c test/feature-debt` chạy thành công sau khi xin quyền ghi `.git`.
- Skipped theo yêu cầu:
  - Chưa chạy `dart format`.
  - Chưa chạy `flutter analyze`.

## 2026-05-24 23:44:39 +07:00 - Phase 1

- Thay đổi chính:
  - Thêm `integration_test` và `sqflite_common_ffi` vào `pubspec.yaml`.
  - Cập nhật `pubspec.lock` với các dependency test mới.
  - Thêm test-only API trong `DatabaseHelper` để inject SQLite in-memory và tạo schema/index cho test.
  - Thêm helper seed DB, fake auth service, widget harness và FFI harness.
- File/module ảnh hưởng:
  - `pubspec.yaml`
  - `pubspec.lock`
  - `lib/database/database_helper.dart`
  - `test/helpers/debt_database_fixture.dart`
  - `test/helpers/debt_ffi_database.dart`
  - `test/helpers/fake_auth_service.dart`
  - `test/helpers/debt_widget_harness.dart`
  - `test/helpers/debt_ffi_widget_harness.dart`
- Verification:
  - Kiểm tra diff tĩnh cho phần `DatabaseHelper`.
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF.
- Ghi chú:
  - Không đổi schema runtime.
  - Không bump `AppConstants.dbVersion`.
  - Sau yêu cầu mới của user, không chạy thêm lệnh `flutter` hoặc `dart`; các lệnh đó để user chạy thủ công.

## 2026-05-24 23:44:39 +07:00 - Phase 2

- Thay đổi chính:
  - Thêm model tests cho `Loan` và `TransactionModel`.
  - Thêm validator tests cho amount và interest rate.
  - Thêm DAO/database tests cho tạo vay/cho vay, payment, update, rollback delete, summary, category transaction.
  - Thêm provider tests cho validate input, default category mapping, reload loan/transaction provider, delete rollback.
  - Thêm widget tests cho `AddEditLoanScreen` và `PaymentScreen`.
- File/module ảnh hưởng:
  - `test/models/debt_models_test.dart`
  - `test/utils/debt_validators_test.dart`
  - `test/database/debt_loan_dao_test.dart`
  - `test/providers/debt_loan_provider_test.dart`
  - `test/screens/loans/debt_loan_screens_test.dart`
- Verification:
  - Kiểm tra danh sách test file bằng `rg --files`.
  - Kiểm tra các flow test dùng DB in-memory, không dùng database thật của app.
- Skipped theo yêu cầu:
  - Chưa chạy `flutter test test`.
  - Chưa chạy `dart format`.
  - Chưa chạy `flutter analyze`.

## 2026-05-24 23:44:39 +07:00 - Phase 3

- Thay đổi chính:
  - Thêm `integration_test/debt_flow_test.dart`.
  - Test có guard Android-only và skip nếu không chạy trên Android.
  - Flow integration dùng DB in-memory: tạo borrow, trả một phần, tạo lend, kiểm tra summary/transaction/balance.
- File/module ảnh hưởng:
  - `integration_test/debt_flow_test.dart`
  - `test/helpers/debt_database_fixture.dart`
  - `test/helpers/debt_widget_harness.dart`
- Verification:
  - Kiểm tra tĩnh guard `Platform.isAndroid`.
  - Chưa chọn thiết bị vì user yêu cầu không chạy lệnh Flutter; user tự chạy `flutter devices` và test thủ công.
- Skipped theo yêu cầu:
  - Chưa chạy integration test trên Android phone thật.
  - Không chạy trên desktop/emulator/iOS.

## 2026-05-24 23:44:39 +07:00 - Phase 4

- Thay đổi chính:
  - Cập nhật plan để ghi rõ các lệnh Flutter/Dart là lệnh user chạy thủ công.
  - Cập nhật changelog với kết quả verification thực tế.
- File/module ảnh hưởng:
  - `docs/plans/debt-feature-test-plan.md`
  - `docs/changelogs/debt-feature-test-changelog.md`
- Verification đã chạy:
  - `git status --short --branch`
  - `git diff --check`
  - `rg --files test integration_test docs\plans docs\changelogs`
  - `rg` kiểm tra các lệnh Flutter/Dart còn lại trong docs/test.
- Verification cần user chạy thủ công:
  - `flutter pub get`
  - `flutter test test`
  - `flutter devices`
  - `flutter test integration_test/debt_flow_test.dart -d <android-device-id>`
- Skipped theo yêu cầu:
  - Không chạy `dart format`.
  - Không chạy `flutter analyze`.

## 2026-05-25 00:02:35 +07:00 - Follow-up fix

- Thay đổi chính:
  - Thay `pumpAndSettle()` bằng bounded pumps trong debt widget tests để tránh kẹt khi widget tree còn scheduled frame.
  - Thêm `pumpDebtFrames` và `pumpDebtUntil` dùng predicate rõ ràng thay vì chờ toàn bộ app settle.
  - Áp dụng cùng pattern cho integration debt flow.
- File/module ảnh hưởng:
  - `test/helpers/debt_widget_harness.dart`
  - `test/screens/loans/debt_loan_screens_test.dart`
  - `integration_test/debt_flow_test.dart`
- Verification:
  - `rg "pumpAndSettle" test integration_test` không còn kết quả.
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF.
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`; user chạy thủ công.

## 2026-05-25 00:10:41 +07:00 - Follow-up fix

- Thay đổi chính:
  - Chuyển debt widget harness sang `ThemeData(useMaterial3: true)` để tránh phụ thuộc `GoogleFonts` trong widget test.
  - Rút `AddEditLoanScreen` widget test về render/form-state test, không bấm submit trong widget test nữa.
  - Bổ sung provider test cho payment vượt remaining để vẫn cover behavior rủi ro mà không đi qua async UI submit.
- File/module ảnh hưởng:
  - `test/helpers/debt_widget_harness.dart`
  - `test/screens/loans/debt_loan_screens_test.dart`
  - `test/providers/debt_loan_provider_test.dart`
- Verification:
  - `rg "tap\(|enterText\(|ensureVisible\(|pumpDebtUntil|pumpDebtFrames" test\screens\loans\debt_loan_screens_test.dart test\helpers\debt_widget_harness.dart test\providers\debt_loan_provider_test.dart` xác nhận screen widget test không còn thao tác submit.
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF.
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`; user chạy thủ công.

## 2026-05-25 00:25:49 +07:00 - Follow-up debug fix

- Thay đổi chính:
  - Khôi phục hướng test UI submit cho `AddEditLoanScreen` và `PaymentScreen`.
  - Sửa nguyên nhân nghi ngờ gây treo: widget test chạy trong fake async zone trong khi `sqflite_common_ffi` dùng async IO thật.
  - Bọc DB setup, provider preload, submit callback và DB assertions bằng `tester.runAsync`.
  - Thêm checkpoint log dạng `[debt-widget-test] ...` và timeout 5 giây cho từng bước để biết chính xác bước bị treo nếu còn lỗi.
  - Gọi trực tiếp `ElevatedButton.onPressed` trong `runAsync` thay vì `tester.tap` cho nút submit, để callback `_save()` chạy trong real async zone.
  - Áp dụng cùng pattern cho `integration_test/debt_flow_test.dart`.
- File/module ảnh hưởng:
  - `test/helpers/debt_widget_harness.dart`
  - `test/helpers/debt_ffi_widget_harness.dart`
  - `test/screens/loans/debt_loan_screens_test.dart`
  - `integration_test/debt_flow_test.dart`
- Verification:
  - `rg "tester\.tap\(|onPressed|runDebtStep|runDebtValue|waitForDebtCondition|pumpDebtUntil|pumpAndSettle" test integration_test`
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF.
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`; user chạy thủ công.

## 2026-05-27 06:43:03 +07:00 - Follow-up integration fix

- Nguyên nhân lỗi:
  - Harness đặt `AddEditLoanScreen` trực tiếp làm `home` của `MaterialApp`.
  - Khi lưu khoản vay thành công, màn hình gọi `Navigator.pop(context, true)`, làm route duy nhất bị pop.
  - Lần harness dựng `PaymentScreen` tiếp theo, `Navigator` đã có lịch sử rỗng nên văng assertion `_history.isNotEmpty`.
- Thay đổi chính:
  - Thêm route nền ổn định `_DebtTestRouteHost` trong widget harness.
  - Mỗi màn hình cần test được `push` lên trên route nền; thao tác lưu có thể `pop` an toàn về route nền.
  - Giữ nguyên các UI submit flow trong widget test và integration test.
  - Đổi toàn bộ title `group`, `test`, `testWidgets` trong `test/` và `integration_test/` sang tiếng Việt có dấu.
  - Việt hóa checkpoint log của debt UI/integration test.
- File/module ảnh hưởng:
  - `test/helpers/debt_widget_harness.dart`
  - `test/helpers/debt_ffi_widget_harness.dart`
  - `test/models/debt_models_test.dart`
  - `test/utils/debt_validators_test.dart`
  - `test/database/debt_loan_dao_test.dart`
  - `test/providers/debt_loan_provider_test.dart`
  - `test/screens/loans/debt_loan_screens_test.dart`
  - `integration_test/debt_flow_test.dart`
- Verification:
  - `rg -n "\b(group|test|testWidgets)\(" test integration_test` xác nhận title test đã được Việt hóa.
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF ở file đã có từ trước.
- Verification cần user chạy thủ công:
  - `flutter test test`
  - `flutter test integration_test -d <android-device-id>`
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`.

## 2026-05-27 07:00:58 +07:00 - Mở rộng integration theo UI thực tế

- Thay đổi chính:
  - Cho phép harness nhận `ThemeData` tùy chọn; widget tests nhỏ vẫn dùng theme nhẹ mặc định.
  - Integration test truyền `AppTheme.lightTheme` để chạy với màu, input, button và typography của app thật.
  - Luồng borrow/payment đi qua navigation thật của feature: `LoanListScreen` -> `AddEditLoanScreen` -> `LoanDetailScreen` -> `PaymentScreen`.
  - Luồng này kiểm tra UI danh sách hiển thị khoản vay, UI chi tiết hiển thị dư nợ trước và sau trả một phần, đồng thời vẫn kiểm tra balance.
  - Luồng lend giữ mở trực tiếp `AddEditLoanScreen` với theme thật để bao phủ sign, balance và category mà không kéo dài điều hướng không cần thiết.
- File/module ảnh hưởng:
  - `test/helpers/debt_widget_harness.dart`
  - `integration_test/debt_flow_test.dart`
- Verification:
  - Kiểm tra tĩnh xác nhận `AppTheme.lightTheme` chỉ được truyền từ integration test.
  - Kiểm tra tĩnh xác nhận integration có `LoanListScreen`, `LoanDetailScreen`, `PaymentScreen` và assertion dư nợ render.
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF ở file đã có từ trước.
- Verification cần user chạy thủ công:
  - `flutter test integration_test -d <android-device-id>`
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`.

## 2026-05-27 07:10:06 +07:00 - Delay quan sát trên điện thoại thật

- Thay đổi chính:
  - Thêm `_thoiGianQuanSat` và `_dungDeQuanSat` chỉ trong `integration_test/debt_flow_test.dart`.
  - Mỗi trạng thái UI quan trọng được giữ lại 2 giây để có thể quan sát trên điện thoại thật: danh sách ban đầu, form vay, danh sách sau tạo, chi tiết trước/sau trả nợ, form thanh toán và form cho vay.
  - Delay trình diễn được đặt ngoài các block `waitForDebtCondition` và `pumpDebtUntil`; timeout/predicate chờ DB/provider vẫn giữ nguyên.
- File/module ảnh hưởng:
  - `integration_test/debt_flow_test.dart`
- Verification:
  - Kiểm tra tĩnh xác nhận các lệnh `_dungDeQuanSat` chỉ xuất hiện trong integration test.
  - Kiểm tra tĩnh xác nhận `waitForDebtCondition` và `pumpDebtUntil` vẫn còn nguyên tại các bước đồng bộ dữ liệu.
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF ở file đã có từ trước.
- Verification cần user chạy thủ công:
  - `flutter test integration_test -d <android-device-id>`
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`.

## 2026-05-27 07:15:53 +07:00 - Sửa tái khởi tạo harness giữa flow

- Nguyên nhân lỗi:
  - Sau bước trả nợ, integration test gọi `pumpDebtWidgetWithFixture` lần hai để mở form cho vay.
  - `tester.pumpWidget` cập nhật `MaterialApp` và tái sử dụng `NavigatorState` hiện có; nó không tạo một navigator mới với route host ở trạng thái đang hiển thị.
  - Lúc đó `LoanDetailScreen` vẫn là route đang visible, còn `_DebtTestRouteHost` nằm offstage; `find.byKey(_debtHostKey)` không thấy phần tử visible và `tester.element(...)` ném `Bad state: No element`.
- Thay đổi chính:
  - Bỏ lần dựng harness thứ hai trong cùng integration test.
  - Tái sử dụng app tree, provider và navigator đã mở từ đầu: từ detail quay lại `LoanListScreen`, mở form thêm mới, rồi tạo khoản cho vay.
  - Bổ sung quan sát danh sách sau khi tạo khoản cho vay.
- File/module ảnh hưởng:
  - `integration_test/debt_flow_test.dart`
- Verification:
  - Kiểm tra tĩnh xác nhận flow integration chỉ còn một lần gọi `pumpDebtWidgetWithFixture`.
  - Kiểm tra tĩnh xác nhận flow cho vay đi tiếp qua `LoanListScreen` và sử dụng cùng `borrowHarness`.
  - `git diff --check` không báo whitespace error, chỉ có cảnh báo LF/CRLF ở file đã có từ trước.
- Verification cần user chạy thủ công:
  - `flutter test integration_test -d <android-device-id>`
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`.

## 2026-05-27 07:49:50 +07:00 - Chốt target Android và chuẩn bị commit baseline

- Thay đổi chính:
  - Mở rộng target integration test từ điện thoại Android thật sang Android nói chung, gồm Genymotion và điện thoại Android thật.
  - Giữ guard `Platform.isAndroid` trong integration test; cập nhật thông báo skip và comment delay quan sát để phản ánh đúng target.
  - Cập nhật plan với phase mở rộng coverage cho edit, delete, full payment, thu nợ, transaction-linked navigation và màn theo dõi vay nợ.
  - Chuẩn bị commit local cho baseline test debt hiện có trước khi thêm các kịch bản mới.
- File/module ảnh hưởng:
  - `docs/plans/debt-feature-test-plan.md`
  - `docs/changelogs/debt-feature-test-changelog.md`
  - `integration_test/debt_flow_test.dart`
- Verification:
  - Kiểm tra trạng thái nhánh xác nhận đang ở `test/feature-debt`.
  - Kiểm tra tĩnh xác nhận hai file `data_sql.markdown` và `execute_sql.markdown` không thuộc phạm vi commit debt testing.
- Verification cần user chạy thủ công:
  - `flutter test test`
  - `flutter test integration_test/debt_flow_test.dart -d <genymotion-device-id>`
  - `flutter test integration_test/debt_flow_test.dart -d <physical-android-device-id>`
- Skipped theo yêu cầu:
  - Không chạy lệnh `flutter` hoặc `dart`.
  - Không chạy `dart format` hoặc `flutter analyze`.
