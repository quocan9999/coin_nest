# Notification Reminders And Backup Alert Changelog

Timestamp: 2026-06-01 00:00:00 +07:00

## Phase 1 - Hạ tầng notification

- Thêm dependency `flutter_local_notifications`, `timezone`, `flutter_timezone`.
- Thêm Android manifest receiver cho scheduled notification và boot reschedule.
- Thêm `NotificationService` để init local notification, xin quyền và schedule/cancel reminder hằng ngày.
- Thêm `ReminderCoordinator` để gom logic đồng bộ nhắc ghi chép và nhắc vay/cho vay.
- Không thêm quyền exact alarm; notification Android dùng lịch inexact để tránh quyền nhạy cảm.

## Phase 2 - Cài đặt giờ nhắc

- Mở rộng `SettingsProvider` để lưu bật/tắt nhắc vay nợ và giờ nhắc chung dạng `HH:mm`.
- Tải settings ngay khi khởi tạo app thay vì để `SettingsProvider` ở trạng thái mặc định.
- Cập nhật phần `NHẮC NHỞ` trong `GeneralSettingsScreen` với switch nhắc ghi chép, switch nhắc vay nợ và chọn giờ nhắc.
- `LoanProvider` tự đồng bộ lịch nhắc vay nợ sau khi load hoặc thay đổi khoản vay/thanh toán.
- `HomeScreen` tải danh sách khoản vay khi app vào màn chính để reminder có dữ liệu active loans.

## Phase 3 - Badge dữ liệu chưa sao lưu

- Thêm `BackupAlertProvider` để lưu số thay đổi tài chính chưa sao lưu theo từng user trong `SharedPreferences`.
- Gắn dirty tracking sau mutation thành công ở tài khoản, danh mục, giao dịch, khoản vay, thanh toán vay và ngân sách.
- Reset số thay đổi chưa sao lưu sau khi backup hoặc restore thành công.
- Thêm `NotificationBadgeButton` dùng chung cho icon chuông có badge.
- Thêm `NotificationCenterScreen` hiển thị trạng thái thông báo và nút điều hướng tới `Sao lưu & Phục hồi`.
- Thay icon chuông no-op ở màn Tổng quan và Giao dịch bằng badge mở màn thông báo.
