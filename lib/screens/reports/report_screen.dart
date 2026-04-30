import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/report_provider.dart';
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
  @override
  void initState() {
    super.initState();
    _loadPreviewData();
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Báo cáo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadPreviewData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
          _buildMenuCard(
            context: context,
            icon: Icons.account_balance_wallet_rounded,
            iconBgColor: AppTheme.primaryContainer,
            iconColor: AppTheme.primary,
            title: 'Tài chính hiện tại',
            subtitle: 'Tổng quan tài sản và khoản nợ',
            previewKey: 'finance_${netWorth.toStringAsFixed(0)}',
            preview: accountProv.isLoading || loanProv.isLoading
                ? _buildSkeletonBar(width: 100, height: 12)
                : Text(
                    'Tài sản ròng: ${Formatters.currency(netWorth)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: netWorth >= 0
                              ? AppTheme.secondary
                              : AppTheme.tertiary,
                        ),
                  ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CurrentFinanceScreen()),
              ).then((_) => _loadPreviewData());
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.bar_chart_rounded,
            iconBgColor: AppTheme.secondaryContainer,
            iconColor: AppTheme.secondary,
            title: 'Tình hình thu chi',
            subtitle: 'Phân tích thu nhập và chi tiêu',
            previewKey: 'inex_${reportProv.totalIncome}_${reportProv.totalExpense}',
            preview: reportProv.isLoading
                ? _buildSkeletonBar()
                : Row(
                    children: [
                      Text(
                        '↑ ${Formatters.currency(reportProv.totalIncome)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.secondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '↓ ${Formatters.currency(reportProv.totalExpense)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.tertiary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(tháng này)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomeExpenseScreen()),
              ).then((_) => _loadPreviewData());
            },
          ),
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
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tertiary,
                            ),
                      )
                    : Text(
                        'Chưa có chi tiêu tháng này',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseAnalysisScreen()),
              ).then((_) => _loadPreviewData());
            },
          ),
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
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondary,
                            ),
                      )
                    : Text(
                        'Chưa có thu nhập tháng này',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomeAnalysisScreen()),
              ).then((_) => _loadPreviewData());
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.receipt_long_rounded,
            iconBgColor: const Color(0xFFFFE0B2),
            iconColor: const Color(0xFFE65100),
            title: 'Theo dõi vay nợ',
            subtitle: 'Quản lý các khoản vay và cho vay',
            previewKey: 'loan_${totalLentRemaining}_${totalBorrowedRemaining}',
            preview: loanProv.isLoading
                ? _buildSkeletonBar()
                : (totalLentRemaining == 0 && totalBorrowedRemaining == 0)
                    ? Text(
                        'Không có khoản vay nào',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cho vay: ${Formatters.currency(totalLentRemaining)}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.secondary,
                                ),
                          ),
                          Text(
                            'Còn nợ: ${Formatters.currency(totalBorrowedRemaining)}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.tertiary,
                                ),
                          ),
                        ],
                      ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoanTrackingScreen()),
              ).then((_) => _loadPreviewData());
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
