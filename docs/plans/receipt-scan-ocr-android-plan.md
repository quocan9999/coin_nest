# Plan Scan Hoá Đơn Android Cho CoinNest

## Summary

- Chỉ làm Android; không sửa iOS.
- Field `Số tiền` vẫn nhập thủ công bằng bàn phím số hệ thống.
- Khi field `Số tiền` focus, hiển thị thanh `Scan hoá đơn` ngay phía trên bàn phím Android.
- Scan mở màn camera có chụp ảnh và chọn ảnh thư viện.
- OCR on-device bằng ML Kit, chỉ điền `Số tiền` và gợi ý `Ghi chú`.
- Sau khi hoàn tất từng phase: cập nhật changelog, chạy kiểm tra phù hợp, stage đúng file, commit local ngay rồi mới qua phase kế tiếp.

## Rules Bắt Buộc

- Không chuyển sang phase kế tiếp nếu phase hiện tại chưa có commit local.
- Mỗi phase phải ghi changelog vào `docs/changelogs/receipt-scan-ocr-android-changelog.md`.
- Các lệnh `flutter`/`dart` chạy ngoài sandbox theo `AGENTS.md` sau khi xin approval.
- Comment tiếng Việt có dấu cho các khối code quan trọng: quyền camera/thư viện, vòng đời camera, chọn/chụp ảnh, OCR heuristic và áp dụng kết quả OCR.
- Không comment kiểu mô tả từng dòng đơn giản; comment phải giải thích mục đích, ràng buộc hoặc edge case.

## Key Changes

- Thêm dependency Android: `camera`, `image_picker`, `permission_handler`, `google_mlkit_text_recognition`.
- Cấu hình Android `CAMERA`; không thêm iOS plist/Podfile.
- Thêm OCR service/model/parser để đọc text và chọn tổng tiền đáng tin cậy.
- Thêm màn scan full-screen theo `AppTheme`, có camera preview, nút chụp, nút chọn ảnh, loading OCR.
- Tích hợp vào `AddTransactionScreen` bằng accessory bar `Scan hoá đơn` khi ô số tiền đang focus.
- Bottom sheet xác nhận kết quả scan trước khi áp dụng; message/dialog/snackbar đều tiếng Việt có dấu.

## Phases And Commits

- Phase 1 - Docs, dependency, Android config, OCR parser:
  - Tạo plan/changelog.
  - Thêm dependency, Android permission, OCR result model/service/parser.
  - Thêm test parser từ text giả lập hoá đơn mẫu.
  - Commit ngay:
    `feat(ocr): thêm nền tảng đọc hoá đơn Android`

- Phase 2 - Camera và chọn ảnh:
  - Thêm màn scan Android có preview, chụp ảnh, chọn ảnh thư viện.
  - Xử lý quyền camera, lỗi không có camera, lỗi người dùng huỷ chọn ảnh.
  - Thêm comment tiếng Việt cho camera lifecycle và permission flow.
  - Commit ngay:
    `feat(ocr): mở camera và chọn ảnh hoá đơn trên Android`

- Phase 3 - Tích hợp vào ô số tiền:
  - Giữ nhập tay bằng `TextFormField` hiện tại.
  - Hiện thanh `Scan hoá đơn` phía trên bàn phím khi field focus.
  - Áp dụng kết quả OCR vào số tiền và ghi chú sau xác nhận.
  - Thêm comment tiếng Việt cho logic không ghi đè ghi chú người dùng.
  - Commit ngay:
    `feat(transaction): tích hợp scan hoá đơn vào ô số tiền`

- Phase 4 - Hardening và validation:
  - Rà UI theo `DESIGN.md` và `AppTheme`.
  - Rà comment tiếng Việt ở các khối code quan trọng.
  - Test trên Genymotion A10 Android 11 và điện thoại thật Android 15 nếu thiết bị sẵn sàng.
  - Cập nhật changelog kết quả validation.
  - Commit ngay:
    `test(ocr): hoàn thiện kiểm thử scan hoá đơn Android`

## Test Plan

- Parser test:
  - Coffee Binbo -> `89.000`.
  - POS365 -> `167.000`, không lấy `334.000`.
  - Phiếu thanh toán -> `165.000`.
  - Bách Hoá Xanh -> ưu tiên `85.000`.
- Android manual:
  - Genymotion A10 Android 11: nhập tay, chọn ảnh thư viện, xử lý camera lỗi/không có camera.
  - Điện thoại thật Android 15: xin quyền camera, chụp ảnh, chọn ảnh, OCR, áp dụng kết quả.
- Validation:
  - `flutter pub get` khi thêm dependency.
  - `dart format .`, `flutter analyze`, `flutter test` ngoài sandbox sau approval.
  - Nếu thiết bị không sẵn sàng ở Phase 4, ghi rõ trong changelog phần chưa test manual.

## Assumptions

- Không đổi SQLite schema, không bump `dbVersion`.
- Không lưu ảnh hoá đơn vào database/cloud.
- Không dùng cloud OCR, Firebase Storage hoặc Cloud Functions.
- Hạng mục, tài khoản và ngày vẫn do người dùng chọn thủ công.
