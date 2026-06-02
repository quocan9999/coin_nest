import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/category_icons.dart';
import '../loans/loan_detail_screen.dart';
import '../notifications/notification_center_screen.dart';
import 'add_transaction_screen.dart';
import '../../widgets/notification_badge_button.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});
  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final userId = context.read<AuthProvider>().currentUserId;
      final txnProv = context.read<TransactionProvider>();

      // --- VÁ LỖI: Trả toàn bộ bộ lọc về trạng thái ban đầu ---
      txnProv.clearFilters();
      _searchController.clear(); // Xóa chữ trong thanh tìm kiếm

      // Sau khi reset, mới tiến hành nạp danh sách giao dịch
      context.read<AccountProvider>().loadAccounts(userId);
      txnProv.loadTransactions(userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'expense':
        return 'Chi tiêu';
      case 'income':
        return 'Thu nhập';
      case 'transfer':
        return 'Chuyển khoản';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ lắng nghe sự thay đổi, logic nạp đã được cô lập trong initState
    final txnProv = context.watch<TransactionProvider>();
    final accountProv = context.watch<AccountProvider>();
    final theme = Theme.of(context);
    final colors = AppTheme.colors(context);
    final colorScheme = theme.colorScheme;

    final grouped = txnProv.groupedByDate;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'CoinNest',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          NotificationBadgeButton(
            onPressed: () => _openNotificationCenter(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (q) {
                txnProv.setSearchQuery(q);
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo ghi chú hoặc hạng mục...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: colors.input,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. BỘ LỌC THỜI GIAN & TÀI KHOẢN (Song song)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildTimeDropdown(context, txnProv)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAccountDropdown(context, txnProv, accountProv),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. DANH SÁCH GIAO DỊCH
          Expanded(
            child: txnProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : grouped.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          txnProv.searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.receipt_long_outlined,
                          size: 56,
                          color: colors.textDisabled,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          txnProv.searchQuery.isNotEmpty
                              ? 'Không tìm thấy kết quả phù hợp'
                              : 'Chưa có ghi chép nào',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: grouped.entries.map((entry) {
                      final total = entry.value.fold<double>(
                        0,
                        (sum, t) => sum + t.signedAmount,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                Formatters.signedCurrency(total),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: total >= 0
                                      ? colors.income
                                      : colors.expense,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map(
                            (txn) => _buildTxnTile(context, txn),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget Tùy chỉnh: Dropdown lọc Thời gian
  Widget _buildTimeDropdown(BuildContext context, TransactionProvider txnProv) {
    final colors = AppTheme.colors(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: txnProv.timeFilter,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  const DropdownMenuItem(
                    value: 'today',
                    child: Text('Hôm nay'),
                  ),
                  const DropdownMenuItem(
                    value: 'this_month',
                    child: Text('Tháng này'),
                  ),
                  const DropdownMenuItem(
                    value: 'last_month',
                    child: Text('Tháng trước'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text(
                      txnProv.timeFilter == 'custom' &&
                              txnProv.customDateRange != null
                          ? '${txnProv.customDateRange!.start.day}/${txnProv.customDateRange!.start.month} - ${txnProv.customDateRange!.end.day}/${txnProv.customDateRange!.end.month}'
                          : 'Tùy chọn...',
                    ),
                  ),
                ],
                onChanged: (val) async {
                  if (val == null) return;
                  final userId = context.read<AuthProvider>().currentUserId;

                  if (val == 'custom') {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppTheme.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      if (!context.mounted) return;
                      txnProv.setTimeFilter('custom', customRange: range);
                      txnProv.loadTransactions(userId);
                    }
                  } else {
                    txnProv.setTimeFilter(val);
                    txnProv.loadTransactions(userId);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Tùy chỉnh: Dropdown lọc Tài khoản
  Widget _buildAccountDropdown(
    BuildContext context,
    TransactionProvider txnProv,
    AccountProvider accProv,
  ) {
    final colors = AppTheme.colors(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.input,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 16,
            color: colors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: txnProv.filterAccountId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả ví', overflow: TextOverflow.ellipsis),
                  ),
                  ...accProv.accounts.map(
                    (a) => DropdownMenuItem<int?>(
                      value: a.id,
                      child: Text(a.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (val) {
                  final userId = context.read<AuthProvider>().currentUserId;
                  txnProv.setFilterAccount(val);
                  txnProv.loadTransactions(userId);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnTile(BuildContext context, TransactionModel txn) {
    final theme = Theme.of(context);
    final colors = AppTheme.colors(context);
    final color = txn.isNegative
        ? colors.expense
        : (txn.type == 'transfer' ? colors.transfer : colors.income);
    final sign = txn.isNegative
        ? '- '
        : (txn.type == 'transfer' || txn.type == 'balance_adjust' ? '' : '+ ');
    final iconKey = txn.categoryIconName ?? txn.type;

    final noteStr = (txn.note != null && txn.note!.toString().trim().isNotEmpty)
        ? '${txn.note} • '
        : '';

    return GestureDetector(
      onTap: () {
        _openTransaction(context, txn);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CategoryIcons.getColor(iconKey).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CategoryIcons.getIcon(iconKey),
                color: CategoryIcons.getColor(iconKey),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.categoryName ?? _getTypeLabel(txn.type),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$noteStr${txn.time ?? Formatters.time(txn.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${Formatters.currency(txn.amount)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (txn.accountName != null)
                  Text(
                    txn.accountName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTransaction(
    BuildContext context,
    TransactionModel txn,
  ) async {
    if (txn.isLoanLinked) {
      final userId = context.read<AuthProvider>().currentUserId;
      final loan = await context.read<LoanProvider>().findLoanForTransaction(
        userId: userId,
        loanId: txn.loanId,
        transactionId: txn.id,
      );
      if (!context.mounted) return;
      if (loan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không tìm thấy khoản vay liên kết với giao dịch này',
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
      );
      return;
    }

    final userId = context.read<AuthProvider>().currentUserId;
    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: txn),
      ),
    );
    if (!context.mounted) return;
    await accountProvider.loadAccounts(userId);
    await transactionProvider.loadTransactions(userId);
  }

  void _openNotificationCenter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
  }
}
