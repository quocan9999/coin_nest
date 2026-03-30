import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/category_icons.dart';
import '../transactions/transaction_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final userId = context.read<AuthProvider>().currentUserId;
    await context.read<TransactionProvider>().loadTransactions(userId);
    if (mounted) {
      await context.read<AccountProvider>().loadAccounts(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accounts = context.watch<AccountProvider>();
    final txnProv = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // AppBar row
                Row(
                  children: [
                    const Icon(Icons.menu_rounded,
                        color: AppTheme.onSurface, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'CoinNest',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Greeting
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                ),
                Text(
                  auth.currentUser?.fullName ?? 'Bạn',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),

                const SizedBox(height: 20),

                // Total balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TỔNG SỐ DƯ',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  letterSpacing: 1.5,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(accounts.totalBalance),
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 16),
                      // Income / Expense chips
                      Row(
                        children: [
                          _buildSummaryChip(
                            context,
                            icon: Icons.arrow_downward_rounded,
                            label: 'Thu nhập',
                            amount: _calculateMonthlyAmount(
                                txnProv.transactions, 'income'),
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryChip(
                            context,
                            icon: Icons.arrow_upward_rounded,
                            label: 'Chi tiêu',
                            amount: _calculateMonthlyAmount(
                                txnProv.transactions, 'expense'),
                            color: AppTheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Giao dịch gần đây',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TransactionListScreen()),
                      ),
                      child: Text(
                        'XEM TẤT CẢ',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (txnProv.transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: AppTheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có giao dịch nào',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...txnProv.transactions.take(5).map(
                        (txn) => _buildTransactionTile(context, txn),
                      ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    Formatters.compactCurrency(amount),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, dynamic txn) {
    final isExpense = txn.type == 'expense';
    final amountColor = isExpense ? AppTheme.tertiary : AppTheme.secondary;
    final sign = isExpense ? '- ' : '+ ';
    final iconKey = txn.categoryIconName ?? txn.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CategoryIcons.getColor(iconKey).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CategoryIcons.getIcon(iconKey),
              color: CategoryIcons.getColor(iconKey),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.categoryName ?? txn.type,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (txn.note != null && txn.note!.isNotEmpty)
                  Text(
                    txn.note!,
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
                      color: amountColor,
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
    );
  }

  double _calculateMonthlyAmount(List transactions, String type) {
    double total = 0;
    for (final txn in transactions) {
      if (txn.type == type) total += txn.amount;
    }
    return total;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'CHÀO BUỔI SÁNG,';
    if (hour < 18) return 'CHÀO BUỔI CHIỀU,';
    return 'CHÀO BUỔI TỐI,';
  }
}
