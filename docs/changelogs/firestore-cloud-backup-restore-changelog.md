# Firestore Cloud Backup/Restore Changelog

Timestamp: 2026-05-30 18:01:31 +07:00

## Added

- Thêm dependency `cloud_firestore`.
- Thêm `BackupDao` để export/restore snapshot tài chính SQLite theo user.
- Thêm `CloudBackupService` để upload/download snapshot Firestore dạng metadata + chunks.
- Thêm `BackupProvider` để điều phối backup/restore và kiểm tra Firebase Auth uid.
- Đăng ký `BackupProvider` trong `lib/main.dart`.
- Thêm `firestore.rules` và cấu hình Firestore rules trong `firebase.json`.

## Changed

- Cập nhật `DataSettingsScreen` từ placeholder import/export file sang thao tác cloud:
  - hiển thị trạng thái bản sao lưu hiện tại;
  - nút `Sao lưu ngay`;
  - nút `Khôi phục` có confirm ghi đè;
  - reload provider tài chính sau restore.

## Notes

- Không bump `AppConstants.dbVersion` vì không đổi SQLite schema.
- Không dùng Firebase Storage hoặc Cloud Functions cho backup/restore.
- Không xóa `firebase_storage` vì nằm ngoài phạm vi cleanup của task này.
