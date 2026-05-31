# Firestore Cloud Backup/Restore Hardening Plan

## Summary

- Không ghi đè `docs/plans/firestore-cloud-backup-restore-plan.md`.
- Cập nhật tiến độ bằng cách append vào `docs/changelogs/firestore-cloud-backup-restore-changelog.md`.
- Chia 4 phase, mỗi phase có commit riêng khi hoàn tất.
- Giữ phạm vi backup là dữ liệu tài chính SQLite: `accounts`, `categories`, `transactions`, `loans`, `loan_payments`, `budgets`.
- Không backup `feedbacks`, map hỗ trợ, Firebase auth state, hoặc settings trong đợt này.
- Tất cả thông báo UI, lỗi, snackbar, dialog dùng tiếng Việt có dấu.

## Phase 1 - Hoàn thiện xóa bản sao lưu cloud

Mục tiêu:

- Cho người dùng xóa bản sao lưu cloud của chính họ mà không ảnh hưởng dữ liệu local.

Thay đổi chính:

- Thêm API trong `CloudBackupService` để xóa `user_backups/{uid}/snapshots/current` và toàn bộ `chunks`.
- Thêm `BackupProvider.deleteCurrentBackup(User? currentUser)`.
- Thêm nút nguy hiểm trong màn `Sao lưu & Phục hồi`: `Xóa bản sao lưu cloud`.
- Dialog xác nhận ghi rõ: `Thao tác này chỉ xóa bản sao lưu trên cloud. Dữ liệu trên thiết bị vẫn được giữ.`
- Sau khi xóa thành công, metadata về `null`, UI hiển thị `Chưa có bản sao lưu`.
- Firestore rules hiện tại đã cho user ghi trong `user_backups/{uid}`, không cần mở rộng rules.

Validation:

- Xóa backup khi có snapshot.
- Xóa backup khi không có snapshot.
- Sau khi xóa, restore báo `Chưa có bản sao lưu trên cloud.`
- Local data không đổi.

Commit message:

```text
feat(backup): thêm xoá bản sao lưu cloud

- Xóa metadata và chunks của bản sao lưu hiện tại
- Thêm xác nhận rõ ràng rằng dữ liệu local không bị ảnh hưởng
- Cập nhật trạng thái cloud sau khi xóa thành công
```

## Phase 2 - Cải thiện lỗi và trạng thái người dùng

Mục tiêu:

- Không hiển thị lỗi kỹ thuật thô như `StateError`, `FirebaseException`, `DatabaseException` cho người dùng.

Thay đổi chính:

- Chuẩn hóa mapper lỗi trong `BackupProvider`.
- Các lỗi cần có thông báo tiếng Việt có dấu:
  - Chưa đăng nhập: `Bạn cần đăng nhập để sao lưu dữ liệu.`
  - Firebase user không khớp: `Tài khoản Firebase không khớp với người dùng hiện tại.`
  - Không có backup: `Chưa có bản sao lưu trên cloud.`
  - Backup thiếu chunk: `Bản sao lưu trên cloud chưa đầy đủ. Vui lòng sao lưu lại.`
  - Checksum sai: `Bản sao lưu không hợp lệ.`
  - Lỗi mạng/quyền Firestore: `Không thể kết nối Firestore. Vui lòng kiểm tra mạng và thử lại.`
  - Lỗi restore chung: `Khôi phục thất bại. Dữ liệu trên thiết bị đã được giữ nguyên.`
- Cải thiện snackbar/dialog trong `DataSettingsScreen` để dùng message từ provider.
- Không đổi logic backup/restore trong phase này.

Validation:

- Tắt mạng rồi backup.
- Tắt mạng rồi restore.
- Restore khi chưa có backup.
- Làm hỏng chunk trong Firestore rồi restore.
- Kiểm tra app không crash và nút thao tác bật lại.

Commit message:

```text
fix(backup): chuẩn hóa thông báo lỗi sao lưu

- Chuyển lỗi kỹ thuật sang thông báo tiếng Việt dễ hiểu
- Bổ sung thông báo cho lỗi mạng, thiếu backup và backup không hợp lệ
- Giữ dữ liệu local an toàn khi khôi phục thất bại
```

## Phase 3 - Hiển thị chi tiết bản sao lưu

Mục tiêu:

- Người dùng biết backup hiện tại chứa những gì, không chỉ thấy tổng số bản ghi.

Thay đổi chính:

- Trong trạng thái cloud, hiển thị:
  - Thời gian sao lưu.
  - Tổng số bản ghi.
  - Số `Tài khoản`.
  - Số `Danh mục`.
  - Số `Giao dịch`.
  - Số `Khoản vay`.
  - Số `Lịch sử trả nợ`.
  - Số `Ngân sách`.
- Dữ liệu lấy từ `metadata.recordCounts`.
- Nếu chưa có backup, chỉ hiển thị `Chưa có bản sao lưu` và `0 bản ghi`.
- Không thêm field Firestore mới; dùng metadata hiện có.

Validation:

- Backup dữ liệu rỗng hoặc ít dữ liệu.
- Backup có đủ account/category/transaction/loan/payment/budget.
- Kiểm tra số lượng hiển thị khớp Firestore metadata.

Commit message:

```text
feat(backup): hiển thị chi tiết nội dung bản sao lưu

- Hiển thị số bản ghi theo từng nhóm dữ liệu tài chính
- Dùng recordCounts từ metadata Firestore hiện có
- Giữ trạng thái rõ ràng khi chưa có bản sao lưu
```

## Phase 4 - Tăng độ phủ test cho restore và cloud chunks

Mục tiêu:

- Bắt sớm các lỗi FK/remap và lỗi cloud snapshot không đầy đủ.

Thay đổi chính:

- Bổ sung test restore cho:
  - Budget có `account_id`.
  - Transfer có `to_account_id`.
  - Loan có `transaction_id`.
  - Loan payment có `transaction_id`.
  - Nhiều account/category/budget cùng lúc.
- Bổ sung test cloud service cho:
  - Upload nhiều chunks.
  - Download thiếu chunk phải fail.
  - Upload mới thay thế chunks cũ.
- Không cần thêm snapshot history trong phase này.
- Không đổi `formatVersion` nếu không đổi payload schema.

Validation:

```bash
flutter test test/database/backup_dao_test.dart
flutter test
flutter analyze
```

Commit message:

```text
test(backup): mở rộng kiểm thử khôi phục và chunks

- Kiểm tra remap khóa ngoại cho budget, transfer, loan và payment
- Kiểm tra snapshot nhiều chunks và trường hợp thiếu chunk
- Bảo vệ luồng restore khỏi lỗi FOREIGN KEY khi schema mở rộng
```

## Assumptions

- Không làm snapshot history trong đợt này; vẫn dùng `snapshots/current`.
- Không backup feedback vì feedback đã là dữ liệu cloud riêng trong collection `feedbacks`.
- Không backup map hỗ trợ vì không có dữ liệu người dùng.
- Không backup settings/theme/currency trong đợt này để giữ snapshot tài chính đơn giản.
- Nếu thêm bảng tài chính mới sau này, phải cập nhật `BackupDao`, test restore, và cân nhắc tăng `BackupDao.formatVersion`.
