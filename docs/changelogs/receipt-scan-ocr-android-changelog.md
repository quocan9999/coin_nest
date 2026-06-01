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
