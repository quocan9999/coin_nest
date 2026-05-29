import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/loan.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class PaymentScreen extends StatefulWidget {
  final Loan loan;

  const PaymentScreen({super.key, required this.loan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _paymentDate;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now();
    _accountId = widget.loan.accountId;
    if (_accountId == null) {
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) _accountId = accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vui lòng chọn tài khoản')));
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
      if (mounted) Navigator.pop(context, true);
    } else {
      final message =
          context.read<LoanProvider>().errorMessage ??
          'Không thể ghi nhận thanh toán';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    final color = widget.loan.type == 'borrow'
        ? AppTheme.colors(context).expense
        : AppTheme.colors(context).warning;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text(
          widget.loan.type == 'borrow'
              ? 'Thanh toán khoản vay'
              : 'Ghi nhận thu nợ',
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.loan.personName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Còn lại: ${Formatters.currency(widget.loan.remainingAmount)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _label('SỐ TIỀN THANH TOÁN'),
              SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: '0', suffixText: 'đ'),
                validator: (value) {
                  final base = Validators.amount(value);
                  if (base != null) return base;
                  final amount = Validators.parseAmount(value ?? '');
                  if (amount > widget.loan.remainingAmount) {
                    return 'Số tiền không được vượt quá dư nợ còn lại';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _label('NGÀY THANH TOÁN'),
              SizedBox(height: 8),
              _datePicker(),
              SizedBox(height: 20),
              _label('TÀI KHOẢN'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
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
              SizedBox(height: 20),
              _label('GHI CHÚ'),
              SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                validator: Validators.note,
                decoration: InputDecoration(hintText: 'Tùy chọn'),
              ),
              SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('Lưu thanh toán'),
                ),
              ),
            ],
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

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async {
        final today = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _paymentDate.isAfter(today) ? today : _paymentDate,
          firstDate: widget.loan.startDate,
          lastDate: today,
        );
        if (picked != null) setState(() => _paymentDate = picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.colors(context).input,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.colors(context).textSecondary,
            ),
            SizedBox(width: 8),
            Text(
              Formatters.date(_paymentDate),
              style: TextStyle(color: AppTheme.colors(context).textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
