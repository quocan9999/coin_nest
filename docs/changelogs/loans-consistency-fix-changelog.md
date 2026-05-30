# Changelog Sửa Tính Nhất Quán Loans

## 2026-05-24 01:31:53 +07:00 - Phase 1: SQLite migration/dbVersion

- Thay đổi chính: giữ nguyên schema SQLite và `AppConstants.dbVersion = 3` vì đợt này không thêm bảng/cột/index/ràng buộc mới.
- File/module ảnh hưởng: không có thay đổi schema.
- Verification: kiểm tra các thay đổi code không sửa `lib/utils/constants.dart` và không thêm migration.
- Commit message đề xuất: `chore(loans): giữ nguyên phiên bản sqlite cho đợt sửa consistency`

## 2026-05-24 01:31:53 +07:00 - Phase 2: Xóa loan/lend rollback đúng dữ liệu

- Thay đổi chính: thêm `LoanDao.deleteForUserWithRollback` để query loan và linked transactions trong một DB transaction, reverse số dư account, xóa linked transactions, xóa `loan_payments`, xóa loan.
- File/module ảnh hưởng: `lib/database/loan_dao.dart`, `lib/providers/loan_provider.dart`, `lib/screens/loans/loan_detail_screen.dart`.
- Verification: static check bằng `git diff --check`; đọc luồng xóa loan để xác nhận provider reload loans/transactions và màn detail reload accounts sau delete.
- Commit message đề xuất: `fix(loans): rollback số dư khi xóa khoản vay`

## 2026-05-24 01:31:53 +07:00 - Phase 3: Chặn sửa/xóa loan transaction ở màn transaction thường

- Thay đổi chính: `TransactionListScreen` điều hướng loan-linked transaction sang `LoanDetailScreen`; `AddTransactionScreen` hiện thông báo chặn edit/delete; `TransactionProvider` guard update/delete transaction có `loanId` hoặc type `loan/lend`.
- File/module ảnh hưởng: `lib/screens/transactions/transaction_list_screen.dart`, `lib/screens/transactions/add_transaction_screen.dart`, `lib/providers/transaction_provider.dart`, `lib/database/transaction_dao.dart`, `lib/models/transaction_model.dart`.
- Verification: static check bằng `git diff --check`; `rg` xác nhận các guard `isLoanLinked`, `findLoanForTransaction`, và provider delete/update đã được gắn.
- Commit message đề xuất: `fix(transactions): điều hướng giao dịch khoản vay sang chi tiết loan`

## 2026-05-24 01:31:53 +07:00 - Phase 4: Full edit loan/lend trong domain loans

- Thay đổi chính: `AddEditLoanScreen` hỗ trợ edit mode với `Loan?`; `LoanProvider.updateLoan` và `LoanDao.updateLoanWithTransactions` validate total paid/start date, update loan, transaction gốc, payment transactions, remaining/status trong DB transaction.
- File/module ảnh hưởng: `lib/screens/loans/add_edit_loan_screen.dart`, `lib/screens/loans/loan_detail_screen.dart`, `lib/providers/loan_provider.dart`, `lib/database/loan_dao.dart`.
- Verification: static check bằng `git diff --check`; đọc lại luồng edit amount/account/type và payment transaction update balance qua `_updateTransactionWithBalance`.
- Commit message đề xuất: `feat(loans): hỗ trợ chỉnh sửa đầy đủ khoản vay`

## 2026-05-24 01:31:53 +07:00 - Phase 5: Sửa dấu tiền loan/lend trong transaction list

- Thay đổi chính: `TransactionModel.isNegative` đổi sang negative cho `expense/lend`, positive cho `income/loan`; transaction list dùng `signedAmount` và sign/color theo `isNegative`.
- File/module ảnh hưởng: `lib/models/transaction_model.dart`, `lib/screens/transactions/transaction_list_screen.dart`.
- Verification: static check bằng `git diff --check`; đọc lại daily total fold bằng `signedAmount`.
- Commit message đề xuất: `fix(transactions): hiển thị đúng dấu tiền vay và cho vay`

## 2026-05-24 01:31:53 +07:00 - Phase 6: Inject provider đúng instance

- Thay đổi chính: bỏ `LoanProvider` tự tạo `TransactionProvider`; gắn `LoanProvider` bằng `ChangeNotifierProxyProvider<TransactionProvider, LoanProvider>` trong `MultiProvider`; loan operations reload đúng transaction provider instance UI đang watch.
- File/module ảnh hưởng: `lib/main.dart`, `lib/providers/loan_provider.dart`.
- Verification: static check bằng `git diff --check`; `rg` xác nhận không còn `_txnProvider` và có `ChangeNotifierProxyProvider`.
- Commit message đề xuất: `fix(loans): dùng đúng instance transaction provider`

## 2026-05-24 01:31:53 +07:00 - Phase 7: Gắn category cho loan/payment transactions

- Thay đổi chính: thêm helper `CategoryDao.findDefaultCategoryId`; transaction gốc và payment transaction tìm category mặc định theo user/type/name, fallback `null` nếu thiếu; report DAO tính breakdown income gồm `income/loan`, expense gồm `expense/lend`.
- File/module ảnh hưởng: `lib/database/category_dao.dart`, `lib/providers/loan_provider.dart`, `lib/database/loan_dao.dart`, `lib/database/transaction_dao.dart`.
- Verification: static check bằng `git diff --check`; đọc lại mapping `Vay mượn`, `Cho mượn`, `Trả nợ`, `Thu nợ`.
- Commit message đề xuất: `fix(loans): gắn category mặc định cho giao dịch khoản vay`

## 2026-05-24 01:31:53 +07:00 - Phase 8: Lãi suất chỉ là metadata

- Thay đổi chính: giữ `interestRate` và `interestCalculated` là metadata; thêm note trong `AddEditLoanScreen` rằng app chưa tự tính/cộng lãi vào dư nợ.
- File/module ảnh hưởng: `lib/screens/loans/add_edit_loan_screen.dart`, `lib/database/loan_dao.dart`.
- Verification: static check bằng `git diff --check`; đọc code xác nhận không tạo transaction lãi và không cộng lãi vào `remainingAmount`.
- Commit message đề xuất: `fix(loans): ghi rõ lãi suất chỉ là metadata`

## 2026-05-24 02:13:12 +07:00 - Bổ sung: Mở chi tiết loan từ Tổng quan

- Thay đổi chính: recent transaction ở màn Tổng quan mở thẳng `LoanDetailScreen` khi transaction có `loanId` hoặc type `loan/lend`; bỏ màn card chặn "Giao dịch khoản vay" khỏi luồng hiển thị thường.
- File/module ảnh hưởng: `lib/screens/dashboard/dashboard_screen.dart`, `lib/screens/transactions/add_transaction_screen.dart`.
- Verification: static check bằng `git diff --check`; `rg` xác nhận không còn title/card "Giao dịch khoản vay" cũ và dashboard đã dùng `_openTransaction`.
- Commit message đề xuất: `fix(dashboard): mở chi tiết khoản vay từ giao dịch gần đây`
