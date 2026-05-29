import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/providers/auth_provider.dart';
import 'package:coin_nest/providers/loan_provider.dart';
import 'package:coin_nest/screens/loans/loan_detail_screen.dart';
import 'package:coin_nest/theme/app_theme.dart';
import 'package:coin_nest/utils/formatters.dart';

class LoanTrackingScreen extends StatefulWidget {
  const LoanTrackingScreen({super.key});

  @override
  State<LoanTrackingScreen> createState() => _LoanTrackingScreenState();
}

class _LoanTrackingScreenState extends State<LoanTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Chờ frame đầu hoàn tất để LoanProvider không notifyListeners trong build.
      _loadLoans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId != 0) {
      await context.read<LoanProvider>().loadLoans(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanProv = context.watch<LoanProvider>();

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text(
          'Theo dõi vay nợ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.colors(context).primary,
          ),
        ),
        backgroundColor: AppTheme.colors(context).surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppTheme.colors(context).primary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.colors(context).primary,
          unselectedLabelColor: AppTheme.colors(context).textSecondary,
          indicatorColor: AppTheme.colors(context).primary,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          tabs: [
            Tab(text: 'Cho vay'),
            Tab(text: 'Còn nợ'),
          ],
        ),
      ),
      body: loanProv.isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  context: context,
                  loans: loanProv.loans.where((l) => l.type == 'lend').toList(),
                  isLend: true,
                ),
                _buildTabContent(
                  context: context,
                  loans: loanProv.loans
                      .where((l) => l.type == 'borrow')
                      .toList(),
                  isLend: false,
                ),
              ],
            ),
    );
  }

  Widget _buildTabContent({
    required BuildContext context,
    required List<Loan> loans,
    required bool isLend,
  }) {
    final totalAmount = loans.fold<double>(0, (sum, loan) => sum + loan.amount);
    final totalRemaining = loans.fold<double>(
      0,
      (sum, loan) => sum + loan.remainingAmount,
    );
    final totalPaid = totalAmount - totalRemaining;
    final progress = totalAmount > 0 ? totalPaid / totalAmount : 0.0;

    final color = isLend
        ? AppTheme.colors(context).income
        : AppTheme.colors(context).expense;
    final colorContainer = isLend
        ? AppTheme.colors(context).incomeBg
        : AppTheme.colors(context).expenseBg;

    return RefreshIndicator(
      color: color,
      onRefresh: _loadLoans,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: loans.isEmpty
            ? _buildEmptyState(context)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(
                    context: context,
                    isLend: isLend,
                    color: color,
                    colorContainer: colorContainer,
                    totalPaid: totalPaid,
                    totalAmount: totalAmount,
                    progress: progress,
                  ),
                  SizedBox(height: 32),
                  Text(
                    isLend ? 'DANH SÁCH CHO VAY' : 'DANH SÁCH CẦN TRẢ',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colors(context).textDisabled,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...loans.map(
                    (loan) => _buildLoanCard(
                      context: context,
                      loan: loan,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required bool isLend,
    required Color color,
    required Color colorContainer,
    required double totalPaid,
    required double totalAmount,
    required double progress,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLend ? 'Tổng tiến độ thu tiền' : 'Tổng tiến độ trả nợ',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  Formatters.currency(totalPaid),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '/ ${Formatters.currency(totalAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: clampedProgress,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.colors(
                    context,
                  ).card.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(clampedProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard({
    required BuildContext context,
    required Loan loan,
    required Color color,
  }) {
    final paid = loan.amount - loan.remainingAmount;
    final progress = (loan.paidPercentage / 100).clamp(0.0, 1.0).toDouble();
    final statusLabel = _statusLabel(loan);
    final statusColor = _statusColor(loan);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () => _openLoanDetail(context, loan),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.colors(context).card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppTheme.colors(
                context,
              ).textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    loan.personName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(loan.remainingAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 4),
                    _buildStatusBadge(statusLabel, statusColor),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (loan.dueDate != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: AppTheme.colors(context).border,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Hạn: ${Formatters.date(loan.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.colors(context).textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.colors(context).input,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  Formatters.percent(loan.paidPercentage),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Đã thanh toán: ${Formatters.currency(paid)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.colors(context).textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 72,
              color: AppTheme.colors(context).border,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có khoản nào',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(Loan loan) {
    if (loan.isPaid) return 'Đã trả';
    if (loan.isOverdue) return 'Quá hạn';
    return 'Đang hoạt động';
  }

  Color _statusColor(Loan loan) {
    if (loan.isPaid) return AppTheme.colors(context).income;
    if (loan.isOverdue) return AppTheme.colors(context).expense;
    return AppTheme.colors(context).primary;
  }

  Future<void> _openLoanDetail(BuildContext context, Loan loan) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
    );
    if (!context.mounted) return;
    if (changed == true) {
      await _loadLoans();
    }
  }
}
