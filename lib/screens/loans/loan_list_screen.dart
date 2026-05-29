import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'add_edit_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});
  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().currentUserId;
      context.read<LoanProvider>().loadLoans(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loanProv = context.watch<LoanProvider>();

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text('Vay / Cho vay'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.colors(context).primary,
            ),
            onPressed: _openAddLoan,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    context,
                    'Đang vay',
                    loanProv.summary['borrowed'] ?? 0,
                    AppTheme.colors(context).expense,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    context,
                    'Cho vay',
                    loanProv.summary['lent'] ?? 0,
                    AppTheme.colors(context).warning,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loanProv.loans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 56,
                          color: AppTheme.colors(context).border,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có khoản vay nào',
                          style: TextStyle(
                            color: AppTheme.colors(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: loanProv.loans.length,
                    itemBuilder: (_, i) {
                      final loan = loanProv.loans[i];
                      return GestureDetector(
                        onTap: () => _openLoanDetail(loan),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).card,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: loan.type == 'borrow'
                                          ? AppTheme.colors(
                                              context,
                                            ).expense.withAlpha(20)
                                          : AppTheme.colors(
                                              context,
                                            ).warning.withAlpha(20),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm,
                                      ),
                                    ),
                                    child: Text(
                                      loan.type == 'borrow' ? 'Vay' : 'Cho vay',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: loan.type == 'borrow'
                                            ? AppTheme.colors(context).expense
                                            : AppTheme.colors(context).warning,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _statusBadge(context, loan),
                                  Spacer(),
                                  Text(
                                    Formatters.currency(loan.remainingAmount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                loan.personName,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: (loan.paidPercentage / 100).clamp(0, 1),
                                backgroundColor: AppTheme.colors(
                                  context,
                                ).border.withAlpha(51),
                                valueColor: AlwaysStoppedAnimation(
                                  loan.type == 'borrow'
                                      ? AppTheme.colors(context).expense
                                      : AppTheme.colors(context).warning,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${Formatters.percent(loan.paidPercentage)} đã trả • ${Formatters.date(loan.startDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    final userId = context.read<AuthProvider>().currentUserId;
    await context.read<LoanProvider>().loadLoans(userId);
  }

  Future<void> _openAddLoan() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditLoanScreen()),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _openLoanDetail(dynamic loan) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
    );
    if (changed == true) await _refresh();
  }

  Widget _statusBadge(BuildContext context, dynamic loan) {
    final label = loan.isPaid
        ? 'Đã trả'
        : (loan.isOverdue ? 'Quá hạn' : 'Đang hoạt động');
    final color = loan.isPaid
        ? AppTheme.colors(context).income
        : (loan.isOverdue
              ? AppTheme.colors(context).expense
              : AppTheme.colors(context).primary);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(6),
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

  Widget _summaryCard(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
          SizedBox(height: 4),
          Text(
            Formatters.currency(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
