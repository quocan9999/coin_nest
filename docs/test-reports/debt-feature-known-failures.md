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

## 2026-05-27 09:50:17 +07:00 - Quay lại từ chi tiết luôn làm mới màn theo dõi dù không thay đổi dữ liệu

- Phạm vi: `LoanDetailScreen` và `LoanTrackingScreen`.
- Kịch bản:
  - Mở một khoản cho vay từ màn `Theo dõi vay nợ`.
  - Chỉ xem chi tiết, sau đó nhấn nút quay lại; không sửa, thanh toán hoặc xóa.
- Kỳ vọng:
  - Quay lại màn theo dõi mà không báo có thay đổi dữ liệu.
  - Không gọi lại `loadLoans()` nếu khoản vay không bị cập nhật.
- Hành vi đọc được từ mã hiện tại:
  - Nút quay lại của `LoanDetailScreen` luôn gọi `Navigator.pop(context, true)`.
  - `LoanTrackingScreen._openLoanDetail()` hiểu kết quả `true` là dữ liệu đã thay đổi và gọi `_loadLoans()`.
  - Vì vậy thao tác chỉ xem rồi quay lại vẫn phát sinh reload không cần thiết, có thể hiển thị loading/ảnh hưởng độ mượt của điều hướng.
- Liên hệ với failure của bộ test:
  - Log mới cho thấy test tap tab `Còn nợ` khi route màn theo dõi chưa nhận pointer, nên failure hiện tại được sửa ở phần đồng bộ điều hướng của test.
  - Defect reload thừa là hành vi runtime riêng được ghi nhận tại đây, không sửa trong nhánh kiểm thử.
- Verification cần thực hiện sau khi có fix runtime:
  - Thêm widget/integration assertion: quay lại từ detail mà không thao tác dữ liệu không kích hoạt refresh.
  - Giữ assertion refresh sau các luồng có thay đổi thật như sửa, thanh toán hoặc xóa.
