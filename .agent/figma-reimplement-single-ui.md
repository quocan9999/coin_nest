# Quy trình reimplement một UI Flutter duy nhất lên Figma

Bạn đang reimplement **một UI/screen duy nhất** từ Flutter source code lên Figma bằng `figma-ui-mcp`.

Quy trình này không loop toàn bộ app, không loop folder, không tự chuyển sang UI khác. Mỗi lần chạy chỉ xử lý đúng UI mà người dùng chỉ định trong prompt bằng biến `UI=...`.

## Cách nhận UI mục tiêu

Người dùng sẽ truyền một biến duy nhất trong prompt:

```text
UI=auth/login_screen
```

Đây là format khuyến nghị vì nó cho biết cả folder chức năng và screen:

- `UI=auth/login_screen` -> source `lib/screens/auth/login_screen.dart`, feature label `Auth`
- `UI=auth/forgot_password_screen` -> source `lib/screens/auth/forgot_password_screen.dart`, feature label `Auth`
- `UI=loans/payment_screen` -> source `lib/screens/loans/payment_screen.dart`, feature label `Loans`

Nếu cần chỉ rõ path đầy đủ:

```text
UI=lib/screens/auth/login_screen.dart
```

Nếu chắc chắn tên screen không bị trùng, có thể dùng tên screen ngắn:

```text
UI=login_screen
```

Quy tắc resolve UI:

1. Nếu `UI` là path `.dart`, dùng đúng file đó.
2. Nếu `UI` có dạng `{folder}/{screen}`, resolve thành `lib/screens/{folder}/{screen}.dart`.
3. Nếu `UI` là tên không có `.dart` và không có `/`, tìm file khớp chính xác theo mẫu `lib/screens/**/{UI}.dart`.
4. Sau khi resolve source path, suy ra feature label/background từ folder chức năng theo mapping bên dưới.
5. Nếu không tìm thấy file, dừng và báo rõ.
6. Nếu tìm thấy nhiều file trùng tên khi dùng tên ngắn, dừng và yêu cầu người dùng truyền format `{folder}/{screen}` hoặc path đầy đủ.
7. Không xử lý bất kỳ file screen nào khác ngoài UI đã resolve.

## MCP và node type được phép

- Dùng `figma_status` trước để kiểm tra kết nối.
- Dùng `figma_docs` nếu cần xác nhận cú pháp tool.
- Dùng `figma_read get_page_nodes` để kiểm tra canvas hiện tại.
- Dùng `figma_write` để tạo/cập nhật page, feature label/background và screen FRAME.
- Dùng `figma_read screenshot` sau khi hoàn tất để kiểm tra kết quả.

`figma-ui-mcp` không hỗ trợ Section. Không tạo Section.

Chỉ dùng các node type sau:

- `FRAME`
- `RECTANGLE`
- `ELLIPSE`
- `LINE`
- `TEXT`
- `SVG`
- `VECTOR`
- `IMAGE`

Dùng `FRAME` để thay cho group/container, screen, card, app bar, bottom bar, dialog container, list item container và các layout block lớn.

## Quy tắc field/schema của `figma-ui-mcp`

Khi tạo, sửa hoặc apply variable cho node Figma, phải dùng đúng field mà `figma-ui-mcp` hỗ trợ.

Với node type `TEXT`:

- Dùng `fill` để set màu chữ.
- Dùng `fill` để bind/apply color variable cho màu chữ.
- Không dùng `fontColor`.
- Không dùng `textColor`.
- Không dùng `color` cho màu chữ.
- Nếu gặp lỗi kiểu `Field "fontColor" is not available on node type TEXT`, phải sửa lại thao tác đó sang `fill` rồi tiếp tục trên frame hiện có.

Với text style:

- Dùng `fontSize` cho cỡ chữ.
- Dùng `fontFamily` cho font family.
- Dùng `fontStyle` cho weight/style nếu tool yêu cầu.
- Dùng `letterSpacing` cho letter spacing.
- Dùng `lineHeight` cho line height.
- Dùng `characters` cho nội dung text.

Không tự bịa field theo Flutter/CSS nếu `figma-ui-mcp` không hỗ trợ. Nếu không chắc field nào đúng, gọi `figma_docs` trước khi `figma_write`.

## Nguồn bắt buộc phải đọc

Luôn đọc trước khi vẽ hoặc sửa Figma:

- `DESIGN.md`
- `lib/theme/app_theme.dart`
- File screen `.dart` đã resolve từ biến `UI`

Lưu ý: file theme thật trong repo là `lib/theme/app_theme.dart`.

Khi screen import local widget/component, phải đọc các file đó nếu chúng ảnh hưởng tới UI:

- Widget/component local.
- Theme extension/helper.
- Model/enum/helper ảnh hưởng tới text, trạng thái, icon, màu sắc, button style hoặc layout.

## Quy tắc fidelity bắt buộc

Mục tiêu là UI trên Figma phải khớp với source code Flutter hiện tại.

- Tuân thủ nghiêm ngặt `DESIGN.md`.
- Tuân thủ nghiêm ngặt `lib/theme/app_theme.dart`.
- Source code screen là nguồn sự thật cho layout và cấu trúc.
- Không tạo visual system mới.
- Không làm UI đẹp hơn code.
- Không tự chọn màu, font, spacing, radius hoặc shadow nếu code/theme đã định nghĩa.
- Không dùng màu gần giống. Phải dùng đúng token hoặc đúng giá trị màu trong code/theme.
- Button, text, icon, card, input, background, border, shadow/elevation phải khớp code/theme.
- Nếu button trong app là màu xanh thì trên Figma cũng phải là màu xanh đúng token/hex từ code/theme, không được đổi sang cam hoặc màu khác.
- Nếu code dùng `Theme.of(context)`, `AppTheme`, `ColorScheme`, text theme hoặc custom style, phải trace về giá trị trong `app_theme.dart` rồi áp dụng vào Figma.
- Nếu `DESIGN.md` và `app_theme.dart` khác layout cụ thể trong screen, dùng `app_theme.dart` cho token/style và dùng source screen cho layout/structure.

Phải kiểm tra kỹ các phần sau, nếu trong code mà không sử dụng cái nào thì không được tự ý thêm vào (ví dụ nếu screen đó không sử dụng BottomNavigationBar thì không được tự ý thêm BottomNavigationBar):

- Background.
- AppBar.
- BottomNavigationBar.
- FAB.
- Button primary/secondary/destructive.
- Text color, font size, font weight, line height.
- Input/TextField.
- Card/ListTile/List item.
- Icon và màu icon.
- Padding, margin, spacing.
- Border radius.
- Border color/width.
- Shadow/elevation.
- Default UI của screen.
- Dialog/bottom sheet/snackbar chỉ dựng nếu chúng đang xuất hiện trong default UI ban đầu của screen. Không tạo frame riêng cho các state này.

Không tự thêm UI hệ thống:

- Không dựng iOS/Android status bar giả.
- Không thêm giờ như `9:41`.
- Không thêm icon wifi/sóng mạng.
- Không thêm icon pin.
- Không thêm home indicator/navigation bar giả.
- Chỉ dựng các phần này nếu source screen Flutter thật có widget custom tự vẽ chúng trong code. Nếu chúng chỉ là chrome/status bar của thiết bị hoặc preview thì bỏ qua.

Không tạo UI theo state:

- Không tạo frame phụ cho loading, empty, error, success, validation, dialog hoặc bottom sheet.
- Không tạo các frame như `login_screen__default`, `login_screen__loading`, `login_screen__error`, `login_screen__empty`, `login_screen__validation`, `login_screen__dialog`, `login_screen__bottom_sheet`.
- Mỗi lần chạy chỉ được tạo hoặc cập nhật đúng một screen FRAME chính cho UI được chỉ định.
- Nếu source code có nhiều state, chỉ dựng trạng thái mặc định/initial/default mà người dùng thấy khi mở screen lần đầu.
- Nếu không chắc default state là gì, dùng state không loading, không error, không empty, không modal, không bottom sheet, trừ khi source screen mặc định hiển thị trạng thái đó ngay khi mở.

## Figma target

Chỉ dùng một Figma page:

- Page name: `App Screens`

Trong page `App Screens`:

- Screen UI phải là một top-level `FRAME` trực tiếp trên page `App Screens`.
- Mỗi screen FRAME phải có resolution cố định `390 x 884`.
- Width của screen FRAME: `390`.
- Height của screen FRAME: `884`.
- Không tự đổi resolution theo screenshot, device preset hoặc nội dung.
- Không được nest screen FRAME vào bên trong FRAME khác.
- Không được đặt screen FRAME làm child của feature FRAME container.
- Lý do: Figma prototype `Navigate to` cần screen là top-level frame để có thể chọn từng screen riêng.
- Không tạo top-level FRAME container làm parent chứa screen.
- Không tạo page mới cho folder.
- Không tạo Section.
- Không tạo Group.
- Grouping theo chức năng chỉ là visual grouping, không phải parent-child structure.
- Để nhóm theo chức năng, dùng `TEXT` label, ví dụ `Auth`, `Loans`, `Reports`.
- Nếu cần nền nhóm chức năng, dùng `RECTANGLE` background đặt phía sau các screen liên quan, nhưng screen FRAME vẫn phải là top-level sibling, không được nằm trong RECTANGLE hoặc FRAME background.
- Ví dụ đúng: `TEXT Auth` và top-level `FRAME auth__login_screen`, top-level `FRAME auth__forgot_password_screen`.
- Ví dụ sai: `FRAME Auth` chứa child `login_screen`.

Mapping folder chức năng sang label nhóm:

- `lib/screens/accounts` -> `Accounts`
- `lib/screens/auth` -> `Auth`
- `lib/screens/budgets` -> `Budgets`
- `lib/screens/categories` -> `Categories`
- `lib/screens/dashboard` -> `Dashboard`
- `lib/screens/home` -> `Home`
- `lib/screens/loans` -> `Loans`
- `lib/screens/onboarding` -> `Onboarding`
- `lib/screens/reports` -> `Reports`
- `lib/screens/settings` -> `Settings`
- `lib/screens/splash` -> `Splash`
- `lib/screens/transactions` -> `Transactions`

Nếu UI nằm ngoài mapping, tạo label nhóm theo tên folder cha viết PascalCase.

## Naming

- Feature label: tên theo mapping, ví dụ `Auth`.
- Main screen FRAME phải là top-level frame và nên có prefix folder để tránh trùng tên khi prototype, ví dụ `auth__login_screen`.
- Main screen FRAME luôn có kích thước `390 x 884`.
- Nếu đã có frame cũ tên ngắn như `login_screen`, có thể cập nhật trực tiếp frame đó nếu nó là top-level frame.
- Nếu frame cũ đang nằm trong feature container, đưa frame đó ra top-level hoặc tạo lại đúng một top-level frame mới rồi không duplicate thêm.
- Chỉ tạo một main screen FRAME duy nhất cho UI được chỉ định.
- Không thêm suffix state vào tên frame.
- Không tạo frame phụ theo state.

Nếu frame đã tồn tại:

- Cập nhật/sửa frame hiện có.
- Không duplicate frame, trừ khi frame cũ sai cấu trúc nghiêm trọng đến mức không thể sửa.
- Nếu phải tạo lại, đổi tên frame cũ thành `{screen_name}__old` rồi tạo frame mới đúng tên chính.

## Progress file

Dùng progress riêng cho một UI:

- `.agent/figma-single-ui-progress.json`

Structure đề xuất:

```json
{
  "figmaPage": "App Screens",
  "ui": "login_screen",
  "sourcePath": "lib/screens/auth/login_screen.dart",
  "featureLabel": "Auth",
  "screenFrame": "auth__login_screen",
  "status": "pending",
  "lastStep": "",
  "notes": []
}
```

Cập nhật progress sau từng bước quan trọng:

- resolved_source
- read_design
- read_theme
- read_screen
- read_imported_widgets
- inspected_figma
- wrote_frame
- verified_screenshot
- completed

Khi người dùng truyền `UI` khác với progress cũ, reset progress cho UI mới.

## Quy trình thực thi

1. Đọc biến `UI` từ prompt người dùng.
2. Resolve UI thành đúng source path `.dart`.
3. Kiểm tra `figma_status`.
4. Đọc `DESIGN.md`.
5. Đọc `lib/theme/app_theme.dart`.
6. Đọc file screen source.
7. Đọc local widget/component được import và có ảnh hưởng UI.
8. Trace tất cả style từ screen về theme/token/code, đặc biệt màu text, màu button, background, input, icon và card.
9. Xác định và loại bỏ mọi UI hệ thống giả như giờ, wifi, pin, home indicator nếu source screen không tự vẽ chúng.
10. Tạo hoặc chuyển sang page `App Screens`.
11. Tạo hoặc tái sử dụng `TEXT` feature label theo folder chức năng nếu cần.
12. Nếu có background nhóm, dùng `RECTANGLE` background phía sau, không dùng FRAME container.
13. Tìm screen FRAME hiện có trên page.
14. Nếu screen FRAME hiện có đang nested trong FRAME container cũ, đưa nó ra thành top-level frame nếu tool hỗ trợ; nếu tool không hỗ trợ move/reparent, tạo đúng một top-level screen FRAME mới và không tạo duplicate thêm.
15. Nếu có top-level frame hiện có, set frame size về đúng `390 x 884`, so sánh với code và sửa trực tiếp.
16. Nếu chưa có frame, tạo đúng một top-level screen FRAME mới với kích thước `390 x 884`.
17. Reimplement UI bằng node type hợp lệ.
18. Chỉ dựng default UI của screen. Không tạo state frame phụ.
19. Chạy `figma_read screenshot` để verify.
20. Nếu thấy sai màu/style/layout so với code/theme, sửa lại ngay.
21. Cập nhật `.agent/figma-single-ui-progress.json` status `completed`.
22. Dừng lại. Không xử lý UI khác.

## Resume khi bị ngắt

Khi resume:

1. Đọc lại biến `UI` từ prompt.
2. Đọc `.agent/figma-single-ui-progress.json`.
3. Nếu progress cùng UI, tiếp tục từ `lastStep`.
4. Nếu progress khác UI, reset progress cho UI mới.
5. Re-read `DESIGN.md`, `lib/theme/app_theme.dart`, source screen và imported widgets trước khi sửa tiếp.
6. Không bỏ qua bước kiểm tra fidelity chỉ vì frame đã tồn tại.
7. Verify screenshot trước khi kết thúc.

## Failure handling

- Nếu không tìm thấy source path từ `UI`, dừng và báo rõ.
- Nếu có nhiều file trùng tên, dừng và yêu cầu dùng path đầy đủ.
- Nếu Figma/MCP/plugin/auth bị lỗi, dừng và báo blocker.
- Nếu source code chưa rõ, đọc thêm imported widget/helper thay vì đoán.
- Không xử lý bất kỳ UI nào khác để "tiện thể" hoàn thành.
