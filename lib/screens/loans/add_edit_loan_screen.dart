import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/loan_interest_calculator.dart';
import '../../utils/validators.dart';
import '../../widgets/money_amount_input.dart';

class AddEditLoanScreen extends StatefulWidget {
  final Loan? loan;
  final String? initialType;

  const AddEditLoanScreen({super.key, this.loan, this.initialType});

  @override
  State<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends State<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _personController = TextEditingController();

  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  final _noteController = TextEditingController();

  final _interestController = TextEditingController();

  String _type = 'borrow';

  DateTime _startDate = DateTime.now();

  DateTime? _dueDate;

  int? _accountId;

  bool get _isEditMode => widget.loan != null;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _amountController.addListener(_refreshPreview);
    _interestController.addListener(_refreshPreview);
    final loan = widget.loan;
    if (loan != null) {
      _type = loan.type;
      _personController.text = loan.personName;
      _amountController.text = MoneyAmountInput.formatAmount(loan.amount);
      _interestController.text = loan.interestRate == 0
          ? ''
          : loan.interestRate.toString();
      _noteController.text = loan.note ?? '';
      _startDate = loan.startDate;
      _dueDate = loan.dueDate;
      _accountId = loan.accountId;
    } else {
      if (widget.initialType == 'borrow' || widget.initialType == 'lend') {
        _type = widget.initialType!;
      }
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) _accountId = accounts.first.id;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.removeListener(_refreshPreview);
    _amountController.dispose();
    _amountFocusNode.dispose();
    _noteController.dispose();
    _interestController.removeListener(_refreshPreview);
    _interestController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
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

    if (_dueDate != null && _dueDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'H\u1ea1n tr\u1ea3 kh\u00f4ng \u0111\u01b0\u1ee3c tr\u01b0\u1edbc ng\u00e0y b\u1eaft \u0111\u1ea7u',
          ),
        ),
      );

      return;
    }

    final userId = context.read<AuthProvider>().currentUserId;
    final loanProvider = context.read<LoanProvider>();
    final amount = Validators.parseAmount(_amountController.text);
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final success = _isEditMode
        ? await loanProvider.updateLoan(
            loanId: widget.loan!.id!,
            userId: userId,
            type: _type,
            personName: _personController.text.trim(),
            amount: amount,
            interestRate: double.tryParse(_interestController.text) ?? 0,
            note: note,
            startDate: _startDate,
            dueDate: _dueDate,
            accountId: _accountId!,
          )
        : await loanProvider.addLoan(
            userId: userId,
            type: _type,
            personName: _personController.text.trim(),
            amount: amount,
            interestRate: double.tryParse(_interestController.text) ?? 0,
            note: note,
            startDate: _startDate,
            dueDate: _dueDate,
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
          loanProvider.errorMessage ??
          'Kh\u00f4ng th\u1ec3 l\u01b0u kho\u1ea3n vay';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;

    final theme = Theme.of(context);

    return MoneyAmountKeyboardBackGuard(
      focusNode: _amountFocusNode,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBar: MoneyAmountKeyboardPanel(
          isVisible: _amountFocusNode.hasFocus,
          onKeyPressed: _handleAmountKeyboardKey,
          shouldEvaluate: MoneyAmountInput.needsEvaluation(
            _amountController.text,
          ),
        ),

        appBar: AppBar(
          title: Text(
            _isEditMode ? 'S\u1eeda vay/cho vay' : 'Th\u00eam vay/cho vay',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),

            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing10),
          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                Row(
                  children: [
                    _typeChip('Vay', 'borrow'),
                    const SizedBox(width: AppTheme.spacing4),
                    _typeChip('Cho vay', 'lend'),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing10),
                _label('NGƯỜI VAY/CHO VAY'),
                const SizedBox(height: AppTheme.spacing4),
                TextFormField(
                  controller: _personController,
                  validator: (value) => Validators.entityName(value, 'Tên'),
                  decoration: const InputDecoration(
                    hintText: 'VD: Nguyễn Văn B',
                  ),
                ),
                const SizedBox(height: AppTheme.spacing10),
                _label('SỐ TIỀN'),
                const SizedBox(height: AppTheme.spacing4),
                MoneyAmountField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  validator: Validators.amount,
                ),
                const SizedBox(height: AppTheme.spacing10),
                _label('Lãi suất (%/năm)'.toUpperCase()),
                const SizedBox(height: AppTheme.spacing4),
                TextFormField(
                  controller: _interestController,

                  keyboardType: TextInputType.number,

                  validator: Validators.interestRate,

                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                _metadataNote(context),
                if (_interestPreview(context) case final preview?) ...[
                  const SizedBox(height: AppTheme.spacing6),
                  preview,
                ],
                const SizedBox(height: AppTheme.spacing10),
                _label('TÀI KHOẢN LIÊN KẾT'),
                const SizedBox(height: AppTheme.spacing4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,

                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),

                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _accountId,

                      dropdownColor: theme.cardColor,

                      isExpanded: true,
                      hint: const Text('Chọn tài khoản'),
                      items: accounts
                          .map(
                            (account) => DropdownMenuItem(
                              value: account.id,
                              child: Text(account.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _accountId = value),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          _label('NGÀY BẮT ĐẦU'),
                          const SizedBox(height: AppTheme.spacing4),
                          _datePicker(
                            _startDate,
                            (date) => setState(() => _startDate = date),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          _label('HẠN TRẢ'),
                          const SizedBox(height: AppTheme.spacing4),
                          _datePicker(
                            _dueDate,
                            (date) => setState(() => _dueDate = date),
                            canClear: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing10),
                _label('GHI CHÚ'),
                const SizedBox(height: AppTheme.spacing4),
                TextFormField(
                  controller: _noteController,

                  maxLines: 2,

                  validator: Validators.note,

                  decoration: const InputDecoration(hintText: 'Tùy chọn'),
                ),
                const SizedBox(height: AppTheme.spacing12),
                SizedBox(
                  height: AppTheme.spacing24 + AppTheme.spacing2,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(
                      _isEditMode ? 'L\u01b0u thay \u0111\u1ed5i' : 'L\u01b0u',
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

  Widget _metadataNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        'Lãi được tính hằng ngày trên gốc còn lại. Khi thanh toán, hệ thống ưu tiên trừ lãi trước rồi mới trừ gốc.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget? _interestPreview(BuildContext context) {
    final amount = Validators.parseAmount(_amountController.text);
    if (amount <= 0) return null;

    final rate = double.tryParse(_interestController.text.trim()) ?? 0;
    final now = DateTime.now();
    final previewLoan = Loan(
      userId: context.read<AuthProvider>().currentUserId,
      type: _type,
      personName: _personController.text.trim().isEmpty
          ? 'preview'
          : _personController.text.trim(),
      amount: amount,
      remainingAmount: amount,
      interestRate: rate,
      startDate: _startDate,
      createdAt: now,
      updatedAt: now,
    );
    final breakdown = LoanInterestCalculator.calculate(
      loan: previewLoan,
      payments: const [],
      asOf: now,
    );
    final totalLabel = _type == 'borrow'
        ? 'Tổng còn phải trả'
        : 'Tổng còn phải thu';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          _previewRow(
            context,
            'Ước tính lãi đến hôm nay',
            Formatters.currency(breakdown.interestOutstanding),
          ),
          const SizedBox(height: AppTheme.spacing4),
          _previewRow(
            context,
            totalLabel,
            Formatters.currency(breakdown.totalOutstanding),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing6),
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

  void _refreshPreview() {
    if (!mounted) return;
    setState(() {});
  }

  Widget _typeChip(String label, String value) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing10,
          vertical: AppTheme.spacing6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: selected ? AppTheme.onPrimary : AppTheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );

  Widget _datePicker(
    DateTime? date,
    ValueChanged<DateTime> onPicked, {
    bool canClear = false,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,

          initialDate: date ?? DateTime.now(),

          firstDate: DateTime(2020),

          lastDate: DateTime(2035),
        );
        if (picked != null) onPicked(picked);
      },

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing8,
          vertical: AppTheme.spacing6,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,

          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),

        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: AppTheme.spacing8,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spacing4),
            Expanded(
              child: Text(
                date != null ? Formatters.date(date) : 'Chọn ngày',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: date != null ? AppTheme.onSurface : AppTheme.outline,
                ),
              ),
            ),
            if (canClear && date != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: const Icon(
                  Icons.close_rounded,
                  size: AppTheme.spacing8,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
          ],
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
}
