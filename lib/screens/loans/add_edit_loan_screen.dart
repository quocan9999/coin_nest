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
      ).showSnackBar(SnackBar(content: Text('Vui lòng chọn tài khoản')));
      return;
    }
    if (_dueDate != null && _dueDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hạn trả không được trước ngày bắt đầu')),
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
      final message = loanProvider.errorMessage ?? 'Không thể lưu khoản vay';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa vay/cho vay' : 'Thêm vay/cho vay'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacing10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _typeChip('Vay', 'borrow'),
                  SizedBox(width: AppTheme.spacing4),
                  _typeChip('Cho vay', 'lend'),
                ],
              ),
              SizedBox(height: AppTheme.spacing10),
              _label('NGƯỜI VAY/CHO VAY'),
              SizedBox(height: AppTheme.spacing4),
              TextFormField(
                controller: _personController,
                validator: (value) => Validators.entityName(value, 'Tên'),
                decoration: InputDecoration(hintText: 'VD: Nguyễn Văn B'),
              ),
              SizedBox(height: AppTheme.spacing10),
              _label('SỐ TIỀN'),
              SizedBox(height: AppTheme.spacing4),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: Validators.amount,
                decoration: InputDecoration(hintText: '0', suffixText: 'đ'),
              ),
              SizedBox(height: AppTheme.spacing10),
              _label('LÃI SUẤT (%/NĂM)'),
              SizedBox(height: AppTheme.spacing4),
              TextFormField(
                controller: _interestController,
                keyboardType: TextInputType.number,
                validator: Validators.interestRate,
                decoration: InputDecoration(hintText: '0', suffixText: '%'),
              ),
              SizedBox(height: AppTheme.spacing4),
              _metadataNote(context),
              SizedBox(height: AppTheme.spacing10),
              _label('TÀI KHOẢN LIÊN KẾT'),
              SizedBox(height: AppTheme.spacing4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppTheme.colors(context).input,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _accountId,
                    isExpanded: true,
                    hint: Text('Chọn tài khoản'),
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
              SizedBox(height: AppTheme.spacing10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('NGÀY BẮT ĐẦU'),
                        SizedBox(height: AppTheme.spacing4),
                        _datePicker(
                          _startDate,
                          (date) => setState(() => _startDate = date),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('HẠN TRẢ'),
                        SizedBox(height: AppTheme.spacing4),
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
              SizedBox(height: AppTheme.spacing10),
              _label('GHI CHÚ'),
              SizedBox(height: AppTheme.spacing4),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                validator: Validators.note,
                decoration: InputDecoration(hintText: 'Tùy chọn'),
              ),
              SizedBox(height: AppTheme.spacing12),
              SizedBox(
                height: AppTheme.spacing24 + AppTheme.spacing2,
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
      padding: EdgeInsets.all(AppTheme.spacing6),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).input,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        'Lãi suất chỉ được lưu để ghi chú, app chưa tự tính hoặc cộng lãi vào dư nợ.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.colors(context).textSecondary,
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing10,
          vertical: AppTheme.spacing6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.colors(context).primary
              : AppTheme.colors(context).input,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppTheme.onPrimary
                : AppTheme.colors(context).textPrimary,
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
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing8,
          vertical: AppTheme.spacing6,
        ),
        decoration: BoxDecoration(
          color: AppTheme.colors(context).input,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: AppTheme.spacing8,
              color: AppTheme.colors(context).textSecondary,
            ),
            SizedBox(width: AppTheme.spacing4),
            Expanded(
              child: Text(
                date != null ? Formatters.date(date) : 'Chọn ngày',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: date != null
                      ? AppTheme.colors(context).textPrimary
                      : AppTheme.colors(context).textDisabled,
                ),
              ),
            ),
            if (canClear && date != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: Icon(
                  Icons.close_rounded,
                  size: AppTheme.spacing8,
                  color: AppTheme.colors(context).textSecondary,
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
