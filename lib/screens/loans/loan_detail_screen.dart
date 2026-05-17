import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final color = loan.type == 'borrow' ? AppTheme.tertiary : AppTheme.loanColor;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Chi tiết khoản vay'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.tertiary), onPressed: () => _confirmDelete(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Text(loan.type == 'borrow' ? 'Vay' : 'Cho vay', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Text(loan.personName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Text('Tổng ${Formatters.currency(loan.amount)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(Formatters.currency(loan.remainingAmount), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 8),
              Text('còn lại', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (loan.paidPercentage / 100).clamp(0, 1),
                backgroundColor: AppTheme.outlineVariant.withAlpha(51),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text('${Formatters.percent(loan.paidPercentage)} đã trả', style: Theme.of(context).textTheme.labelMedium),
            ]),
          ),
          const SizedBox(height: 16),
          _detailRow(context, 'Ngày bắt đầu', Formatters.date(loan.startDate)),
          if (loan.dueDate != null) _detailRow(context, 'Hạn trả', Formatters.date(loan.dueDate!)),
          if (loan.interestRate > 0) _detailRow(context, 'Lãi suất', '${loan.interestRate}%/năm'),
          if (loan.accountName != null) _detailRow(context, 'Tài khoản', loan.accountName!),
          if (loan.note != null && loan.note!.isNotEmpty) _detailRow(context, 'Ghi chú', loan.note!),
          _detailRow(context, 'Trạng thái', loan.isPaid ? 'Đã trả' : (loan.isOverdue ? 'Quá hạn' : 'Đang hoạt động')),
        ]),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Xóa khoản vay'),
      content: Text('Xóa khoản vay với "${loan.personName}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        TextButton(onPressed: () async {
          final userId = context.read<AuthProvider>().currentUserId;
          await context.read<LoanProvider>().deleteLoan(loan.id!, userId);
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Xóa', style: TextStyle(color: AppTheme.tertiary))),
      ],
    ));
  }
}
