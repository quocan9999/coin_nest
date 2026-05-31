# Firestore Cloud Backup/Restore Plan

## Mục tiêu

- Sao lưu snapshot dữ liệu tài chính của user hiện tại lên Cloud Firestore.
- Khôi phục snapshot từ Firestore về SQLite local cho đúng Firebase Auth user.
- Không dùng import/export file, Firebase Storage hay Cloud Functions.

## Phạm vi dữ liệu

- Backup: `accounts`, `categories`, `transactions`, `loans`, `loan_payments`, `budgets`.
- Không backup: `users`, password hash/salt, session, settings, feedback.
- Snapshot format version: `1`.
- Không đổi SQLite schema nên không bump `AppConstants.dbVersion`.

## Thiết kế

- `BackupDao` đọc raw rows theo `user_id`, tạo payload JSON và checksum SHA-256.
- `CloudBackupService` ghi metadata tại `/user_backups/{uid}/snapshots/current`.
- Payload JSON được chia chunk trong subcollection `chunks` để tránh giới hạn 1 MiB/document.
- `BackupProvider` kiểm tra Firebase Auth uid khớp `currentUser.firebaseUid` trước khi backup/restore.
- `DataSettingsScreen` hiển thị trạng thái cloud, nút sao lưu, nút khôi phục và confirm ghi đè.

## Restore

- Validate Firebase Auth user và checksum snapshot.
- Trong một SQLite transaction:
  - xóa dữ liệu tài chính hiện tại của user;
  - insert lại account/category/loan/transaction/payment/budget;
  - remap toàn bộ id;
  - update lại `loans.transaction_id`;
  - chạy `PRAGMA foreign_key_check`.

## Firebase Rules

- Chỉ user có `request.auth.uid == uid` được đọc/ghi backup của chính họ.
- Rules áp dụng cho metadata document và subcollection `chunks`.

## Validation

- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
