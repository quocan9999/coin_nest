# Debt Feature Known Failures

## 2026-05-27 - Xóa khoản debt bằng user không sở hữu báo thành công

- Phạm vi: `LoanProvider.deleteLoan` và `LoanDao.deleteForUserWithRollback`.
- Kịch bản dự kiến:
  - User A tạo một khoản vay.
  - Gọi xóa khoản vay đó bằng `userId` của user B.
- Kỳ vọng:
  - Không xóa dữ liệu của user A.
  - Thao tác của user B trả về thất bại để UI không thông báo xóa thành công.
- Hành vi đọc được từ mã hiện tại:
  - DAO lọc theo `id` và `user_id`, do đó trả `0` khi user B không sở hữu khoản vay.
  - Provider không kiểm tra số bản ghi DAO đã xóa và luôn tải lại dữ liệu rồi trả `true` nếu không có exception.
- Quyết định kiểm thử:
  - Không thêm regression test executable yêu cầu `deleteLoan` trả `false`, vì test đó sẽ đỏ trong khi task hiện tại không sửa logic runtime.
  - Giữ coverage cách ly ở các truy vấn/thanh toán đã đáp ứng hành vi hiện hữu; lỗi xóa cần được sửa ở task runtime riêng trước khi bật regression test.
- Verification cần thực hiện sau khi có fix runtime:
  - Thêm provider test: user khác xóa loan trả `false`, loan của chủ sở hữu còn nguyên, balance và transactions không thay đổi.
