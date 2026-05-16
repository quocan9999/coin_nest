import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../models/loan_payment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'payment_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Loan _loan;
  late Future<List<LoanPayment>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
    _paymentsFuture = _loadPayments();
  }

  Future<List<LoanPayment>> _loadPayments() {
    final userId = context.read<AuthProvider>().currentUserId;
    return context.read<LoanProvider>().getPaymentHistory(_loan.id!, userId);
  }

  Future<void> _refreshLoan() async {
    final userId = context.read<AuthProvider>().currentUserId;
    final provider = context.read<LoanProvider>();
    await provider.loadLoans(userId);
    final updated = provider.loans.where((loan) => loan.id == _loan.id).toList();
    if (!mounted) return;
    setState(() {
      if (updated.isNotEmpty) _loan = updated.first;
      _paymentsFuture = _loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _loan.type == 'borrow' ? AppTheme.tertiary : AppTheme.loanColor;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Chi tiết khoản vay'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context, true)),
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
              Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                _chip(_loan.type == 'borrow' ? 'Vay' : 'Cho vay', color),
                _statusBadge(context),
              ]),
              const SizedBox(height: 12),
              Text(_loan.personName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Text('Tổng ${Formatters.currency(_loan.amount)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(Formatters.currency(_loan.remainingAmount), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 8),
              Text('còn lại', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (_loan.paidPercentage / 100).clamp(0, 1),
                backgroundColor: AppTheme.outlineVariant.withAlpha(51),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text('${Formatters.percent(_loan.paidPercentage)} đã trả', style: Theme.of(context).textTheme.labelMedium),
            ]),
          ),
          const SizedBox(height: 16),
          if (!_loan.isPaid)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openPayment,
                icon: const Icon(Icons.payments_outlined),
                label: Text(_loan.type == 'borrow' ? 'Thanh toán' : 'Thu nợ'),
              ),
            ),
          if (!_loan.isPaid) const SizedBox(height: 16),
          _detailRow(context, 'Ngày bắt đầu', Formatters.date(_loan.startDate)),
          if (_loan.dueDate != null) _detailRow(context, 'Hạn trả', Formatters.date(_loan.dueDate!)),
          if (_loan.interestRate > 0) _detailRow(context, 'Lãi suất', '${_loan.interestRate}%/năm'),
          if (_loan.accountName != null) _detailRow(context, 'Tài khoản', _loan.accountName!),
          if (_loan.note != null && _loan.note!.isNotEmpty) _detailRow(context, 'Ghi chú', _loan.note!),
          _detailRow(context, 'Trạng thái', _statusText),
          const SizedBox(height: 24),
          Text('LỊCH SỬ THANH TOÁN', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.outline, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          _paymentHistory(),
        ]),
      ),
    );
  }

  String get _statusText {
    if (_loan.isPaid) return 'Đã trả';
    if (_loan.isOverdue) return 'Quá hạn';
    return 'Đang hoạt động';
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusBadge(BuildContext context) {
    final color = _loan.isPaid ? AppTheme.secondary : (_loan.isOverdue ? AppTheme.tertiary : AppTheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      child: Text(_statusText, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _paymentHistory() {
    return FutureBuilder<List<LoanPayment>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            child: Text('Chưa có thanh toán nào', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
          );
        }
        return Column(
          children: payments.map((payment) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppTheme.primary.withAlpha(18), borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                child: const Icon(Icons.receipt_long_outlined, size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Formatters.currency(payment.amount), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(Formatters.date(payment.paymentDate), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                if (payment.note != null && payment.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(payment.note!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ])),
            ]),
          )).toList(),
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Future<void> _openPayment() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PaymentScreen(loan: _loan)));
    if (changed == true) await _refreshLoan();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Xóa khoản vay'),
      content: Text('Xóa khoản vay với "${_loan.personName}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        TextButton(onPressed: () async {
          final userId = context.read<AuthProvider>().currentUserId;
          await context.read<LoanProvider>().deleteLoan(_loan.id!, userId);
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) Navigator.pop(context, true);
        }, child: const Text('Xóa', style: TextStyle(color: AppTheme.tertiary))),
      ],
    ));
  }
}
