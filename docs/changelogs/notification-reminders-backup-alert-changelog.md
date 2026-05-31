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
