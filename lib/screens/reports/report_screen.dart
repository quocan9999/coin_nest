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
        color: AppTheme.colors(context).input,
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
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text(
          'Báo cáo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.colors(context).primary,
          ),
        ),
        backgroundColor: AppTheme.colors(context).surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppTheme.colors(context).primary,
        onRefresh: _loadPreviewData,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildMenuCard(
              context: context,
              icon: Icons.account_balance_wallet_rounded,
              iconBgColor: AppTheme.colors(context).transferBg,
              iconColor: AppTheme.colors(context).primary,
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
                            ? AppTheme.colors(context).income
                            : AppTheme.colors(context).expense,
                      ),
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CurrentFinanceScreen()),
                ).then((_) {
                  if (mounted) _loadPreviewData();
                });
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.bar_chart_rounded,
              iconBgColor: AppTheme.colors(context).incomeBg,
              iconColor: AppTheme.colors(context).income,
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
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.colors(context).income,
                              ),
                        ),
                        Text(
                          '↓ ${Formatters.currency(reportProv.totalExpense)}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.colors(context).expense,
                              ),
                        ),
                        Text(
                          '(tháng này)',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.colors(context).textSecondary,
                              ),
                        ),
                      ],
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => IncomeExpenseScreen()),
                ).then((_) {
                  if (mounted) _loadPreviewData();
                });
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.pie_chart_rounded,
              iconBgColor: AppTheme.colors(context).expenseBg,
              iconColor: AppTheme.colors(context).expense,
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
                        color: AppTheme.colors(context).expense,
                      ),
                    )
                  : Text(
                      'Chưa có chi tiêu tháng này',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExpenseAnalysisScreen()),
                ).then((_) {
                  if (mounted) _loadPreviewData();
                });
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.show_chart_rounded,
              iconBgColor: AppTheme.colors(context).incomeBg,
              iconColor: AppTheme.colors(context).income,
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
                        color: AppTheme.colors(context).income,
                      ),
                    )
                  : Text(
                      'Chưa có thu nhập tháng này',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => IncomeAnalysisScreen()),
                ).then((_) {
                  if (mounted) _loadPreviewData();
                });
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.receipt_long_rounded,
              iconBgColor: AppTheme.colors(context).warningBg,
              iconColor: AppTheme.colors(context).warning,
              title: 'Theo dõi vay nợ',
              subtitle: 'Tổng quan khoản vay và cho vay',
              previewKey: 'loan_${totalLentRemaining}_$totalBorrowedRemaining',
              preview: loanProv.isLoading
                  ? _buildSkeletonBar()
                  : (totalLentRemaining == 0 && totalBorrowedRemaining == 0)
                  ? Text(
                      'Không có khoản vay nào',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cho vay: ${Formatters.currency(totalLentRemaining)}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.colors(context).income,
                              ),
                        ),
                        Text(
                          'Còn nợ: ${Formatters.currency(totalBorrowedRemaining)}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.colors(context).expense,
                              ),
                        ),
                      ],
                    ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoanTrackingScreen()),
                ).then((_) {
                  if (mounted) _loadPreviewData();
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
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.colors(context).card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppTheme.colors(
                  context,
                ).textPrimary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
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
              SizedBox(width: 16),
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
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ),
                    SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(previewKey),
                        child: preview,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.colors(context).border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
