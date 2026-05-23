import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class AddEditLoanScreen extends StatefulWidget {
  final Loan? loan;

  const AddEditLoanScreen({super.key, this.loan});

  @override
  State<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends State<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
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
    final loan = widget.loan;
    if (loan != null) {
      _type = loan.type;
      _personController.text = loan.personName;
      _amountController.text = _formatInputAmount(loan.amount);
      _interestController.text = loan.interestRate == 0
          ? ''
          : loan.interestRate.toString();
      _noteController.text = loan.note ?? '';
      _startDate = loan.startDate;
      _dueDate = loan.dueDate;
      _accountId = loan.accountId;
    } else {
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) _accountId = accounts.first.id;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tài khoản')));
      return;
    }
    if (_dueDate != null && _dueDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hạn trả không được trước ngày bắt đầu')),
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
      if (mounted) Navigator.pop(context, true);
    } else {
      final message =
          loanProvider.errorMessage ?? 'Không thể lưu khoản vay';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa vay/cho vay' : 'Thêm vay/cho vay'),
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
              Row(
                children: [
                  _typeChip('Vay', 'borrow'),
                  const SizedBox(width: 8),
                  _typeChip('Cho vay', 'lend'),
                ],
              ),
              const SizedBox(height: 20),
              _label('NGƯỜI VAY/CHO VAY'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _personController,
                validator: (value) => Validators.entityName(value, 'Tên'),
                decoration: const InputDecoration(hintText: 'VD: Nguyễn Văn B'),
              ),
              const SizedBox(height: 20),
              _label('SỐ TIỀN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: Validators.amount,
                decoration: const InputDecoration(
                  hintText: '0',
                  suffixText: 'đ',
                ),
              ),
              const SizedBox(height: 20),
              _label('LÃI SUẤT (%/NĂM)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _interestController,
                keyboardType: TextInputType.number,
                validator: Validators.interestRate,
                decoration: const InputDecoration(
                  hintText: '0',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 8),
              _metadataNote(context),
              const SizedBox(height: 20),
              _label('TÀI KHOẢN LIÊN KẾT'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _accountId,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('NGÀY BẮT ĐẦU'),
                        const SizedBox(height: 8),
                        _datePicker(
                          _startDate,
                          (date) => setState(() => _startDate = date),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('HẠN TRẢ'),
                        const SizedBox(height: 8),
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
              const SizedBox(height: 20),
              _label('GHI CHÚ'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                validator: Validators.note,
                decoration: const InputDecoration(hintText: 'Tùy chọn'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditMode ? 'Lưu thay đổi' : 'Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metadataNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        'Lãi suất chỉ được lưu để ghi chú, app chưa tự tính hoặc cộng lãi vào dư nợ.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
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
                  size: 16,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatInputAmount(double value) {
    final raw = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }
}
