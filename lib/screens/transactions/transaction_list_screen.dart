import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/category_icons.dart';
import '../loans/loan_detail_screen.dart';
import 'add_transaction_screen.dart';

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
      context.read<TransactionProvider>().loadTransactions(userId);
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
      case 'loan':
        return 'Đi vay';
      case 'lend':
        return 'Cho vay';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final txnProv = context.watch<TransactionProvider>();
    final grouped = txnProv.groupedByDate;

    return Scaffold(
      backgroundColor: AppTheme.surface,
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (q) {
                txnProv.setSearchQuery(q);
                txnProv.loadTransactions(
                  context.read<AuthProvider>().currentUserId,
                );
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm giao dịch...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _filterChip('Tháng này', Icons.calendar_month, true),
                const SizedBox(width: 8),
                _filterChip('Hạng mục', Icons.category_outlined, false),
                const SizedBox(width: 8),
                _filterChip('Tài khoản', Icons.account_balance_outlined, false),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Transaction list
          Expanded(
            child: txnProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : txnProv.transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: AppTheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
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
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                              Text(
                                Formatters.signedCurrency(total),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: total >= 0
                                          ? AppTheme.secondary
                                          : AppTheme.tertiary,
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

  Widget _filterChip(String label, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? Colors.white : AppTheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnTile(BuildContext context, TransactionModel txn) {
    final color = txn.isNegative
        ? AppTheme.tertiary
        : (txn.type == 'transfer' ? AppTheme.primary : AppTheme.secondary);
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
          color: AppTheme.surfaceContainerLowest,
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
                  // ĐÃ SỬA: Sử dụng _getTypeLabel(txn.type) nếu không có categoryName
                  Text(
                    txn.categoryName ?? _getTypeLabel(txn.type),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$noteStr${txn.time ?? Formatters.time(txn.date)}',
                    style: Theme.of(context).textTheme.bodySmall,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (txn.accountName != null)
                  Text(
                    txn.accountName!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
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
            content: Text('Không tìm thấy khoản vay liên kết với giao dịch này'),
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: txn),
      ),
    );
  }
}
