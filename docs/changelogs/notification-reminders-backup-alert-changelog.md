# Notification Reminders And Backup Alert Changelog

Timestamp: 2026-06-01 00:00:00 +07:00

## Phase 1 - Hạ tầng notification

- Thêm dependency `flutter_local_notifications`, `timezone`, `flutter_timezone`.
- Thêm Android manifest receiver cho scheduled notification và boot reschedule.
- Thêm `NotificationService` để init local notification, xin quyền và schedule/cancel reminder hằng ngày.
- Thêm `ReminderCoordinator` để gom logic đồng bộ nhắc ghi chép và nhắc vay/cho vay.
- Không thêm quyền exact alarm; notification Android dùng lịch inexact để tránh quyền nhạy cảm.
