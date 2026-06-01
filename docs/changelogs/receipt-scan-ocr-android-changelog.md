# Receipt Scan OCR Android Changelog

## 2026-06-01 - Phase 1

- Tạo plan triển khai Android-only tại `docs/plans/receipt-scan-ocr-android-plan.md`.
- Thêm dependency `camera`, `image_picker`, `permission_handler`, `google_mlkit_text_recognition`.
- Thêm quyền `android.permission.CAMERA` và đặt Android `minSdk = 24` theo yêu cầu plugin camera/image picker mới.
- Thêm `ReceiptScanResult`, `ReceiptOcrService` và `ReceiptOcrParser` để đọc chữ bằng ML Kit và chọn tổng tiền hoá đơn.
- Thêm test parser cho các mẫu Coffee Binbo, POS365, phiếu thanh toán và Bách Hoá Xanh.

Validation:

- `flutter pub get`: pass.
- `dart format lib/models/receipt_scan_result.dart lib/services/receipt/receipt_ocr_service.dart test/services/receipt_ocr_parser_test.dart`: pass.
- `flutter test test/services/receipt_ocr_parser_test.dart`: pass.
- `flutter analyze`: pass.

## 2026-06-01 - Phase 2

- Thêm `ReceiptScanScreen` cho Android với camera preview, nút chụp ảnh và nút chọn ảnh từ thư viện.
- Xử lý quyền camera bằng dialog tiếng Việt có lối mở cài đặt ứng dụng.
- Giữ fallback chọn ảnh thư viện khi Genymotion hoặc thiết bị không mở được camera.
- Kết nối ảnh chụp/ảnh chọn với `ReceiptOcrService` để trả `ReceiptScanResult` về caller.
- Thêm comment tiếng Việt cho lifecycle camera, lỗi camera trên Genymotion và hành vi quyền thư viện Android.

Validation:

- `dart format lib/screens/transactions/receipt_scan_screen.dart`: pass.
- `flutter analyze`: pass.
- `flutter test test/services/receipt_ocr_parser_test.dart`: pass.

## 2026-06-01 - Phase 3

- Tích hợp `ReceiptScanScreen` vào `AddTransactionScreen`.
- Giữ ô `Số tiền` nhập tay bằng bàn phím số Android như trước.
- Thêm thanh `Scan hoá đơn` khi ô số tiền đang focus và bàn phím đang mở.
- Thêm bottom sheet xác nhận kết quả scan trước khi điền số tiền và ghi chú.
- Không ghi đè ghi chú nếu người dùng đã nhập nội dung trước đó.

Validation:

- `dart format lib/screens/transactions/add_transaction_screen.dart`: pass.
- `flutter analyze`: pass.
- `flutter test test/services/receipt_ocr_parser_test.dart`: pass.

## 2026-06-01 - Phase 7

- Sửa nút `Xong/=` từ hình chữ nhật dọc thành một ô vuông cùng kích thước với các phím còn lại.
- Đưa keypad về grid 4 cột cố định để các hàng `1 2 3` và `0 000 xoá` thẳng hàng với `4 5 6`, `7 8 9`.
- Giữ ô trống ở cột phải của hàng `1 2 3` để nút `Xong/=` nằm ở hàng cuối mà không làm lệch bố cục.

Validation:

- `dart format lib/screens/transactions/add_transaction_screen.dart`: pass.
- `flutter analyze`: pass.
- `flutter test test/services/receipt_ocr_parser_test.dart`: pass.

## 2026-06-01 - Phase 6

- Reset bỏ commit lỗi `5ff3cec` vì layout dùng `Expanded` theo trục dọc trong `bottomNavigationBar` gây `BoxConstraints forces an infinite height`.
- Làm lại nút phải của bàn phím bằng chiều cao cố định để tránh lỗi `RenderBox was not laid out`.
- Gộp hai nút `Xong` thành một nút lớn ở cạnh phải bàn phím custom.
- Khi số tiền có biểu thức `+`, `-`, `×`, `÷`, nút lớn đổi từ `Xong` sang `=`.
- Bấm `=` chỉ tính kết quả và giữ bàn phím mở; sau khi tính xong nút đổi lại thành `Xong`.
- Bấm `Xong` mới đóng bàn phím custom.

Validation:

- `dart format lib/screens/transactions/add_transaction_screen.dart`: pass.
- `flutter analyze`: pass.
- `flutter test test/services/receipt_ocr_parser_test.dart`: pass.

## 2026-06-01 - Phase 4

- Rà lại comment tiếng Việt ở các khối quan trọng: OCR heuristic, camera lifecycle, lỗi camera Genymotion, quyền thư viện Android và logic không ghi đè ghi chú.
- Rà nhanh UI mới để bảo đảm phần thêm mới dùng `AppTheme` cho màu, spacing và radius.
- Dọn thư mục metadata build `android/.kotlin/` sinh ra trong lúc build để không đưa artifact vào commit.

Validation:

- `flutter test`: pass toàn bộ 71 test.
- `flutter devices`: phát hiện Genymotion `A10` Android 11 (API 30); chưa thấy điện thoại thật Android 15 trong danh sách thiết bị.
- `flutter build apk --debug`: tạo được `build/app/outputs/flutter-apk/app-debug.apk` khoảng 85.9 MB, nhưng lệnh không kết thúc sạch trong timeout 5 phút của công cụ.
- Chưa chạy manual test trên Android 15 vì thiết bị không được Flutter liệt kê ở thời điểm validation.

## 2026-06-01 - Phase 5

- Thay thanh `Scan hoá đơn` bám bàn phím hệ thống bằng bàn phím custom nằm trong app để không che toàn bộ màn hình.
- Giữ thao tác nhập số tiền qua custom keypad với các phím `0-9`, `000`, `C`, xoá lùi, `Xong`.
- Thêm phép tính cơ bản `+`, `-`, `×`, `÷`; khi bấm `Xong` hoặc lưu giao dịch, biểu thức được tính về số tiền cuối.
- Giữ nút `Scan hoá đơn` ở hàng trên của bàn phím custom.
- Thêm comment tiếng Việt cho luồng bàn phím custom và thứ tự tính nhân/chia trước cộng/trừ.

Validation:

- `dart format lib/screens/transactions/add_transaction_screen.dart`: pass.
- `flutter analyze`: pass.
- `flutter test test/services/receipt_ocr_parser_test.dart`: pass.
