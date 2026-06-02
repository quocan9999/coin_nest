import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/money_amount_input.dart';

class PaymentScreen extends StatefulWidget {
  final Loan loan;

  const PaymentScreen({super.key, required this.loan});

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

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _paymentDate = DateTime.now();

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

    final success = await context.read<LoanProvider>().recordPayment(
      widget.loan.id!,
      Validators.parseAmount(_amountController.text),
      userId,
      paymentDate: _paymentDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
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
            widget.loan.type == 'borrow'
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
                        'C\u00f2n l\u1ea1i: ${Formatters.currency(widget.loan.remainingAmount)}',
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

                    if (amount > widget.loan.remainingAmount) {
                      return 'Số tiền không được vượt quá dư nợ còn lại';
                    }

                    return null;
                  },
                ),

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

                    child: const Text('L\u01b0u thanh to\u00e1n'),
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
