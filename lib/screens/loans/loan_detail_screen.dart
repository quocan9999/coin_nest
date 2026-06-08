import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../models/loan_payment.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'add_edit_loan_screen.dart';
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

    final updated = provider.loans
        .where((loan) => loan.id == _loan.id)
        .toList();

    if (!mounted) return;

    setState(() {
      if (updated.isNotEmpty) {
        _loan = updated.first;
      }
      _paymentsFuture = _loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = _loan.type == 'borrow'
        ? AppTheme.tertiary
        : AppTheme.loanColor;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Chi tiết khoản vay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
            onPressed: _openEditLoan,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.tertiary),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD THÔNG TIN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Wrap(
                    spacing: AppTheme.spacing4,
                    runSpacing: AppTheme.spacing4,
                    alignment: WrapAlignment.center,
                    children: [
                      _chip(_loan.type == 'borrow' ? 'Vay' : 'Cho vay', color),
                      _statusBadge(context),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing6),
                  Text(
                    _loan.personName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    _loan.type == 'borrow'
                        ? 'Tổng còn phải trả'
                        : 'Tổng còn phải thu',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    Formatters.currency(_loan.totalOutstanding),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'gồm gốc và lãi chưa thanh toán',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  LinearProgressIndicator(
                    value: (_loan.paidPercentage / 100).clamp(0, 1),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(color),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    minHeight: AppTheme.spacing4,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '${Formatters.percent(_loan.paidPercentage)} đã trả',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            if (!_loan.isPaid)
              SizedBox(
                width: double.infinity,
                height: AppTheme.spacing24 + AppTheme.spacing2,
                child: ElevatedButton.icon(
                  onPressed: _openPayment,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(_loan.type == 'borrow' ? 'Thanh toán' : 'Thu nợ'),
                ),
              ),
            if (!_loan.isPaid) const SizedBox(height: AppTheme.spacing8),
            _detailRow(
              context,
              'Ngày bắt đầu',
              Formatters.date(_loan.startDate),
            ),

            if (_loan.dueDate != null)
              _detailRow(context, 'Hạn trả', Formatters.date(_loan.dueDate!)),

            _detailRow(
              context,
              'Gốc ban đầu',
              Formatters.currency(_loan.principalAmount),
            ),
            _detailRow(
              context,
              'Gốc còn lại',
              Formatters.currency(_loan.principalRemaining),
            ),
            _detailRow(
              context,
              'Lãi đã phát sinh',
              Formatters.currency(_loan.interestAccrued),
            ),
            _detailRow(
              context,
              _loan.type == 'borrow' ? 'Lãi đã trả' : 'Lãi đã thu',
              Formatters.currency(_loan.interestPaid),
            ),
            _detailRow(
              context,
              _loan.type == 'borrow' ? 'Lãi chưa trả' : 'Lãi chưa thu',
              Formatters.currency(_loan.interestOutstanding),
            ),
            _detailRow(
              context,
              _loan.type == 'borrow' ? 'Tổng đã trả' : 'Tổng đã thu',
              Formatters.currency(_loan.totalPaid),
            ),
            _detailRow(
              context,
              _loan.type == 'borrow'
                  ? 'Tổng còn phải trả'
                  : 'Tổng còn phải thu',
              Formatters.currency(_loan.totalOutstanding),
            ),
            _detailRow(context, 'Lãi suất', '${_loan.interestRate}%/năm'),

            if (_loan.accountName != null)
              _detailRow(context, 'Tài khoản', _loan.accountName!),
            if (_loan.note != null && _loan.note!.isNotEmpty)
              _detailRow(context, 'Ghi chú', _loan.note!),
            _detailRow(context, 'Trạng thái', _statusText),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'LỊCH SỬ THANH TOÁN',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.outline,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppTheme.spacing6),
            _paymentHistory(),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing6,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusBadge(BuildContext context) {
    final color = _loan.isPaid
        ? AppTheme.secondary
        : (_loan.isOverdue ? AppTheme.tertiary : AppTheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing6,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        _statusText,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _paymentHistory() {
    return FutureBuilder<List<LoanPayment>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing8),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              'Chưa có thanh toán nào',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          children: payments
              .map(
                (payment) => GestureDetector(
                  onTap: () => _openEditPayment(payment),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppTheme.spacing20,
                          height: AppTheme.spacing20,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: AppTheme.spacing10,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.currency(payment.amount),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppTheme.spacing2 / 2),
                              Text(
                                Formatters.date(payment.paymentDate),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (payment.interestAmount > 0 ||
                                  payment.principalAmount > 0) ...[
                                const SizedBox(height: AppTheme.spacing2 / 2),
                                Text(
                                  payment.interestAmount > 0
                                      ? 'Lãi: ${Formatters.currency(payment.interestAmount)} · Gốc: ${Formatters.currency(payment.principalAmount)}'
                                      : 'Gốc: ${Formatters.currency(payment.principalAmount)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                              if (payment.note != null &&
                                  payment.note!.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacing2 / 2),
                                Text(
                                  payment.note!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPayment() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(loan: _loan)),
    );
    if (changed == true) await _refreshLoan();
  }

  Future<void> _openEditPayment(LoanPayment payment) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(loan: _loan, payment: payment),
      ),
    );
    if (changed == true) await _refreshLoan();
  }

  Future<void> _openEditLoan() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditLoanScreen(loan: _loan)),
    );
    if (changed == true) await _refreshLoan();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khoản vay'),
        content: Text('Xóa khoản vay với "${_loan.personName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final userId = context.read<AuthProvider>().currentUserId;
              await context.read<LoanProvider>().deleteLoan(_loan.id!, userId);
              if (context.mounted) {
                await context.read<AccountProvider>().loadAccounts(userId);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppTheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}
