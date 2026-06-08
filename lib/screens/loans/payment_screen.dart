import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../models/loan_payment.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/loan_interest_calculator.dart';
import '../../utils/validators.dart';
import '../../widgets/money_amount_input.dart';

class PaymentScreen extends StatefulWidget {
  final Loan loan;
  final LoanPayment? payment;

  const PaymentScreen({super.key, required this.loan, this.payment});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  final _noteController = TextEditingController();

  late DateTime _paymentDate;

  int? _accountId;

  bool get _isEditMode => widget.payment != null;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _amountController.addListener(_refreshAllocationPreview);

    final payment = widget.payment;
    if (payment != null) {
      _amountController.text = MoneyAmountInput.formatAmount(payment.amount);
      _noteController.text = payment.note ?? '';
      _paymentDate = payment.paymentDate;
    } else {
      _paymentDate = DateTime.now();
    }

    _accountId = widget.loan.accountId;

    if (_accountId == null) {
      final accounts = context.read<AccountProvider>().accounts;

      if (accounts.isNotEmpty) {
        _accountId = accounts.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_refreshAllocationPreview);
    _amountController.dispose();
    _amountFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_finalizeAmountExpression(showError: true)) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui l\u00f2ng ch\u1ecdn t\u00e0i kho\u1ea3n'),
        ),
      );
      return;
    }

    final userId = context.read<AuthProvider>().currentUserId;

    final amount = Validators.parseAmount(_amountController.text);
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final loanProvider = context.read<LoanProvider>();
    final success = _isEditMode
        ? await loanProvider.updatePayment(
            widget.payment!,
            amount,
            userId,
            paymentDate: _paymentDate,
            note: note,
            accountId: _accountId,
          )
        : await loanProvider.recordPayment(
            widget.loan.id!,
            amount,
            userId,
            paymentDate: _paymentDate,
            note: note,
            accountId: _accountId,
          );

    if (!mounted) return;

    if (success) {
      await context.read<AccountProvider>().loadAccounts(userId);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      final message =
          context.read<LoanProvider>().errorMessage ??
          'Kh\u00f4ng th\u1ec3 ghi nh\u1eadn thanh to\u00e1n';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accounts = context.watch<AccountProvider>().accounts;

    final color = widget.loan.type == 'borrow'
        ? AppTheme.tertiary
        : AppTheme.loanColor;

    return MoneyAmountKeyboardBackGuard(
      focusNode: _amountFocusNode,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        bottomNavigationBar: MoneyAmountKeyboardPanel(
          isVisible: _amountFocusNode.hasFocus,
          onKeyPressed: _handleAmountKeyboardKey,
          shouldEvaluate: MoneyAmountInput.needsEvaluation(
            _amountController.text,
          ),
        ),

        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: true,

          title: Text(
            _isEditMode
                ? 'Chi tiết thanh toán'
                : widget.loan.type == 'borrow'
                ? 'Thanh to\u00e1n kho\u1ea3n vay'
                : 'Ghi nh\u1eadn thu n\u1ee3',
          ),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                // CARD INFO
                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: color.withAlpha(16),

                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        widget.loan.personName,

                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        widget.loan.type == 'borrow'
                            ? 'Còn phải trả: ${Formatters.currency(widget.loan.totalOutstanding)}'
                            : 'Còn phải thu: ${Formatters.currency(widget.loan.totalOutstanding)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SỐ TIỀN
                _label('SỐ TIỀN THANH TOÁN'),

                const SizedBox(height: 8),

                MoneyAmountField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  validator: (value) {
                    final base = Validators.amount(value);

                    if (base != null) {
                      return base;
                    }

                    final amount = Validators.parseAmount(value ?? '');

                    if (amount > _maximumEditableAmount) {
                      return 'Số tiền không được vượt quá dư nợ còn lại';
                    }

                    return null;
                  },
                ),

                if (_allocationPreview(context) case final preview?) ...[
                  const SizedBox(height: 12),
                  preview,
                ],

                const SizedBox(height: 20),

                // NGÀY THANH TOÁN
                _label('NGÀY THANH TOÁN'),

                const SizedBox(height: 8),

                _datePicker(),

                const SizedBox(height: 20),

                // TÀI KHOẢN
                _label('TÀI KHOẢN'),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,

                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),

                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _accountId,

                      isExpanded: true,

                      dropdownColor: colorScheme.surface,

                      hint: const Text('Chọn tài khoản'),

                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),

                      onChanged: (v) => setState(() => _accountId = v),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // GHI CHÚ
                _label('GHI CHÚ'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _noteController,

                  maxLines: 2,

                  validator: Validators.note,

                  decoration: const InputDecoration(hintText: 'Tùy chọn'),
                ),

                const SizedBox(height: 28),

                // BUTTON
                SizedBox(
                  height: 52,

                  child: ElevatedButton(
                    onPressed: _submit,

                    child: Text(
                      _isEditMode ? 'Lưu thay đổi' : 'L\u01b0u thanh to\u00e1n',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAmountKeyboardKey(MoneyAmountKeyboardKey key) {
    MoneyAmountInput.handleKey(
      context: context,
      controller: _amountController,
      focusNode: _amountFocusNode,
      key: key,
      refresh: () => setState(() {}),
    );
  }

  double get _maximumEditableAmount {
    final currentPaymentAmount = widget.payment?.amount ?? 0;
    return widget.loan.totalOutstanding + currentPaymentAmount;
  }

  Widget? _allocationPreview(BuildContext context) {
    final amount = Validators.parseAmount(_amountController.text);
    if (amount <= 0) return null;

    final currentPayment = widget.payment;
    final breakdown = LoanInterestBreakdown(
      principalAmount: widget.loan.principalAmount,
      principalRemaining:
          widget.loan.principalRemaining +
          (currentPayment?.principalAmount ?? 0),
      interestAccrued: widget.loan.interestAccrued,
      interestPaid:
          widget.loan.interestPaid - (currentPayment?.interestAmount ?? 0),
      interestOutstanding:
          widget.loan.interestOutstanding +
          (currentPayment?.interestAmount ?? 0),
    );
    final allocation = LoanInterestCalculator.allocatePayment(
      amount: amount,
      breakdown: breakdown,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allocation.interestAmount > 0) ...[
            _allocationRow(
              context,
              'Trừ lãi',
              Formatters.currency(allocation.interestAmount),
            ),
            const SizedBox(height: AppTheme.spacing4),
          ],
          _allocationRow(
            context,
            'Trừ gốc',
            Formatters.currency(allocation.principalAmount),
          ),
        ],
      ),
    );
  }

  Widget _allocationRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _refreshAllocationPreview() {
    if (!mounted) return;
    setState(() {});
  }

  bool _finalizeAmountExpression({required bool showError}) {
    return MoneyAmountInput.finalizeExpression(
      context: context,
      controller: _amountController,
      refresh: () => setState(() {}),
      showError: showError,
    );
  }

  Widget _label(String text) {
    return Text(
      text,

      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _datePicker() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () async {
        final today = DateTime.now();

        final picked = await showDatePicker(
          context: context,

          initialDate: _paymentDate.isAfter(today) ? today : _paymentDate,

          firstDate: widget.loan.startDate,

          lastDate: today,
        );

        if (picked != null) {
          setState(() => _paymentDate = picked);
        }
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,

          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),

        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),

            const SizedBox(width: 8),

            Text(
              Formatters.date(_paymentDate),

              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
