# Plan Thông Báo CoinNest

## Mục tiêu

- Nhắc người dùng ghi chép thu/chi hằng ngày theo khung giờ đã chọn.
- Nhắc người dùng kiểm tra khoản vay/cho vay khi còn khoản active chưa tất toán.
- Hiển thị badge trên icon chuông khi có thay đổi dữ liệu tài chính chưa sao lưu.
- Dẫn người dùng từ màn thông báo tới `Sao lưu & Phục hồi` để sao lưu dữ liệu.

## Phase 1 - Hạ tầng notification

- Thêm `flutter_local_notifications`, `timezone`, `flutter_timezone`.
- Cấu hình Android manifest cho scheduled notification và reschedule sau reboot.
- Thêm `NotificationService` để init plugin, xin quyền và schedule/cancel notification hằng ngày.
- Thêm `ReminderCoordinator` để đồng bộ lịch nhắc dựa trên settings và danh sách khoản vay.
- Không thêm quyền exact alarm; lịch nhắc dùng `AndroidScheduleMode.inexactAllowWhileIdle`.

Commit:

```text
feat(notification): thêm hạ tầng nhắc nhở cục bộ

- Thêm dependency và cấu hình quyền notification cho Android
- Khởi tạo service nhắc nhở theo giờ local của thiết bị
- Lưu plan và changelog triển khai thông báo
```

## Phase 2 - Cài đặt giờ nhắc

- Mở rộng `SettingsProvider` với bật/tắt nhắc vay nợ và giờ nhắc chung.
- Cập nhật `GeneralSettingsScreen` phần nhắc nhở bằng token từ `AppTheme`.
- Đồng bộ lịch nhắc sau khi đổi settings và sau khi load dữ liệu user.
- Nhắc vay nợ chỉ schedule khi có khoản active còn `remainingAmount > 0`.

Commit:

```text
feat(notification): bật nhắc ghi chép và vay nợ theo giờ

- Thêm tuỳ chọn giờ nhắc chung trong cài đặt
- Schedule nhắc ghi chép hằng ngày theo giờ người dùng chọn
- Schedule nhắc vay và cho vay khi còn khoản active chưa tất toán
```

## Phase 3 - Badge dữ liệu chưa sao lưu

- Thêm `BackupAlertProvider` lưu số thay đổi tài chính chưa sao lưu theo user.
- Gắn dirty tracking sau mutation thành công ở giao dịch, khoản vay, ngân sách, tài khoản và danh mục.
- Reset count sau backup hoặc restore thành công.
- Thêm `NotificationBadgeButton` và `NotificationCenterScreen`.
- Icon chuông ở màn Tổng quan/Giao dịch mở màn thông báo; nút `Sao lưu dữ liệu` điều hướng tới `DataSettingsScreen`.

Commit:

```text
feat(notification): hiển thị cảnh báo dữ liệu chưa sao lưu

- Đếm số thay đổi tài chính cục bộ chưa sao lưu theo từng user
- Hiển thị badge trên nút chuông ở màn tổng quan và giao dịch
- Thêm màn thông báo dẫn nhanh tới Sao lưu & Phục hồi
```

## Phase 4 - Test và validation

- Thêm test cho settings persist, reminder coordinator, backup alert provider, badge và màn thông báo.
- Chạy `dart format .`, `flutter analyze`, `flutter test` ngoài sandbox.
- Cập nhật changelog theo từng phase trước commit.

Commit:

```text
test(notification): bổ sung kiểm thử luồng thông báo

- Kiểm thử lưu cài đặt nhắc nhở và lịch schedule local
- Kiểm thử badge dữ liệu chưa sao lưu và reset sau backup
- Hoàn thiện changelog thông báo theo từng phase
```

## Giả định

- Một khung giờ chung dùng cho cả nhắc ghi chép và nhắc vay/cho vay, mặc định `20:00`.
- Badge đếm thao tác thay đổi dữ liệu tài chính thành công, không diff từng row với Firestore.
- Không đổi SQLite schema nên không bump `AppConstants.dbVersion`.
- Không dùng FCM, Cloud Functions, Firebase Storage hoặc server push cho notification.
