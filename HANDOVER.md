# CoinNest - Handover Document

Cập nhật: 29/05/2026  
Phạm vi quét: toàn bộ workspace `coin_nest`

## 1. Tổng quan & Công nghệ sử dụng

### Mục đích chính

CoinNest là ứng dụng Flutter quản lý tài chính cá nhân. Dữ liệu nghiệp vụ chính được lưu trong SQLite cục bộ theo từng người dùng, còn Firebase đang được dùng chủ yếu cho xác thực danh tính.

Các nhóm nghiệp vụ chính:

- Đăng ký, đăng nhập, đăng xuất bằng email/password, số điện thoại OTP và Google Sign-In.
- Quản lý tài khoản tiền: tiền mặt, ngân hàng, ví điện tử, tiết kiệm, thẻ tín dụng, loại khác.
- Ghi nhận giao dịch thu, chi, chuyển khoản, vay, cho vay và điều chỉnh số dư.
- Quản lý hạng mục thu/chi, bao gồm hạng mục mặc định và hạng mục tùy chỉnh.
- Quản lý ngân sách chi tiêu theo chu kỳ.
- Theo dõi khoản vay, khoản cho vay và lịch sử thanh toán/thu nợ.
- Báo cáo tài chính hiện tại, báo cáo thu chi, phân tích thu/chi theo ngày/tháng/năm và theo dõi vay nợ.

### Công nghệ, framework và thư viện chính

| Nhóm | Công nghệ / thư viện | Phiên bản / nguồn |
| --- | --- | --- |
| Ngôn ngữ | Dart | SDK constraint `^3.10.8` trong `pubspec.yaml` |
| Framework | Flutter | Cross-platform, Material 3 |
| State management | `provider` | Khai báo `^6.1.5`, lock `6.1.5+1` |
| Local database | SQLite qua `sqflite` | Khai báo `^2.4.2`, lock `2.4.2`; DB `coinnest.db`, schema version `3` |
| File/path | `path_provider`, `path` | Lock `2.1.5`, `1.9.1` |
| Firebase core | `firebase_core` | Lock `4.7.0` |
| Firebase Auth | `firebase_auth` | Lock `6.4.0` |
| Google Sign-In | `google_sign_in` | Lock `7.2.0` |
| Callable Functions client | `cloud_functions` | Lock `6.2.0` |
| Firebase Storage | `firebase_storage` | Lock `13.3.0`, đang khai báo nhưng chưa thấy sử dụng trong `lib/` |
| Biểu đồ | `fl_chart` | Lock `0.70.2` |
| Định dạng ngày/tiền | `intl` | Lock `0.19.0`, locale chính `vi_VN` |
| Font | `google_fonts` | Khai báo `^6.2.1`, lock `6.3.3`; theme dùng Be Vietnam Pro |
| Local preferences | `shared_preferences` | Khai báo `^2.3.4`, lock `2.5.5`; lưu session, onboarding, settings |
| Secure storage | `flutter_secure_storage` | Lock `9.2.4`, đang khai báo nhưng chưa thấy sử dụng trong `lib/` |
| Crypto | `crypto` | Khai báo `^3.0.6`, lock `3.0.7`; dùng hash password local legacy |
| UUID | `uuid` | Khai báo `^4.5.1`, lock `4.5.3`, đang khai báo nhưng chưa thấy sử dụng trong `lib/` |
| SQLite debug viewer | `saropa_drift_advisor` | Lock `3.5.1`, chạy ở debug tại `http://localhost:8642` |
| Lint | `flutter_lints` | Lock `6.0.0`, cấu hình tại `analysis_options.yaml` |
| Cloud Functions runtime | Node.js | `18` trong `functions/package.json` và `firebase.json` |
| Cloud Functions libs | `firebase-admin`, `firebase-functions` | Khai báo `^12.0.0`, `^5.0.0`; không có `package-lock.json` trong repo |
| Android build | Gradle/Kotlin/Java | Android Gradle Plugin qua Flutter template, Java 17, Firebase BOM `34.12.0` |

### Cơ sở dữ liệu

Ứng dụng dùng SQLite cục bộ qua `sqflite`.

- Tên DB: `coinnest.db`.
- Version schema: `3`.
- Bảng chính: `users`, `accounts`, `categories`, `transactions`, `loans`, `loan_payments`, `budgets`, `feedbacks`.
- Foreign key được bật bằng `PRAGMA foreign_keys = ON`.
- Dữ liệu tài chính hiện chưa sync lên cloud; Firebase không phải source of truth cho account/transaction/budget/loan.

## 2. Cấu trúc thư mục

```text
coin_nest/
|-- AGENTS.md
|-- CLAUDE.md
|-- DESIGN.md
|-- HANDOVER.md
|-- README.md
|-- analysis_options.yaml
|-- firebase.json
|-- pubspec.yaml
|-- pubspec.lock
|-- android/
|   |-- app/
|   |   |-- build.gradle.kts
|   |   |-- google-services.json
|   |   `-- src/
|   |-- build.gradle.kts
|   `-- settings.gradle.kts
|-- functions/
|   |-- index.js
|   `-- package.json
|-- lib/
|   |-- app.dart
|   |-- firebase_options.dart
|   |-- main.dart
|   |-- database/
|   |   |-- database_helper.dart
|   |   |-- *_dao.dart
|   |-- models/
|   |-- providers/
|   |-- screens/
|   |   |-- accounts/
|   |   |-- auth/
|   |   |-- budgets/
|   |   |-- categories/
|   |   |-- dashboard/
|   |   |-- home/
|   |   |-- loans/
|   |   |-- onboarding/
|   |   |-- reports/
|   |   |-- settings/
|   |   |-- splash/
|   |   `-- transactions/
|   |-- services/
|   |   `-- auth/
|   |-- theme/
|   `-- utils/
|-- web/
|   |-- index.html
|   |-- manifest.json
|   `-- icons/
|-- ios/
|-- linux/
|-- macos/
`-- windows/
```

### Vai trò các thư mục lớn

| Thư mục / file | Chức năng |
| --- | --- |
| `lib/` | Mã nguồn Flutter/Dart chính của app. |
| `lib/main.dart` | Bootstrap Firebase, Google Sign-In, locale, debug SQLite viewer và đăng ký Provider. |
| `lib/app.dart` | Root `MaterialApp`, gắn theme và màn hình đầu tiên. |
| `lib/database/` | SQLite helper và DAO cho từng bảng nghiệp vụ. |
| `lib/models/` | Entity/data model plain Dart, chuyển đổi qua/lại SQLite row. |
| `lib/providers/` | State và async orchestration theo feature, dùng `ChangeNotifier`. |
| `lib/screens/` | UI screen theo feature. Screen đang trực tiếp dùng `Navigator.push` thay vì route module tập trung. |
| `lib/services/` | Tích hợp ngoài hệ thống, hiện có service xác thực Firebase. |
| `lib/theme/` | Design tokens, color system, spacing, radius, typography và `ThemeData`. |
| `lib/utils/` | Constants, formatter, validator, security helper, phone helper, icon helper. |
| `functions/` | Firebase Cloud Functions Node.js, hiện có callable reset password bằng phone. |
| `android/` | Cấu hình Android native, Firebase Google Services, Gradle/Kotlin. |
| `ios/`, `macos/`, `linux/`, `windows/`, `web/` | Shell platform của Flutter. Firebase runtime hiện mới trả config cho Android trong code. |
| `DESIGN.md` | Quy định design system và UI style. Cần đọc trước khi sửa UI. |
| `AGENTS.md`, `CLAUDE.md`, `lib/screens/CLAUDE.md` | Quy tắc coding, kiến trúc, đặt file và UI cho contributor. |

## 3. Bản đồ chức năng của File

### Entrypoint, cấu hình và theme

| File | Chức năng / nhiệm vụ | Hàm/class quan trọng |
| --- | --- | --- |
| `lib/main.dart` | Khởi tạo Flutter binding, Firebase, Google Sign-In, portrait orientation, locale `vi_VN`, SQLite debug viewer trong debug, đăng ký `MultiProvider`. | `main()` |
| `lib/app.dart` | Root widget của app, cấu hình `MaterialApp`, theme và `SplashScreen`. | `CoinNestApp` |
| `lib/firebase_options.dart` | Firebase options generated/local. `currentPlatform` hiện chỉ trả config Android; web/iOS/macOS/windows/linux throw `UnsupportedError`. | `DefaultFirebaseOptions.currentPlatform`, `android` |
| `lib/theme/app_theme.dart` | Design system: màu semantic, surface, spacing, radius, `ThemeData`, text theme Be Vietnam Pro. | `AppTheme.lightTheme`, color/spacing/radius constants |
| `pubspec.yaml` | Khai báo package app, version `1.0.0+1`, Dart SDK và dependencies. | `dependencies`, `dev_dependencies` |
| `analysis_options.yaml` | Cấu hình lint. | include `package:flutter_lints/flutter.yaml` |
| `firebase.json` | Cấu hình Firebase Functions Node 18 và FlutterFire app ids. | `functions`, `flutter.platforms` |
| `android/app/build.gradle.kts` | Cấu hình Android app, google-services, Java 17, Firebase BOM, rename APK output. | `plugins`, `defaultConfig`, `applicationVariants` |
| `functions/package.json` | Package Cloud Functions, script emulator/deploy/logs. | `serve`, `deploy`, `logs`; engine Node 18 |

### Models

| File | Chức năng / nhiệm vụ | Hàm/class quan trọng |
| --- | --- | --- |
| `lib/models/user.dart` | User local mapping với Firebase UID và provider auth. | `User`, `fromMap`, `toMap`, `copyWith` |
| `lib/models/account.dart` | Tài khoản tài chính, số dư, loại tài khoản, currency, active/include flags. | `Account`, `fromMap`, `toMap`, `copyWith` |
| `lib/models/category.dart` | Hạng mục thu/chi, icon, màu, parent-child, default/active flags. | `Category`, `fromMap`, `toMap`, `copyWith` |
| `lib/models/transaction_model.dart` | Giao dịch thu/chi/chuyển khoản/vay/cho vay/điều chỉnh số dư, có joined fields từ DAO. | `TransactionModel`, `isNegative`, `signedAmount` |
| `lib/models/budget.dart` | Ngân sách chi tiêu, period, số tiền đã chi tính từ query. | `Budget`, `remainingAmount`, `usagePercent`, `isExceeded` |
| `lib/models/loan.dart` | Khoản vay/cho vay, số tiền còn lại, lãi suất, ngày hạn, trạng thái, linked account/transaction. | `Loan`, `paidPercentage`, `isOverdue`, `isPaid` |
| `lib/models/loan_payment.dart` | Lịch sử thanh toán/thu nợ cho loan. | `LoanPayment`, `fromMap`, `toMap`, `copyWith` |

### Database và DAO

| File | Chức năng / nhiệm vụ | Hàm/class quan trọng |
| --- | --- | --- |
| `lib/database/database_helper.dart` | Singleton SQLite, tạo schema/index, migration skeleton, seed default categories/account. | `DatabaseHelper`, `_createAllTables`, `_createIndexes`, `_migratePreservingData`, `seedDefaultCategories`, `seedDefaultAccount`, `getDatabasePath` |
| `lib/database/user_dao.dart` | CRUD/query user local theo id, phone, email, Firebase UID; cập nhật password hash local. | `insert`, `findByPhone`, `findByEmail`, `findByFirebaseUid`, `findById`, `updatePassword` |
| `lib/database/account_dao.dart` | CRUD tài khoản, soft-delete, update/set balance, tính tổng số dư. | `getAllByUser`, `findById`, `softDelete`, `updateBalance`, `setBalance`, `getTotalBalance` |
| `lib/database/category_dao.dart` | CRUD hạng mục, filter income/expense, soft-delete hạng mục. | `getAllByUser`, `findById`, `getExpenseCategories`, `getIncomeCategories`, `softDelete` |
| `lib/database/transaction_dao.dart` | CRUD giao dịch kèm cập nhật số dư atomic; query danh sách và aggregation báo cáo. | `insertWithBalance`, `updateWithBalance`, `deleteWithBalance`, `getByUser`, `dailyTotals`, `monthlyTotals`, `hourlyTotals`, `expenseByCategory`, `incomeByAccount` |
| `lib/database/budget_dao.dart` | CRUD ngân sách; tính `spent_amount` bằng subquery từ transactions theo period. | `getAllByUser`, `findById`, `insert`, `update`, `delete` |
| `lib/database/loan_dao.dart` | CRUD loan, gắn transaction id, ghi nhận payment, tính summary borrowed/lent. | `getAllByUser`, `findByIdForUser`, `updateTransactionId`, `recordPayment`, `getPaymentHistory`, `getSummary`, `deleteForUser` |
| `lib/database/loan_payment_dao.dart` | DAO riêng cho bảng `loan_payments`; một phần workflow payment hiện nằm trong `LoanDao`. | `getByLoanId`, `deleteByLoanId`, `getTotalPaid` |

### Services và providers

| File | Chức năng / nhiệm vụ | Hàm/class quan trọng |
| --- | --- | --- |
| `lib/services/auth/auth_service.dart` | Contract auth cho provider/UI; enum provider và result wrapper. | `AuthService`, `AuthResult`, `AuthIdentifier`, `AppAuthProvider` |
| `lib/services/auth/firebase_auth_service.dart` | Firebase Auth implementation: email/password, phone OTP, Google, reset password, sync user local SQLite, seed dữ liệu mặc định. | `registerWithPhone`, `registerWithEmail`, `loginWithIdentifier`, `loginWithGoogle`, `requestPhoneOtp`, `checkAccountProvider`, `resetPasswordByPhone`, `_syncLocalUserAfterFirebaseLogin` |
| `lib/providers/auth_provider.dart` | State đăng nhập, onboarding, session SharedPreferences, profile, forgot password orchestration. | `init`, `completeOnboarding`, `login`, `loginWithGoogle`, `registerWithEmail`, `confirmPhoneRegistration`, `resetPasswordByPhoneFirebase`, `logout` |
| `lib/providers/account_provider.dart` | State danh sách tài khoản và tổng số dư. | `loadAccounts`, `addAccount`, `updateAccount`, `deleteAccount`, `adjustBalance` |
| `lib/providers/category_provider.dart` | State hạng mục income/expense. | `loadCategories`, `addCategory`, `updateCategory`, `deleteCategory` |
| `lib/providers/transaction_provider.dart` | State danh sách giao dịch, filter/search, CRUD giao dịch. | `loadTransactions`, `addTransaction`, `addTransactionAndReturnId`, `updateTransaction`, `deleteTransaction`, `groupedByDate` |
| `lib/providers/budget_provider.dart` | State ngân sách và selectors active/exceeded. | `loadBudgets`, `addBudget`, `updateBudget`, `deleteBudget`, `activeBudgets`, `exceededBudgets` |
| `lib/providers/loan_provider.dart` | State vay/cho vay, tạo loan kèm transaction, ghi nhận payment, summary. | `loadLoans`, `addLoan`, `recordPayment`, `getPaymentHistory`, `deleteLoan` |
| `lib/providers/report_provider.dart` | Tổng hợp dữ liệu báo cáo từ `TransactionDao`. | `loadReport`, `loadYearlyReport`, getters `totalIncome`, `totalExpense`, `dailyExpense`, `hourlyIncome`, `monthlyExpense` |
| `lib/providers/settings_provider.dart` | Settings app-level lưu trong SharedPreferences. | `loadSettings`, `setShowBalance`, `setDailyReminder`, `setCurrency` |

### Screens

| File | Chức năng / nhiệm vụ | Hàm/class quan trọng |
| --- | --- | --- |
| `lib/screens/splash/splash_screen.dart` | Splash animation, gọi `AuthProvider.init`, route đến onboarding/home/login. | `SplashScreen`, `_initAndNavigate` |
| `lib/screens/onboarding/onboarding_screen.dart` | Onboarding 3 trang, đánh dấu first launch đã hoàn tất. | `OnboardingScreen`, `_finish`, `_OnboardingPage` |
| `lib/screens/home/home_screen.dart` | Shell 5 tab: dashboard, accounts, add transaction FAB, reports, more. Load dữ liệu chung sau khi vào Home. | `HomeScreen`, `_loadData`, `_onTabTapped`, `_buildNavItem` |
| `lib/screens/dashboard/dashboard_screen.dart` | Tổng quan số dư, thu/chi tháng, giao dịch gần đây. | `DashboardScreen`, `_loadRecent`, `_calculateMonthlyAmount`, `_buildTransactionTile` |
| `lib/screens/auth/login_screen.dart` | Đăng nhập bằng email/phone + password, Google, link quên mật khẩu/đăng ký. | `LoginScreen`, `_login`, `_loginWithGoogle` |
| `lib/screens/auth/register_screen.dart` | Đăng ký bằng phone + OTP, toggle sang email, Google. | `RegisterScreen`, `_register`, `_openOtpVerification`, `_loginWithGoogle` |
| `lib/screens/auth/register_email_screen.dart` | Đăng ký email/password, toggle sang phone, Google. | `RegisterEmailScreen`, `_register`, `_loginWithGoogle` |
| `lib/screens/auth/otp_verification_screen.dart` | UI nhập OTP 6 số cho đăng ký phone. | `OtpVerificationScreen`, `_submit`, `_resend`, `_buildOtpField` |
| `lib/screens/auth/forgot_password_screen.dart` | State machine quên mật khẩu: identifier -> OTP -> new password; email gửi reset mail, phone gọi Cloud Function. | `_ForgotStep`, `_handleIdentifierSubmit`, `_handleEmailBranch`, `_handlePhoneBranch`, `_handleResetPassword` |
| `lib/screens/accounts/account_list_screen.dart` | Danh sách tài khoản và tổng tài sản. | `AccountListScreen` |
| `lib/screens/accounts/account_detail_screen.dart` | Chi tiết tài khoản, edit/delete. | `AccountDetailScreen`, `_confirmDelete` |
| `lib/screens/accounts/add_edit_account_screen.dart` | Thêm/sửa tài khoản, loại account, include in total. | `AddEditAccountScreen`, `_save` |
| `lib/screens/transactions/transaction_list_screen.dart` | Danh sách giao dịch theo ngày tương đối, search, filter chip UI. | `TransactionListScreen`, `_buildTxnTile`, `_filterChip` |
| `lib/screens/transactions/add_transaction_screen.dart` | Thêm/sửa/xóa giao dịch; tab chi/thu/chuyển khoản; chọn hạng mục, account, ngày/giờ. | `AddTransactionScreen`, `_save`, `_executeSave`, `_delete`, `CurrencyInputFormatter` |
| `lib/screens/categories/category_list_screen.dart` | Quản lý hạng mục theo tab chi tiêu/thu nhập, hiện parent-child, khóa default category. | `CategoryListScreen`, `_buildList` |
| `lib/screens/categories/add_edit_category_screen.dart` | Thêm/sửa hạng mục, chọn type, parent và icon. | `AddEditCategoryScreen`, `_save`, `_typeChip` |
| `lib/screens/budgets/budget_list_screen.dart` | Danh sách ngân sách, progress đã chi, trạng thái vượt mức. | `BudgetListScreen` |
| `lib/screens/budgets/add_edit_budget_screen.dart` | Thêm ngân sách, chọn chu kỳ và hạng mục expense. | `AddEditBudgetScreen`, `_save` |
| `lib/screens/loans/loan_list_screen.dart` | Danh sách vay/cho vay, summary đang vay/cho vay, progress. | `LoanListScreen`, `_refresh`, `_openAddLoan`, `_openLoanDetail` |
| `lib/screens/loans/add_edit_loan_screen.dart` | Thêm khoản vay/cho vay, linked account, lãi suất, ngày bắt đầu/hạn trả. | `AddEditLoanScreen`, `_save`, `_typeChip` |
| `lib/screens/loans/loan_detail_screen.dart` | Chi tiết loan, lịch sử thanh toán, delete, mở payment. | `LoanDetailScreen`, `_loadPayments`, `_openPayment`, `_confirmDelete` |
| `lib/screens/loans/payment_screen.dart` | Ghi nhận thanh toán/thu nợ cho loan. | `PaymentScreen`, `_submit` |
| `lib/screens/reports/report_screen.dart` | Hub báo cáo với preview: tài chính hiện tại, thu chi, phân tích thu/chi, loan tracking. | `ReportScreen`, `_loadPreviewData`, `_buildMenuCard` |
| `lib/screens/reports/current_finance_screen.dart` | Tổng quan tài sản ròng, tài khoản, nợ, cho vay; hiện có dòng `Tổng nợ` và `Tổng cho vay`, không còn card tổng hợp 4 ô cuối. | `CurrentFinanceScreen`, `_refreshData`, `_buildCard` |
| `lib/screens/reports/income_expense_screen.dart` | Báo cáo thu/chi theo ngày/tháng/năm, summary và breakdown category. | `IncomeExpenseScreen`, `_loadData`, `_buildSummaryCard`, `_buildBreakdownRow` |
| `lib/screens/reports/expense_analysis_screen.dart` | Phân tích chi tiêu bằng line chart theo ngày/tháng/năm; tooltip VND nền trắng chữ đỏ, trục Y có đơn vị riêng, trục X bỏ nhãn; tap drill-down năm -> tháng -> ngày. | `ExpenseAnalysisScreen`, `_loadData`, `_onDetailTap`, `_buildHourlyChart`, `_buildChart`, `_buildLineTouchData`, `_buildTopUnitTitle` |
| `lib/screens/reports/income_analysis_screen.dart` | Phân tích thu nhập tương tự expense analysis, dùng màu thu nhập. | `IncomeAnalysisScreen`, `_loadData`, `_onDetailTap`, `_buildHourlyChart`, `_buildChart`, `_buildLineTouchData`, `_buildTopUnitTitle` |
| `lib/screens/reports/loan_tracking_screen.dart` | Báo cáo vay nợ theo 2 tab cho vay/còn nợ, summary progress và danh sách loan. | `LoanTrackingScreen`, `_buildTabContent`, `_buildLoanCard` |
| `lib/screens/settings/more_screen.dart` | Tab "Khác": profile, quản lý hạng mục/vay/ngân sách, settings, backup, feedback, logout. | `MoreScreen`, `_menuItem`, `_push` |
| `lib/screens/settings/general_settings_screen.dart` | Settings hiện số dư, nhắc nhở, tiền tệ, thông tin version. | `GeneralSettingsScreen`, `_settingsCard`, `_sectionTitle` |
| `lib/screens/settings/data_settings_screen.dart` | UI backup/restore/delete all data, hiện tại mới hiển thị SnackBar "tính năng đang phát triển". | `DataSettingsScreen`, `_showComingSoon` |
| `lib/screens/settings/feedback_screen.dart` | Form góp ý, insert trực tiếp vào bảng `feedbacks`. | `FeedbackScreen`, `_submit` |

### Utils

| File | Chức năng / nhiệm vụ | Hàm/class quan trọng |
| --- | --- | --- |
| `lib/utils/constants.dart` | App metadata, DB version, validation limits, prefs keys, account/transaction/loan/budget/feedback labels. | `AppConstants` |
| `lib/utils/formatters.dart` | Format tiền VND, nhãn `VNĐ`, ngày giờ, percent, compact currency. | `Formatters.currency`, `currencyVnd`, `signedCurrency`, `date`, `time`, `relativeDate` |
| `lib/utils/validators.dart` | Validator form cho phone/email/password/name/amount/date/interest. | `Validators.emailOrPhoneVN`, `amount`, `parseAmount`, `interestRate` |
| `lib/utils/security_utils.dart` | Generate salt, hash/verify password, sanitize input. | `generateSalt`, `hashPassword`, `verifyPassword`, `sanitise` |
| `lib/utils/phone_utils.dart` | Validate/normalize số điện thoại Việt Nam, chuyển phone sang synthetic email. | `normaliseVnPhone`, `phoneToSyntheticEmail` |
| `lib/utils/category_icons.dart` | Map icon key trong DB sang Material icon và màu. | `CategoryIcons.getIcon`, `getColor`, icon key lists |

### Firebase Cloud Functions

| File | Chức năng / nhiệm vụ | Hàm/class quan trọng |
| --- | --- | --- |
| `functions/index.js` | Callable function `resetPasswordByPhone`; yêu cầu client đã auth bằng phone OTP, lấy `phone_number` từ token, map sang synthetic email và update password Firebase user. | `exports.resetPasswordByPhone`, `phoneToSyntheticEmail` logic inline |
| `functions/package.json` | Scripts local/deploy/logs và dependencies Cloud Functions. | `serve`, `shell`, `deploy`, `logs` |

## 4. Luồng hoạt động chính

### 4.1 Luồng khởi động app

```text
lib/main.dart
  -> WidgetsFlutterBinding.ensureInitialized()
  -> Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)
  -> GoogleSignIn.instance.initialize()
  -> SystemChrome.setPreferredOrientations(portrait)
  -> initializeDateFormatting('vi_VN')
  -> Debug: DatabaseHelper.instance.database + DriftDebugServer.start()
  -> runApp(MultiProvider(...))
  -> CoinNestApp
  -> SplashScreen
```

`SplashScreen._initAndNavigate()` gọi `AuthProvider.init()`:

```text
AuthProvider.init()
  -> SharedPreferences: is_first_launch, logged_in_user_id
  -> AuthService.findLocalUserById(userId)
  -> UserDao.findById()
  -> route:
       isFirstLaunch == true  -> OnboardingScreen
       isLoggedIn == true     -> HomeScreen
       else                   -> LoginScreen
```

### 4.2 Luồng xác thực

Đăng ký email:

```text
RegisterEmailScreen._register()
  -> AuthProvider.registerWithEmail()
  -> FirebaseAuthService.registerWithEmail()
  -> FirebaseAuth.createUserWithEmailAndPassword()
  -> UserDao.insert()
  -> DatabaseHelper.seedDefaultCategories()
  -> DatabaseHelper.seedDefaultAccount()
  -> AuthProvider._persistSession(logged_in_user_id)
  -> HomeScreen
```

Đăng ký phone:

```text
RegisterScreen._register()
  -> AuthProvider.requestPhoneRegistrationOtp()
  -> FirebaseAuth.verifyPhoneNumber()
  -> OtpVerificationScreen
  -> AuthProvider.confirmPhoneRegistration()
  -> FirebaseAuthService.registerWithPhone()
       -> confirmPhoneOtp()
       -> signInWithCredential(phone) tạm thời
       -> delete temporary phone-auth user best effort
       -> createUserWithEmailAndPassword(synthetic phone email)
       -> UserDao.insert()
       -> seed default categories/account
       -> persist session
```

Đăng nhập email/phone:

```text
LoginScreen._login()
  -> AuthProvider.login(identifier, password)
  -> FirebaseAuthService.loginWithIdentifier()
       -> nếu email: signInWithEmailAndPassword(email)
       -> nếu phone: normalize + phoneToSyntheticEmail()
  -> _syncLocalUserAfterFirebaseLogin()
       -> find by firebase_uid
       -> fallback by phone/email
       -> insert local user nếu cần
  -> persist session
  -> HomeScreen
```

Google Sign-In:

```text
Login/Register screen
  -> AuthProvider.loginWithGoogle()
  -> GoogleSignIn.instance.authenticate()
  -> FirebaseAuth.signInWithCredential(GoogleAuthProvider)
  -> _syncLocalUserAfterFirebaseLogin(provider=google)
  -> persist session
```

Quên mật khẩu:

```text
ForgotPasswordScreen
  -> email branch:
       checkAccountProvider(email)
       -> password provider: FirebaseAuth.sendPasswordResetEmail()
       -> google provider: hướng dẫn đăng nhập bằng Google
  -> phone branch:
       normalize phone -> synthetic email -> checkAccountProvider()
       -> FirebaseAuth.verifyPhoneNumber()
       -> nhập OTP + password mới
       -> resetPasswordByPhoneFirebase()
       -> FirebaseAuth.signInWithCredential(phone)
       -> Cloud Function resetPasswordByPhone(newPassword)
       -> Firebase Admin updateUser(password) + revokeRefreshTokens()
```

### 4.3 Luồng dữ liệu sau khi vào Home

```text
HomeScreen._loadData()
  -> AccountProvider.loadAccounts()
      -> AccountDao.getAllByUser()
      -> AccountDao.getTotalBalance()
  -> TransactionProvider.loadTransactions()
      -> TransactionDao.getByUser()
  -> CategoryProvider.loadCategories()
      -> CategoryDao.getExpenseCategories()
      -> CategoryDao.getIncomeCategories()
  -> ReportProvider.loadReport()
      -> TransactionDao aggregation queries
```

### 4.4 Luồng thêm/sửa/xóa giao dịch

```text
AddTransactionScreen
  -> TransactionProvider.addTransaction/updateTransaction/deleteTransaction
  -> TransactionDao.insertWithBalance/updateWithBalance/deleteWithBalance
  -> SQLite transaction:
       insert/update/delete transactions
       update accounts.balance theo type
```

Quy tắc số dư hiện tại trong `TransactionDao`:

- `income`: cộng vào account nguồn.
- `expense`: trừ khỏi account nguồn.
- `transfer`: trừ source, cộng destination.
- `loan` (đi vay): cộng vào account linked.
- `lend` (cho vay): trừ khỏi account linked.
- `balance_adjust`: schema/model có hỗ trợ type, nhưng DAO hiện không xử lý như workflow đầy đủ trong `insertWithBalance`.

### 4.5 Luồng vay/cho vay

Thêm loan:

```text
AddEditLoanScreen._save()
  -> LoanProvider.addLoan()
  -> LoanDao.insert(loans)
  -> TransactionProvider.addTransactionAndReturnId(type: loan/lend)
  -> LoanDao.updateTransactionId()
  -> TransactionDao.updateLoanId()
  -> reload loans + transactions nội bộ
```

Ghi nhận payment:

```text
PaymentScreen._submit()
  -> LoanProvider.recordPayment()
  -> TransactionProvider.addTransactionAndReturnId(type: expense/income)
  -> LoanDao.recordPayment()
       -> validate amount/date/status
       -> insert loan_payments
       -> reduce loans.remaining_amount
       -> mark paid nếu remaining <= 0
```

Lưu ý kiến trúc: `LoanProvider` hiện tự khởi tạo `TransactionProvider` riêng, không dùng instance đang đăng ký trong `MultiProvider`. UI đang reload lại ở nhiều điểm để bù cho việc này.

### 4.6 Luồng báo cáo

```text
Report screens
  -> ReportProvider.loadReport(userId, from, to)
      -> TransactionDao.totalIncome/totalExpense
      -> expenseByCategory/incomeByCategory
      -> expenseByAccount/incomeByAccount
      -> dailyTotals/hourlyTotals

  -> ReportProvider.loadYearlyReport(userId, year)
      -> TransactionDao.monthlyTotals(type: income/expense)
```

`ExpenseAnalysisScreen` và `IncomeAnalysisScreen` dùng `fl_chart` để vẽ line chart:

- Tab ngày: dữ liệu theo giờ từ `hourlyTotals`, tooltip hiển thị số tiền `VNĐ` và giờ `HH:00`.
- Tab tháng: dữ liệu theo ngày từ `dailyTotals`, tooltip hiển thị số tiền `VNĐ` và ngày `dd/MM/yyyy`.
- Tab năm: dữ liệu theo tháng từ `monthlyTotals`, tooltip hiển thị số tiền `VNĐ` và tháng/năm.
- Trục X không hiển thị nhãn ngày/tháng/giờ.
- Trục Y hiển thị đơn vị riêng ở phía trên, ví dụ `(Đơn vị: triệu)`, tick dạng số thập phân như `0.0`, `1.5`.

## 5. Đánh giá hiện trạng & Gợi ý bước tiếp theo

### Đã tương đối hoàn thiện

- App shell Flutter, theme, splash, onboarding, bottom navigation.
- Firebase Auth cho email/password, phone OTP và Google Sign-In.
- Cloud Function reset password bằng phone có Firebase Admin update password.
- SQLite schema version 3 với các bảng nghiệp vụ chính và index cơ bản.
- CRUD local cho account, category, transaction, budget, loan/payment.
- Cập nhật số dư account atomic khi thêm/sửa/xóa giao dịch.
- Màn hình tài khoản, giao dịch, hạng mục, ngân sách, vay/cho vay và chi tiết loan.
- Báo cáo thu/chi, phân tích thu/chi bằng chart, tài chính hiện tại, theo dõi loan.
- Tooltip chart phân tích thu/chi đã được chuẩn hóa theo VND, ngày/giờ/tháng và màu semantic.
- Settings có lưu `show_balance`, `daily_reminder`, `currency` vào SharedPreferences.
- Feedback form insert dữ liệu vào bảng `feedbacks`.

### Còn dang dở / boilerplate / cần cảnh giác

- `README.md`, `web/index.html`, `web/manifest.json` vẫn còn nội dung Flutter boilerplate.
- Chưa có thư mục `test/`; chưa có unit/widget/integration tests.
- `DataSettingsScreen` cho backup/restore/delete all data mới là UI và SnackBar "tính năng đang phát triển".
- Firebase runtime trong `lib/firebase_options.dart` hiện chỉ trả config Android, dù `firebase.json` có khai báo app id cho iOS/macOS/web/windows.
- `firebase_storage`, `flutter_secure_storage`, `uuid` đang khai báo dependency nhưng chưa thấy sử dụng trong `lib/`.
- `SettingsProvider.showBalance`, `dailyReminder`, `currency` đã lưu prefs nhưng chưa được áp dụng đầy đủ vào toàn bộ UI/notification/currency formatting.
- Dữ liệu tài chính chỉ nằm trong SQLite local, chưa có cloud sync theo tài khoản Firebase.
- Nhiều provider đang `catch (_) {}` hoặc trả `false` không log rõ lỗi, gây khó debug.
- Xóa loan hiện chỉ xóa record `loans`; transaction gốc/payment liên quan cần được xác định lại về nghiệp vụ revert số dư hay giữ lịch sử.
- `interestRate` và `interestCalculated` đã có trong schema/model nhưng chưa có logic tính lãi tự động.
- Routing dùng `Navigator.push`/`MaterialPageRoute` rải rác trong screen, chưa có route module tập trung.
- `FeedbackScreen` ghi trực tiếp vào `DatabaseHelper.instance.database` thay vì DAO/provider riêng.
- `LoanProvider` tự tạo `TransactionProvider` nội bộ, chưa theo dependency injection như các provider khác.
- Android còn TODO về `applicationId` và release signing config.
- `functions/` chưa có `package-lock.json`, nên dependency Node không được khóa chính xác trong repo.

### Đề xuất 3-5 đầu việc kỹ thuật tiếp theo

1. **Bổ sung test cho nghiệp vụ lõi.**  
   Ưu tiên unit test DAO/provider cho transaction balance, transfer, update/delete transaction, add/payment/delete loan, budget spent amount và report aggregation.

2. **Chuẩn hóa workflow vay/cho vay.**  
   Quyết định khi xóa loan có xóa/revert transaction linked không; thêm logic tính lãi nếu `interestRate` là yêu cầu sản phẩm; refactor `LoanProvider` để nhận dependency/service thay vì tự tạo `TransactionProvider`.

3. **Hoàn thiện backup/restore/delete all data.**  
   Tạo service export/import JSON có `schemaVersion`, validate foreign keys, chạy trong SQLite transaction, rollback khi lỗi và có confirm destructive action rõ ràng.

4. **Hoàn thiện cấu hình platform và dependency.**  
   Chạy/cập nhật `flutterfire configure` cho các platform cần support hoặc khóa phạm vi Android; loại bỏ dependency chưa dùng hoặc wire đúng vào avatar/session/cloud asset.

5. **Củng cố kiến trúc app.**  
   Thêm route module tập trung, chuẩn hóa error handling/logging, đưa feedback/data settings vào DAO/provider, và xác định chiến lược sync nếu dữ liệu tài chính cần đi theo tài khoản Firebase thay vì chỉ local.
