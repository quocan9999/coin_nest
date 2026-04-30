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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Vay / Cho vay'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditLoanScreen()))),
        ],
      ),
      body: Column(children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(child: _summaryCard(context, 'Đang vay', loanProv.summary['borrowed'] ?? 0, AppTheme.tertiary)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard(context, 'Cho vay', loanProv.summary['lent'] ?? 0, AppTheme.loanColor)),
          ]),
        ),
        Expanded(
          child: loanProv.loans.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.handshake_outlined, size: 56, color: AppTheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Chưa có khoản vay nào', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: loanProv.loans.length,
                  itemBuilder: (_, i) {
                    final loan = loanProv.loans[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: loan.type == 'borrow' ? AppTheme.tertiary.withAlpha(20) : AppTheme.loanColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(loan.type == 'borrow' ? 'Vay' : 'Cho vay',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: loan.type == 'borrow' ? AppTheme.tertiary : AppTheme.loanColor)),
                            ),
                            const Spacer(),
                            Text(Formatters.currency(loan.remainingAmount), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 8),
                          Text(loan.personName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (loan.paidPercentage / 100).clamp(0, 1),
                            backgroundColor: AppTheme.outlineVariant.withAlpha(51),
                            valueColor: AlwaysStoppedAnimation(loan.type == 'borrow' ? AppTheme.tertiary : AppTheme.loanColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text('${Formatters.percent(loan.paidPercentage)} đã trả • ${Formatters.date(loan.startDate)}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _summaryCard(BuildContext context, String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(Formatters.currency(amount), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
