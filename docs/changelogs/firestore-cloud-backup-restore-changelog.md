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
## 2026-05-31 - Backup hardening

### Phase 1 - Xóa bản sao lưu cloud

- Thêm luồng xóa `snapshots/current` và toàn bộ `chunks` trong `CloudBackupService`.
- Thêm thao tác `deleteCurrentBackup` trong `BackupProvider`.
- Thêm nút `Xóa bản sao lưu cloud` và dialog xác nhận nêu rõ dữ liệu local không bị ảnh hưởng.

### Phase 2 - Chuẩn hóa lỗi

- Chuyển lỗi backup/restore sang thông báo tiếng Việt có dấu, không hiển thị lỗi kỹ thuật thô cho người dùng.
- Phân biệt lỗi chưa đăng nhập, Firebase user không khớp, thiếu backup, thiếu chunk, checksum sai và lỗi Firestore.
- Snackbar trong màn `Sao lưu & Phục hồi` dùng thông báo từ provider khi thao tác thất bại.

### Phase 3 - Chi tiết metadata

- Hiển thị tổng số bản ghi và số lượng theo từng nhóm dữ liệu tài chính từ `metadata.recordCounts`.
- Giữ trạng thái rỗng rõ ràng: `Chưa có bản sao lưu` và `0 bản ghi`.
- Không thêm field Firestore mới.

### Phase 4 - Mở rộng test

- Bổ sung test restore cho remap khóa ngoại budget, transfer, loan và loan payment.
- Bổ sung test cloud chunks cho upload nhiều chunk, thiếu chunk và upload mới thay thế chunk cũ.
- Không đổi `BackupDao.formatVersion` vì payload schema không đổi.
