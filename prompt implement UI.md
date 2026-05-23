# Reimplement một UI duy nhất

Chỉ sửa dòng `UI=...`. Các dòng còn lại giữ nguyên.

Ví dụ:

```text
UI=auth/login_screen
UI=auth/forgot_password_screen
UI=loans/payment_screen
UI=reports/current_finance_screen
```

## Prompt bắt đầu

```text
UI=auth/login_screen

Hãy đọc và thực thi .agent/figma-reimplement-single-ui.md cho đúng UI ở biến UI.

Chỉ tạo hoặc cập nhật một top-level screen FRAME chính kích thước 390x884 để prototype được tới screen đó. Không nest screen vào FRAME container, không tạo state frame, không duplicate, không xử lý UI khác. Không thêm status bar giả như giờ, wifi, pin. Với TEXT, dùng fill cho màu chữ, không dùng fontColor.
```

## Prompt resume khi bị ngắt

```text
UI=auth/login_screen

Resume .agent/figma-reimplement-single-ui.md cho đúng UI ở biến UI.

Đọc .agent/figma-single-ui-progress.json nếu có, tiếp tục UI này, giữ đúng một top-level screen FRAME chính kích thước 390x884 để prototype được tới screen đó. Không nest screen vào FRAME container, không tạo state frame, không duplicate, không xử lý UI khác. Không thêm status bar giả như giờ, wifi, pin. Nếu lỗi trước đó là fontColor trên TEXT, sửa thao tác đó sang fill rồi tiếp tục.
```
