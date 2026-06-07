import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/ai_spending_insight_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/category_icons.dart';
import '../../services/notification/notification_record_service.dart';
import '../loans/loan_detail_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../../widgets/notification_badge_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<int>? _autoRecordSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadRecent();
    });

    _autoRecordSubscription = NotificationRecordService.recordedTransactions
        .listen(_handleAutoRecordedTransaction);
  }

  @override
  void dispose() {
    _autoRecordSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleAutoRecordedTransaction(int userId) async {
    if (!mounted) return;
    if (context.read<AuthProvider>().currentUserId != userId) return;

    await _loadRecent();
  }

  Future<void> _loadRecent() async {
    // 1. Đọc tất cả Provider trước khi có bất kỳ lệnh await nào (tránh lỗi async gap)
    final authProv = context.read<AuthProvider>();
    final txnProv = context.read<TransactionProvider>();
    final accProv = context.read<AccountProvider>();
    final loanProv = context.read<LoanProvider>();
    final budgetProv = context.read<BudgetProvider>();
    final aiProv = context.read<AiSpendingInsightProvider>();

    final userId = authProv.currentUserId;

    // 2. Dùng biến Provider đã lưu để gọi hàm thay vì gọi lại context
    // ĐÃ SỬA: Gọi hàm tải 5 giao dịch gần nhất
    await txnProv.loadRecentTransactions(userId);

    // Vẫn tải danh sách tổng để tính Tổng Thu/Chi
    await txnProv.loadTransactions(userId);

    if (mounted) {
      await accProv.loadAccounts(userId);
      await loanProv.loadLoans(userId);
      await budgetProv.loadBudgets(userId);
      await aiProv.loadCachedInsight(userId);
    }
  }

  Future<void> _refreshAiInsight() async {
    final userId = context.read<AuthProvider>().currentUserId;

    await context.read<AiSpendingInsightProvider>().refreshInsight(
      userId: userId,
      totalBalance: context.read<AccountProvider>().totalBalance,
      transactions: context.read<TransactionProvider>().transactions,
      loans: context.read<LoanProvider>().loans,
      budgets: context.read<BudgetProvider>().budgets,
    );
  }

  // Hàm chuyển đổi loại giao dịch sang tiếng Việt
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
    final auth = context.watch<AuthProvider>();

    final accounts = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();

    final txnProv = context.watch<TransactionProvider>();
    final aiProv = context.watch<AiSpendingInsightProvider>();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

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
                    Icon(
                      Icons.menu_rounded,

                      color: theme.colorScheme.onSurface,

                      size: 24,
                    ),

                    const SizedBox(width: 12),

                    Text(
                      'CoinNest',

                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primary,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    NotificationBadgeButton(
                      onPressed: () => _openNotificationCenter(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Greeting
                Text(
                  _greeting(),

                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,

                    letterSpacing: 1,
                  ),
                ),

                Text(
                  auth.currentUser?.fullName ?? 'Bạn',

                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 20),

                // Total balance card
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: theme.cardColor,

                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'TỔNG SỐ DƯ',

                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,

                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        settings.showBalance
                            ? Formatters.currency(accounts.totalBalance)
                            : '••••••',

                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,

                              color: theme.colorScheme.onSurface,
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
                              txnProv.transactions,
                              'income',
                            ),

                            color: AppTheme.secondary,
                          ),

                          const SizedBox(width: 12),

                          _buildSummaryChip(
                            context,

                            icon: Icons.arrow_upward_rounded,

                            label: 'Chi tiêu',

                            amount: _calculateMonthlyAmount(
                              txnProv.transactions,
                              'expense',
                            ),

                            color: AppTheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildAiInsightCard(context, aiProv),

                const SizedBox(height: 24),

                // Recent transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      'Ghi chép gần đây',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => const TransactionListScreen(),
                        ),
                      ),

                      child: Text(
                        'XEM TẤT CẢ',

                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.primary,

                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (txnProv.recentTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),

                    decoration: BoxDecoration(
                      color: theme.cardColor,

                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),

                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,

                            size: 48,

                            color: theme.colorScheme.outlineVariant,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Chưa có giao dịch nào',

                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // ĐÃ SỬA: Thêm .toList() vào cuối map để triệt tiêu lỗi gạch đỏ ép kiểu trong hình
                  ...txnProv.recentTransactions.map(
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

  Widget _buildAiInsightCard(
    BuildContext context,
    AiSpendingInsightProvider provider,
  ) {
    final theme = Theme.of(context);
    final colors = AppTheme.colors(context);
    final insight = provider.insight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing4),
                decoration: BoxDecoration(
                  color: colors.transferBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.transfer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý tiết kiệm AI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      insight == null
                          ? 'Cập nhật khi bạn muốn xem cảnh báo chi tiêu tháng này.'
                          : 'Cập nhật lần cuối ${Formatters.dateTime(insight.generatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: provider.isLoading ? null : _refreshAiInsight,
                child: provider.isLoading
                    ? const SizedBox(
                        width: AppTheme.spacing8,
                        height: AppTheme.spacing8,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cập nhật'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          if (provider.errorMessage != null)
            _buildAiStateBox(
              context,
              provider.errorMessage!,
              Icons.wifi_off_rounded,
              colors.warning,
              colors.warningBg,
            )
          else if (insight == null)
            _buildAiStateBox(
              context,
              'Chưa có gợi ý. CoinNest chỉ gửi tóm tắt tháng, không gửi toàn bộ lịch sử giao dịch.',
              Icons.lightbulb_outline_rounded,
              colors.textSecondary,
              theme.colorScheme.surfaceContainerLow,
            )
          else ...[
            _buildSeverityChip(context, insight.severity),
            const SizedBox(height: AppTheme.spacing6),
            Text(
              _plainText(insight.title),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              _plainText(insight.summary),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (insight.alerts.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing8),
              _buildAiList(context, 'Cảnh báo', insight.alerts, colors.warning),
            ],
            if (insight.savingTips.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing8),
              _buildAiList(
                context,
                'Gợi ý tiết kiệm',
                insight.savingTips,
                colors.income,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAiStateBox(
    BuildContext context,
    String message,
    IconData icon,
    Color iconColor,
    Color backgroundColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppTheme.spacing6),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(BuildContext context, String severity) {
    final colors = AppTheme.colors(context);
    final normalized = severity.toLowerCase();
    final color = normalized == 'high'
        ? colors.expense
        : normalized == 'medium'
        ? colors.warning
        : colors.income;
    final background = normalized == 'high'
        ? colors.expenseBg
        : normalized == 'medium'
        ? colors.warningBg
        : colors.incomeBg;
    final label = normalized == 'high'
        ? 'Rủi ro cao'
        : normalized == 'medium'
        ? 'Cần chú ý'
        : 'Ổn định';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing6,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAiList(
    BuildContext context,
    String title,
    List<String> items,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        ...items
            .take(3)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: iconColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Expanded(
                      child: Text(
                        _plainText(item),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  String _plainText(String value) {
    return value
        .replaceAll('```', '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildTransactionTile(BuildContext context, TransactionModel txn) {
    final theme = Theme.of(context);
    final amountColor = txn.isNegative ? AppTheme.tertiary : AppTheme.secondary;
    final sign = txn.isNegative ? '- ' : '+ ';
    final iconKey = txn.categoryIconName ?? txn.type;

    return GestureDetector(
      // Thêm tính năng bấm vào giao dịch ở trang chủ để sửa luôn (tùy chọn, giống trang list)
      onTap: () {
        _openTransaction(context, txn);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: theme.cardColor,

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
                    txn.categoryName ?? _getTypeLabel(txn.type),

                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    txn.time ?? Formatters.time(txn.date),

                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  if (txn.note != null && txn.note!.isNotEmpty)
                    Text(
                      txn.note!,

                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: amountColor,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (txn.accountName != null)
                  Text(
                    txn.accountName!,

                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: txn),
      ),
    );
    if (!context.mounted) return;
    await _loadRecent();
  }

  void _openNotificationCenter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
  }

  double _calculateMonthlyAmount(List transactions, String type) {
    double total = 0;

    for (final txn in transactions) {
      if (type == 'income' && (txn.type == 'income' || txn.type == 'loan')) {
        total += txn.amount;
      }
      if (type == 'expense' && (txn.type == 'expense' || txn.type == 'lend')) {
        total += txn.amount;
      }
    }

    return total;
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'CHÀO BUỔI SÁNG,';
    }

    if (hour < 18) {
      return 'CHÀO BUỔI CHIỀU,';
    }

    return 'CHÀO BUỔI TỐI,';
  }
}
