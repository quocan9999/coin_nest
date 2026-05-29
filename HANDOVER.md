# CoinNest - Handover Document

Ngày tạo: 29/05/2026  
Phạm vi quét: toàn bộ workspace `coin_nest`

## 1. Tổng quan & Công nghệ sử dụng

### Mục đích dự án

CoinNest là ứng dụng Flutter quản lý tài chính cá nhân. Ứng dụng tập trung vào các nghiệp vụ:

- Đăng ký/đăng nhập bằng email, số điện thoại OTP và Google Sign-In qua Firebase Auth.
- Quản lý tài khoản tiền: tiền mặt, ngân hàng, ví điện tử, tiết kiệm, thẻ tín dụng.
- Ghi nhận giao dịch thu, chi, chuyển khoản.
- Quản lý hạng mục thu/chi, gồm cả hạng mục cha/con.
- Lập hạn mức chi tiêu và tính mức đã chi trong kỳ.
- Theo dõi vay/cho vay, ghi nhận thanh toán/thu nợ.
- Báo cáo tài chính hiện tại, thu chi, phân tích thu/chi theo ngày/tháng/năm.
- Lưu dữ liệu nghiệp vụ chính trong SQLite cục bộ; Firebase hiện chủ yếu đóng vai trò xác thực danh tính.

### Công nghệ và thư viện

| Nhóm | Công nghệ / thư viện | Phiên bản / ghi chú |
| --- | --- | --- |
| Ngôn ngữ | Dart | SDK constraint `^3.10.8` trong `pubspec.yaml` |
| Framework app | Flutter | Cross-platform; UI dùng Material 3 |
| State management | `provider` | `^6.1.5`, các provider kế thừa `ChangeNotifier` |
| Local database | SQLite qua `sqflite` | `^2.4.2`; DB file `coinnest.db`, schema version `3` |
| File/path DB | `path_provider`, `path` | `^2.1.5`, `^1.9.1` |
| Firebase core | `firebase_core` | `^4.7.0` |
| Firebase Auth | `firebase_auth` | `^6.4.0` |
| Google Sign-In | `google_sign_in` | `^7.2.0` |
| Cloud Functions client | `cloud_functions` | `^6.2.0` |
| Firebase Storage | `firebase_storage` | `^13.3.0`; đang khai báo nhưng chưa thấy code sử dụng |
| Biểu đồ | `fl_chart` | `^0.70.2`, dùng trong màn hình phân tích thu/chi |
| I18n/format | `intl` | `^0.19.0`, định dạng tiền/ngày tháng `vi_VN` |
| Font | `google_fonts` | `^6.2.1`, theme dùng Be Vietnam Pro |
| Local prefs | `shared_preferences` | `^2.3.4`, lưu session, onboarding và settings |
| Secure storage | `flutter_secure_storage` | `^9.2.4`; đang khai báo nhưng chưa thấy code sử dụng |
| Crypto | `crypto` | `^3.0.6`, hash mật khẩu cục bộ bằng SHA-256 + salt |
| UUID | `uuid` | `^4.5.1`; đang khai báo nhưng chưa thấy code sử dụng |
| SQLite debug | `saropa_drift_advisor` | `^3.5.1`, start debug viewer ở `http://localhost:8642` khi `kDebugMode` |
| Lint | `flutter_lints` | `^6.0.0`, `analysis_options.yaml` include `package:flutter_lints/flutter.yaml` |
| Cloud Functions runtime | Node.js | `18` trong `functions/package.json` |
| Cloud Functions libs | `firebase-admin`, `firebase-functions` | `^12.0.0`, `^5.0.0` |
| Android build | Android Gradle Plugin, Kotlin, Gradle | AGP `8.11.1`, Kotlin `2.2.20`, Gradle `8.14`, Java 17 |
| Android Firebase BOM | Firebase BOM | `34.12.0` trong `android/app/build.gradle.kts` |

Ghi chú: `flutter analyze` đã chạy thành công tại thời điểm tạo tài liệu, kết quả `No issues found`.

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
|   |-- models/
|   |-- providers/
|   |-- screens/
|   |-- services/
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

### Chức năng các thư mục chính

| Thư mục / file | Vai trò |
| --- | --- |
| `lib/` | Mã nguồn Flutter/Dart chính của ứng dụng. |
| `lib/main.dart` | Bootstrap app, init Firebase/Google Sign-In/locale, đăng ký Provider. |
| `lib/app.dart` | Root `MaterialApp`, gắn theme và màn hình đầu tiên. |
| `lib/database/` | SQLite helper và DAO cho các bảng nghiệp vụ. |
| `lib/models/` | Entity/data model plain Dart, map qua/lại SQLite row. |
| `lib/providers/` | Lớp state và async orchestration theo feature, dùng `ChangeNotifier`. |
| `lib/screens/` | UI screen theo từng feature: auth, dashboard, accounts, transactions, reports, settings. |
| `lib/services/` | Tích hợp ngoài hệ thống, hiện có auth service cho Firebase. |
| `lib/theme/` | Design tokens và `ThemeData`. |
| `lib/utils/` | Constants, validators, formatters, phone/security/icon helpers. |
| `functions/` | Firebase Cloud Functions Node.js, hiện có function reset mật khẩu bằng phone. |
| `android/` | Cấu hình Android native, Firebase Google Services, Gradle/Kotlin. |
| `ios/`, `macos/`, `linux/`, `windows/`, `web/` | Shell platform mặc định của Flutter. Firebase options hiện mới cấu hình runtime cho Android. |
| `DESIGN.md` | Design system: editorial finance, tonal layering, no-line UI. |
| `AGENTS.md`, `CLAUDE.md`, `lib/screens/CLAUDE.md` | Hướng dẫn coding, kiến trúc và UI cho contributor. |

## 3. Bản đồ chức năng của file

### Entrypoint, cấu hình và theme

| File | Chức năng chính | Class/hàm cần lưu ý |
| --- | --- | --- |
| `lib/main.dart` | Khởi tạo Flutter binding, Firebase, Google Sign-In, khóa portrait, locale `vi_VN`, start SQLite debug viewer trong debug, đăng ký `MultiProvider`. | `main()` |
| `lib/app.dart` | Root app, gắn title, theme và `SplashScreen`. | `CoinNestApp` |
| `lib/firebase_options.dart` | Firebase options generated/local; `currentPlatform` hiện chỉ trả về config Android, các platform khác throw `UnsupportedError`. | `DefaultFirebaseOptions.currentPlatform`, `android` |
| `lib/theme/app_theme.dart` | Design token màu, spacing, radius, `ThemeData`, text theme Be Vietnam Pro. | `AppTheme.lightTheme`, màu semantic, spacing/radius constants |
| `pubspec.yaml` | Khai báo package, version app `1.0.0+1`, Dart SDK, dependencies. | `dependencies`, `dev_dependencies` |
| `analysis_options.yaml` | Cấu hình lint. | include `flutter_lints` |
| `firebase.json` | Cấu hình Firebase Functions Node 18 và FlutterFire app ids. | `functions`, `flutter.platforms` |
| `android/app/build.gradle.kts` | Cấu hình Android app, google-services, Java 17, Firebase BOM, rename APK output. | `plugins`, `defaultConfig`, `applicationVariants` |
| `functions/package.json` | Package Cloud Functions, scripts emulator/deploy/logs. | scripts `serve`, `deploy`; engine Node 18 |

### Models

| File | Chức năng chính | Class/hàm cần lưu ý |
| --- | --- | --- |
| `lib/models/user.dart` | User local mapping với Firebase UID và auth provider. | `User`, `fromMap`, `toMap`, `copyWith` |
| `lib/models/account.dart` | Tài khoản tài chính, số dư, loại, currency, active/include flags. | `Account`, `fromMap`, `toMap`, `copyWith` |
| `lib/models/category.dart` | Hạng mục thu/chi, icon, màu, parent-child, default/active flags. | `Category`, `fromMap`, `toMap`, `copyWith` |
| `lib/models/transaction_model.dart` | Giao dịch thu/chi/chuyển khoản/vay/cho vay/điều chỉnh số dư, gồm joined fields từ DAO. | `TransactionModel`, `isNegative`, `signedAmount` |
| `lib/models/budget.dart` | Hạn mức chi, period, spent amount computed, category joined fields. | `Budget`, `remainingAmount`, `usagePercent`, `isExceeded` |
| `lib/models/loan.dart` | Khoản vay/cho vay, remaining, interest, due date, status, linked account/transaction. | `Loan`, `paidPercentage`, `isOverdue`, `isPaid` |
| `lib/models/loan_payment.dart` | Lịch sử thanh toán/thu nợ cho loan. | `LoanPayment`, `fromMap`, `toMap`, `copyWith` |

### Database và DAO

| File | Chức năng chính | Class/hàm cần lưu ý |
| --- | --- | --- |
| `lib/database/database_helper.dart` | Singleton SQLite, tạo schema, indexes, migration skeleton, seed default categories/account. | `DatabaseHelper`, `_createAllTables`, `_createIndexes`, `seedDefaultCategories`, `seedDefaultAccount`, `getDatabasePath` |
| `lib/database/user_dao.dart` | CRUD/query user local theo id, phone, email, Firebase UID; update local password hash. | `insert`, `findByPhone`, `findByEmail`, `findByFirebaseUid`, `updatePassword` |
| `lib/database/account_dao.dart` | CRUD tài khoản, soft-delete, update/set balance, tổng số dư. | `getAllByUser`, `softDelete`, `updateBalance`, `setBalance`, `getTotalBalance` |
| `lib/database/category_dao.dart` | CRUD hạng mục, filter income/expense, soft-delete hạng mục custom. | `getAllByUser`, `getExpenseCategories`, `getIncomeCategories`, `softDelete` |
| `lib/database/transaction_dao.dart` | CRUD giao dịch kèm cập nhật số dư atomic; query danh sách và aggregation cho báo cáo. | `insertWithBalance`, `updateWithBalance`, `deleteWithBalance`, `getByUser`, `totalIncome`, `totalExpense`, `dailyTotals`, `monthlyTotals`, `hourlyTotals`, `expenseByCategory`, `incomeByAccount` |
| `lib/database/budget_dao.dart` | CRUD hạn mức, tính `spent_amount` bằng subquery từ transactions theo period. | `getAllByUser`, `findById`, `insert`, `update`, `delete` |
| `lib/database/loan_dao.dart` | CRUD loan, gắn transaction id, ghi nhận payment trong transaction DB, summary borrowed/lent. | `getAllByUser`, `findByIdForUser`, `recordPayment`, `getPaymentHistory`, `getSummary` |
| `lib/database/loan_payment_dao.dart` | DAO riêng cho loan payments; một số logic payment hiện đang nằm trong `LoanDao`. | `getByLoanId`, `deleteByLoanId`, `getTotalPaid` |

Schema SQLite chính gồm các bảng: `users`, `accounts`, `categories`, `transactions`, `loans`, `loan_payments`, `budgets`, `feedbacks`.

### Services và providers

| File | Chức năng chính | Class/hàm cần lưu ý |
| --- | --- | --- |
| `lib/services/auth/auth_service.dart` | Contract auth trước UI/provider; enum provider và result wrapper. | `AuthService`, `AuthResult`, `AppAuthProvider` |
| `lib/services/auth/firebase_auth_service.dart` | Firebase Auth implementation: email/password, phone OTP, Google, reset password, sync user local SQLite, seed data. | `registerWithPhone`, `registerWithEmail`, `loginWithIdentifier`, `loginWithGoogle`, `requestPhoneOtp`, `checkAccountProvider`, `resetPasswordByPhone`, `_syncLocalUserAfterFirebaseLogin` |
| `lib/providers/auth_provider.dart` | State đăng nhập, onboarding, session SharedPreferences, profile, forgot password orchestration. | `init`, `completeOnboarding`, `login`, `loginWithGoogle`, `registerWithEmail`, `confirmPhoneRegistration`, `resetPasswordByPhoneFirebase`, `logout` |
| `lib/providers/account_provider.dart` | State danh sách tài khoản và tổng số dư. | `loadAccounts`, `addAccount`, `updateAccount`, `deleteAccount`, `adjustBalance` |
| `lib/providers/category_provider.dart` | State hạng mục income/expense. | `loadCategories`, `addCategory`, `updateCategory`, `deleteCategory` |
| `lib/providers/transaction_provider.dart` | State danh sách giao dịch, filter/search, CRUD giao dịch. | `loadTransactions`, `addTransactionAndReturnId`, `updateTransaction`, `deleteTransaction`, `groupedByDate` |
| `lib/providers/budget_provider.dart` | State hạn mức chi, active/exceeded selectors. | `loadBudgets`, `addBudget`, `updateBudget`, `deleteBudget` |
| `lib/providers/loan_provider.dart` | State vay/cho vay, tạo loan kèm transaction, payment, summary. | `loadLoans`, `addLoan`, `recordPayment`, `deleteLoan`, `getPaymentHistory` |
| `lib/providers/report_provider.dart` | Tổng hợp dữ liệu báo cáo từ `TransactionDao`. | `loadReport`, `loadYearlyReport`, getters `totalIncome`, `totalExpense`, `dailyExpense`, `monthlyIncome` |
| `lib/providers/settings_provider.dart` | Settings app-level lưu trong SharedPreferences. | `loadSettings`, `setShowBalance`, `setDailyReminder`, `setCurrency` |

### Screens

| File | Chức năng chính | Class/hàm cần lưu ý |
| --- | --- | --- |
| `lib/screens/splash/splash_screen.dart` | Splash animation, gọi `AuthProvider.init`, route đến onboarding/home/login. | `SplashScreen`, `_initAndNavigate` |
| `lib/screens/onboarding/onboarding_screen.dart` | Onboarding 3 trang, mark first launch complete. | `OnboardingScreen`, `_finish`, `_OnboardingPage` |
| `lib/screens/home/home_screen.dart` | Shell 5 tab: dashboard, accounts, add transaction FAB, reports, more. Load data chung sau khi vào Home. | `HomeScreen`, `_loadData`, `_onTabTapped` |
| `lib/screens/dashboard/dashboard_screen.dart` | Tổng quan số dư, thu/chi tháng, giao dịch gần đây. | `DashboardScreen`, `_loadRecent`, `_buildTransactionTile` |
| `lib/screens/auth/login_screen.dart` | Đăng nhập bằng email/phone + password, Google, link quên mật khẩu/đăng ký. | `LoginScreen`, `_login`, `_loginWithGoogle` |
| `lib/screens/auth/register_screen.dart` | Đăng ký bằng phone + OTP, toggle sang email, Google. | `RegisterScreen`, `_register`, `_openOtpVerification`, `_loginWithGoogle` |
| `lib/screens/auth/register_email_screen.dart` | Đăng ký email/password, toggle sang phone, Google. | `RegisterEmailScreen`, `_register`, `_loginWithGoogle` |
| `lib/screens/auth/otp_verification_screen.dart` | UI nhập OTP 6 số cho phone registration. | `OtpVerificationScreen`, `_submit`, `_resend`, `_buildOtpField` |
| `lib/screens/auth/forgot_password_screen.dart` | State machine quên mật khẩu: identifier -> OTP -> new password; email branch gửi Firebase reset email, phone branch gọi Cloud Function. | `_ForgotStep`, `_handleIdentifierSubmit`, `_handleEmailBranch`, `_handlePhoneBranch`, `_handleResetPassword` |
| `lib/screens/accounts/account_list_screen.dart` | Danh sách tài khoản và tổng tài sản. | `AccountListScreen` |
| `lib/screens/accounts/account_detail_screen.dart` | Chi tiết tài khoản, edit/delete. | `AccountDetailScreen`, `_confirmDelete` |
| `lib/screens/accounts/add_edit_account_screen.dart` | Thêm/sửa tài khoản, loại account, include in total. | `AddEditAccountScreen`, `_save` |
| `lib/screens/transactions/transaction_list_screen.dart` | Danh sách giao dịch theo ngày tương đối, search, filter chip UI. | `TransactionListScreen`, `_buildTxnTile`, `_filterChip` |
| `lib/screens/transactions/add_transaction_screen.dart` | Thêm/sửa/xóa giao dịch; tab chi/thu/chuyển khoản; chọn hạng mục, account, ngày. | `AddTransactionScreen`, `_save`, `_executeSave`, `_delete`, `CurrencyInputFormatter` |
| `lib/screens/categories/category_list_screen.dart` | Quản lý hạng mục theo tab chi tiêu/thu nhập, hiện parent-child, lock default category. | `CategoryListScreen`, `_buildList` |
| `lib/screens/categories/add_edit_category_screen.dart` | Thêm/sửa hạng mục, chọn type, parent và icon. | `AddEditCategoryScreen`, `_save`, `_typeChip` |
| `lib/screens/budgets/budget_list_screen.dart` | Danh sách hạn mức chi, progress đã chi, trạng thái vượt mức. | `BudgetListScreen` |
| `lib/screens/budgets/add_edit_budget_screen.dart` | Thêm hạn mức chi, chọn chu kỳ và hạng mục expense. | `AddEditBudgetScreen`, `_save` |
| `lib/screens/loans/loan_list_screen.dart` | Danh sách vay/cho vay, summary đang vay/cho vay, progress. | `LoanListScreen`, `_openAddLoan`, `_openLoanDetail` |
| `lib/screens/loans/add_edit_loan_screen.dart` | Thêm khoản vay/cho vay, linked account, lãi suất, ngày bắt đầu/hạn trả. | `AddEditLoanScreen`, `_save` |
| `lib/screens/loans/loan_detail_screen.dart` | Chi tiết loan, lịch sử thanh toán, delete, mở payment. | `LoanDetailScreen`, `_paymentHistory`, `_openPayment`, `_confirmDelete` |
| `lib/screens/loans/payment_screen.dart` | Ghi nhận thanh toán/thu nợ cho loan. | `PaymentScreen`, `_submit` |
| `lib/screens/reports/report_screen.dart` | Hub báo cáo với preview: tài chính hiện tại, thu chi, phân tích thu/chi, loan tracking. | `ReportScreen`, `_loadPreviewData`, `_buildMenuCard` |
| `lib/screens/reports/current_finance_screen.dart` | Tổng quan tài sản ròng, tài khoản, nợ, cho vay. | `CurrentFinanceScreen`, `_refreshData`, `_buildCard` |
| `lib/screens/reports/income_expense_screen.dart` | Báo cáo thu/chi theo ngày/tháng/năm, summary và breakdown category. | `IncomeExpenseScreen`, `_loadData`, `_buildSummaryCard`, `_buildBreakdownRow` |
| `lib/screens/reports/expense_analysis_screen.dart` | Phân tích chi tiêu bằng line chart theo ngày/tháng/năm; tap drill-down từ năm -> tháng -> ngày. | `ExpenseAnalysisScreen`, `_loadData`, `_onDetailTap`, `_buildHourlyChart`, `_buildChart` |
| `lib/screens/reports/income_analysis_screen.dart` | Phân tích thu nhập tương tự expense analysis nhưng dùng dữ liệu income. | `IncomeAnalysisScreen`, `_loadData`, `_onDetailTap`, `_buildHourlyChart`, `_buildChart` |
| `lib/screens/reports/loan_tracking_screen.dart` | Báo cáo vay nợ theo 2 tab cho vay/còn nợ, summary progress và danh sách loan. | `LoanTrackingScreen`, `_buildTabContent`, `_buildLoanCard` |
| `lib/screens/settings/more_screen.dart` | Tab "Khác": profile, quản lý hạng mục/vay/hạn mức, settings, backup, feedback, logout. | `MoreScreen`, `_menuItem`, `_push` |
| `lib/screens/settings/general_settings_screen.dart` | Settings hiện số dư, nhắc nhở, tiền tệ, thông tin version. | `GeneralSettingsScreen` |
| `lib/screens/settings/data_settings_screen.dart` | UI backup/restore/delete all data, hiện tại chỉ hiện SnackBar "tính năng đang phát triển". | `DataSettingsScreen`, `_showComingSoon` |
| `lib/screens/settings/feedback_screen.dart` | Form góp ý, insert trực tiếp vào bảng `feedbacks`. | `FeedbackScreen`, `_submit` |

### Utils

| File | Chức năng chính | Class/hàm cần lưu ý |
| --- | --- | --- |
| `lib/utils/constants.dart` | App metadata, DB version, validation limits, prefs keys, account/transaction/loan/budget labels. | `AppConstants` |
| `lib/utils/formatters.dart` | Format tiền VND, ngày giờ, percent, compact currency. | `Formatters.currency`, `signedCurrency`, `date`, `relativeDate` |
| `lib/utils/validators.dart` | Validator form cho phone/email/password/name/amount/date/interest. | `Validators.emailOrPhoneVN`, `amount`, `parseAmount`, `interestRate` |
| `lib/utils/security_utils.dart` | Generate salt, hash/verify password, sanitize input. | `generateSalt`, `hashPassword`, `verifyPassword`, `sanitise` |
| `lib/utils/phone_utils.dart` | Validate/normalize số điện thoại VN, chuyển phone sang synthetic email. | `normaliseVnPhone`, `phoneToSyntheticEmail` |
| `lib/utils/category_icons.dart` | Map icon key trong DB sang Material icon và màu. | `CategoryIcons.getIcon`, `getColor`, icon key lists |

### Firebase Cloud Functions

| File | Chức năng chính | Class/hàm cần lưu ý |
| --- | --- | --- |
| `functions/index.js` | Callable function `resetPasswordByPhone`; yêu cầu đã auth bằng phone OTP, lấy `phone_number` claim, map sang synthetic email và update password Firebase user. | `exports.resetPasswordByPhone`, `phoneToSyntheticEmail` |
| `functions/package.json` | Scripts local/deploy/logs và dependencies Cloud Functions. | `serve`, `deploy`, `firebase-admin`, `firebase-functions` |

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

### 4.2 Luồng đăng ký/đăng nhập

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
  -> FirebaseAuthService.confirmPhoneOtp()
       -> signInWithCredential(phone)
       -> delete temporary phone-auth user best effort
       -> signOut()
  -> FirebaseAuth.createUserWithEmailAndPassword(synthetic phone email)
  -> UserDao.insert()
  -> seed default categories/account
  -> persist session
```

Đăng nhập:

```text
LoginScreen._login()
  -> AuthProvider.login(identifier, password)
  -> FirebaseAuthService.loginWithIdentifier()
       -> email: sign in bằng email thật
       -> phone: normalize + phoneToSyntheticEmail()
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
       AuthProvider.checkAccountProvider(email)
       -> nếu password provider: FirebaseAuth.sendPasswordResetEmail()
       -> nếu google provider: hiện dialog hướng dẫn Google Sign-In
  -> phone branch:
       normalize phone -> synthetic email -> checkAccountProvider()
       -> FirebaseAuth.verifyPhoneNumber()
       -> nhập OTP + password mới
       -> AuthProvider.resetPasswordByPhoneFirebase()
       -> FirebaseAuth.signInWithCredential(phone)
       -> Cloud Function resetPasswordByPhone(newPassword)
       -> Firebase Admin updateUser(password) + revokeRefreshTokens()
```

### 4.3 Luồng dữ liệu nghiệp vụ sau khi vào Home

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

Quy tắc cập nhật số dư:

- `income`: cộng vào account source.
- `expense`: trừ khỏi account source.
- `transfer`: trừ source, cộng destination.
- `loan` (đi vay): cộng vào account linked.
- `lend` (cho vay): trừ khỏi account linked.
- `balance_adjust`: table có type nhưng logic DAO hiện chưa xử lý như một workflow UI riêng.

### 4.5 Luồng vay/cho vay

Thêm loan:

```text
AddEditLoanScreen._save()
  -> LoanProvider.addLoan()
  -> LoanDao.insert(loans)
  -> TransactionProvider.addTransactionAndReturnId(type: loan/lend)
  -> LoanDao.updateTransactionId()
  -> TransactionDao.updateLoanId()
  -> reload loans + transactions
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

`ExpenseAnalysisScreen` và `IncomeAnalysisScreen` dùng `fl_chart` để vẽ line chart, có drill-down:

```text
Năm -> tap tháng -> Màn hình tháng
Tháng -> tap ngày -> Màn hình ngày
Ngày -> hiện hourly chart
```

## 5. Đánh giá hiện trạng & Gợi ý bước tiếp theo

### Đã tương đối hoàn thiện

- App shell Flutter, theme, splash, onboarding, home bottom navigation.
- Firebase Auth integration cho email/password, phone OTP, Google Sign-In.
- Cloud Function reset password bằng phone có Firebase Admin update password.
- SQLite schema version 3 với các bảng chính và index cơ bản.
- CRUD local cho account, category, transaction, budget, loan/payment.
- Cập nhật số dư account atomic khi thêm/sửa/xóa giao dịch.
- Báo cáo thu/chi, phân tích thu/chi bằng chart, tài chính hiện tại, theo dõi loan.
- Settings có lưu `show_balance`, `daily_reminder`, `currency` vào SharedPreferences.
- Feedback form insert dữ liệu vào bảng `feedbacks`.
- `flutter analyze` hiện không có issue.

### Còn dang dở / boilerplate / cần cảnh giác

- `README.md`, `web/index.html`, `web/manifest.json` vẫn còn nội dung boilerplate "A new Flutter project".
- Chưa có thư mục `test/`; chưa có unit/widget/integration tests.
- `DataSettingsScreen` cho backup/restore/delete all data mới là UI và SnackBar "tính năng đang phát triển".
- Firebase runtime options hiện chỉ cấu hình Android trong `lib/firebase_options.dart`; iOS/macOS/web/windows sẽ throw `UnsupportedError` dù có shell platform.
- `firebase_storage`, `flutter_secure_storage`, `uuid` đang khai báo dependency nhưng chưa thấy import/sử dụng trong `lib/`.
- `SettingsProvider.showBalance`, `dailyReminder`, `currency` đã lưu prefs nhưng chưa được wire đầy đủ vào các màn hình/notification/currency formatting.
- Không có cloud sync cho dữ liệu tài chính; dữ liệu tài khoản/giao dịch/loan/budget chỉ nằm trong SQLite local theo thiết bị.
- Nhiều provider `catch (_) {}` hoặc return `false` không log/thông báo rõ, gây khó debug khi lỗi database/validation.
- Xóa loan hiện chỉ xóa record `loans`; transaction gốc liên quan đến loan vẫn có thể còn tồn tại với `loan_id` bị set null, nên cần xác định lại nghiệp vụ có cần revert số dư/xóa transaction linked hay không.
- `interestRate` và `interestCalculated` đã có trong model/schema nhưng chưa có logic tính lãi tự động.
- Local `password_hash/password_salt` vẫn được lưu để backward compatibility, nhưng flow login dùng Firebase; reset password qua phone cập nhật Firebase, không cập nhật hash local.
- Routing đang dùng `Navigator.push`/`MaterialPageRoute` rải rác trong screen, chưa có route module tập trung.
- `FeedbackScreen` ghi trực tiếp vào `DatabaseHelper.instance.database` thay vì thông qua DAO/provider riêng.
- `LoanProvider` tự khởi tạo `TransactionProvider` riêng thay vì nhận provider/service qua DI; sau thao tác loan cần chú ý reload provider UI đang đăng ký trong `MultiProvider`.

### 3-5 đầu việc kỹ thuật nên làm tiếp

1. **Bổ sung test cho luồng nghiệp vụ cốt lõi.**  
   Ưu tiên unit test DAO/provider cho transaction balance, transfer, update/delete transaction, add/payment/delete loan, budget spent amount và report aggregation.

2. **Làm rõ và sửa workflow loan.**  
   Quyết định nghiệp vụ khi xóa loan có xóa/revert transaction linked không; thêm logic tính lãi nếu `interestRate` là yêu cầu sản phẩm; tránh dùng `TransactionProvider` nội bộ trong `LoanProvider` bằng DI/service rõ ràng hơn.

3. **Hoàn thiện cấu hình platform và dependency.**  
   Chạy/cập nhật `flutterfire configure` cho các platform cần support hoặc khóa phạm vi Android; nếu chưa dùng `firebase_storage`, `flutter_secure_storage`, `uuid` thì bỏ khỏi dependency, nếu dùng thì wire vào avatar/session/cloud asset.

4. **Triển khai backup/restore/delete all data.**  
   Tạo service/DAO cho export/import JSON có `schemaVersion`, validate foreign keys, transaction rollback, và confirm destructive action rõ ràng.

5. **Củng cố kiến trúc ứng dụng.**  
   Thêm route module tập trung, chuẩn hóa error handling/logging, đưa feedback/data settings vào provider/service, và xây chiến lược sync nếu dữ liệu cần đi theo tài khoản Firebase thay vì chỉ nằm local.

