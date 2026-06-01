import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/transaction_provider.dart';

import '../../theme/app_theme.dart';

import '../../utils/formatters.dart';

import 'current_finance_screen.dart';
import 'expense_analysis_screen.dart';
import 'income_analysis_screen.dart';
import 'income_expense_screen.dart';
import 'loan_tracking_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int? _lastTransactionRevision;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPreviewData();
    });
  }

  void _reloadWhenTransactionRevisionChanges(int transactionRevision) {
    if (_lastTransactionRevision == null) {
      _lastTransactionRevision = transactionRevision;
      return;
    }

    if (_lastTransactionRevision == transactionRevision) return;

    _lastTransactionRevision = transactionRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPreviewData();
    });
  }

  Future<void> _loadPreviewData() async {
    if (!mounted) return;

    final userId = context.read<AuthProvider>().currentUserId;

    if (userId == 0) return;

    final now = DateTime.now();

    await Future.wait([
      context.read<AccountProvider>().loadAccounts(userId),

      context.read<LoanProvider>().loadLoans(userId),

      context.read<ReportProvider>().loadReport(
        userId,

        from: DateTime(now.year, now.month, 1),

        to: DateTime(now.year, now.month + 1, 0),
      ),
    ]);

    if (!mounted) return;
  }

  Widget _buildSkeletonBar({double width = 120, double height = 12}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,

      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,

        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionRevision = context.select<TransactionProvider, int>(
      (provider) => provider.revision,
    );
    _reloadWhenTransactionRevisionChanges(transactionRevision);

    final colorScheme = theme.colorScheme;

    final accountProv = context.watch<AccountProvider>();

    final loanProv = context.watch<LoanProvider>();

    final reportProv = context.watch<ReportProvider>();

    final totalAccountBalance = accountProv.accounts
        .where((a) => a.isIncludedInTotal)
        .fold<double>(0, (s, a) => s + a.balance);

    final totalBorrowedRemaining = loanProv.loans
        .where((l) => l.type == 'borrow' && l.status != 'paid')
        .fold<double>(0, (s, l) => s + l.remainingAmount);

    final totalLentRemaining = loanProv.loans
        .where((l) => l.type == 'lend' && l.status != 'paid')
        .fold<double>(0, (s, l) => s + l.remainingAmount);

    final netWorth =
        totalAccountBalance + totalLentRemaining - totalBorrowedRemaining;

    return Scaffold(
      backgroundColor: colorScheme.surface,

      appBar: AppBar(
        backgroundColor: colorScheme.surface,

        elevation: 0,

        centerTitle: false,

        title: Text(
          'Báo cáo',

          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,

            color: colorScheme.primary,
          ),
        ),
      ),

      body: RefreshIndicator(
        color: colorScheme.primary,

        onRefresh: _loadPreviewData,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

          children: [
            // TÀI CHÍNH
            _buildMenuCard(
              context: context,

              icon: Icons.account_balance_wallet_rounded,

              iconBgColor: AppTheme.primaryContainer,

              iconColor: colorScheme.primary,

              title: 'Tài chính hiện tại',

              subtitle: 'Tổng quan tài sản và khoản nợ',

              previewKey: 'finance_${netWorth.toStringAsFixed(0)}',

              preview: accountProv.isLoading || loanProv.isLoading
                  ? _buildSkeletonBar(width: 100, height: 12)
                  : Text(
                      'Tài sản ròng: ${Formatters.currency(netWorth)}',

                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,

                        color: netWorth >= 0
                            ? AppTheme.secondary
                            : AppTheme.tertiary,
                      ),
                    ),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const CurrentFinanceScreen(),
                  ),
                ).then((_) {
                  if (mounted) {
                    _loadPreviewData();
                  }
                });
              },
            ),

            // THU CHI
            _buildMenuCard(
              context: context,

              icon: Icons.bar_chart_rounded,

              iconBgColor: AppTheme.secondaryContainer,

              iconColor: AppTheme.secondary,

              title: 'Tình hình thu chi',

              subtitle: 'Phân tích thu nhập và chi tiêu',

              previewKey:
                  'inex_${reportProv.totalIncome}_${reportProv.totalExpense}',

              preview: reportProv.isLoading
                  ? _buildSkeletonBar()
                  : Wrap(
                      spacing: 6,
                      runSpacing: 2,

                      children: [
                        Text(
                          '↑ ${Formatters.currency(reportProv.totalIncome)}',

                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.secondary,
                          ),
                        ),

                        Text(
                          '↓ ${Formatters.currency(reportProv.totalExpense)}',

                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.tertiary,
                          ),
                        ),

                        Text(
                          '(tháng này)',

                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const IncomeExpenseScreen(),
                  ),
                ).then((_) {
                  if (mounted) {
                    _loadPreviewData();
                  }
                });
              },
            ),

            // CHI TIÊU
            _buildMenuCard(
              context: context,

              icon: Icons.pie_chart_rounded,

              iconBgColor: AppTheme.tertiaryContainer,

              iconColor: AppTheme.tertiary,

              title: 'Phân tích chi tiêu',

              subtitle: 'Chi tiết chi tiêu theo hạng mục',

              previewKey: 'exp_${reportProv.totalExpense}',

              preview: reportProv.isLoading
                  ? _buildSkeletonBar()
                  : reportProv.totalExpense > 0
                  ? Text(
                      'Tháng này: ${Formatters.currency(reportProv.totalExpense)}',

                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,

                        color: AppTheme.tertiary,
                      ),
                    )
                  : Text(
                      'Chưa có chi tiêu tháng này',

                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const ExpenseAnalysisScreen(),
                  ),
                ).then((_) {
                  if (mounted) {
                    _loadPreviewData();
                  }
                });
              },
            ),

            // THU NHẬP
            _buildMenuCard(
              context: context,

              icon: Icons.show_chart_rounded,

              iconBgColor: const Color(0xFFC8E6C9),

              iconColor: const Color(0xFF2E7D32),

              title: 'Phân tích thu',

              subtitle: 'Chi tiết thu nhập theo hạng mục',

              previewKey: 'inc_${reportProv.totalIncome}',

              preview: reportProv.isLoading
                  ? _buildSkeletonBar()
                  : reportProv.totalIncome > 0
                  ? Text(
                      'Tháng này: ${Formatters.currency(reportProv.totalIncome)}',

                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,

                        color: AppTheme.secondary,
                      ),
                    )
                  : Text(
                      'Chưa có thu nhập tháng này',

                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const IncomeAnalysisScreen(),
                  ),
                ).then((_) {
                  if (mounted) {
                    _loadPreviewData();
                  }
                });
              },
            ),

            // VAY NỢ
            _buildMenuCard(
              context: context,

              icon: Icons.receipt_long_rounded,

              iconBgColor: const Color(0xFFFFE0B2),

              iconColor: const Color(0xFFE65100),

              title: 'Theo dõi vay nợ',

              subtitle: 'Tổng quan khoản vay và cho vay',

              previewKey: 'loan_${totalLentRemaining}_$totalBorrowedRemaining',

              preview: loanProv.isLoading
                  ? _buildSkeletonBar()
                  : (totalLentRemaining == 0 && totalBorrowedRemaining == 0)
                  ? Text(
                      'Không có khoản vay nào',

                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Cho vay: ${Formatters.currency(totalLentRemaining)}',

                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.secondary,
                          ),
                        ),

                        Text(
                          'Còn nợ: ${Formatters.currency(totalBorrowedRemaining)}',

                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.tertiary,
                          ),
                        ),
                      ],
                    ),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (_) => const LoanTrackingScreen()),
                ).then((_) {
                  if (mounted) {
                    _loadPreviewData();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String previewKey,
    required Widget preview,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(AppTheme.radiusLg),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,

            borderRadius: BorderRadius.circular(AppTheme.radiusLg),

            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.04),

                blurRadius: 10,

                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),

                child: Icon(icon, color: iconColor),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,

                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 6),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),

                      child: KeyedSubtree(
                        key: ValueKey(previewKey),

                        child: preview,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Icon(
                Icons.chevron_right_rounded,

                color: colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
