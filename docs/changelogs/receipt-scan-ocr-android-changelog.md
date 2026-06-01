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
