import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/account_provider.dart';

import '../../theme/app_theme.dart';

import '../../utils/validators.dart';
import '../../utils/formatters.dart';

class AddEditLoanScreen extends StatefulWidget {
  const AddEditLoanScreen({super.key});

  @override
  State<AddEditLoanScreen> createState() =>
      _AddEditLoanScreenState();
}

class _AddEditLoanScreenState
    extends State<AddEditLoanScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _personController =
      TextEditingController();

  final _amountController =
      TextEditingController();

  final _noteController =
      TextEditingController();

  final _interestController =
      TextEditingController();

  String _type = 'borrow';

  DateTime _startDate =
      DateTime.now();

  DateTime? _dueDate;

  int? _accountId;

  @override
  void initState() {
    super.initState();

    final accounts =
        context
            .read<AccountProvider>()
            .accounts;

    if (accounts.isNotEmpty) {
      _accountId = accounts.first.id;
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
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_accountId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn tài khoản',
          ),
        ),
      );

      return;
    }

    if (_dueDate != null &&
        _dueDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Hạn trả không được trước ngày bắt đầu',
          ),
        ),
      );

      return;
    }

    final userId =
        context
            .read<AuthProvider>()
            .currentUserId;

    final success =
        await context
            .read<LoanProvider>()
            .addLoan(
              userId: userId,
              type: _type,
              personName:
                  _personController.text
                      .trim(),
              amount:
                  Validators.parseAmount(
                _amountController.text,
              ),
              interestRate:
                  double.tryParse(
                        _interestController
                            .text,
                      ) ??
                      0,
              note:
                  _noteController
                          .text
                          .trim()
                          .isEmpty
                      ? null
                      : _noteController.text
                          .trim(),
              startDate: _startDate,
              dueDate: _dueDate,
              accountId: _accountId,
            );

    if (!mounted) return;

    if (success) {
      await context
          .read<AccountProvider>()
          .loadAccounts(userId);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      final message =
          context
              .read<LoanProvider>()
              .errorMessage ??
          'Không thể lưu khoản vay';

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        context
            .watch<AccountProvider>()
            .accounts;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor:
            theme.scaffoldBackgroundColor,

        title:
            const Text('Thêm vay/cho vay'),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
          ),

          onPressed: () =>
              Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

            children: [
              // Type
              Row(
                children: [
                  _typeChip(
                    context,
                    'Vay',
                    'borrow',
                  ),

                  const SizedBox(width: 8),

                  _typeChip(
                    context,
                    'Cho vay',
                    'lend',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _label(
                context,
                'NGƯỜI VAY/CHO VAY',
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _personController,

                validator:
                    (v) =>
                        Validators
                            .entityName(
                  v,
                  'Tên',
                ),

                decoration:
                    const InputDecoration(
                  hintText:
                      'VD: Nguyễn Văn B',
                ),
              ),

              const SizedBox(height: 20),

              _label(context, 'SỐ TIỀN'),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _amountController,

                keyboardType:
                    TextInputType.number,

                validator:
                    Validators.amount,

                decoration:
                    const InputDecoration(
                  hintText: '0',
                  suffixText: 'đ',
                ),
              ),

              const SizedBox(height: 20),

              _label(
                context,
                'LÃI SUẤT (%/NĂM)',
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _interestController,

                keyboardType:
                    TextInputType.number,

                validator:
                    Validators.interestRate,

                decoration:
                    const InputDecoration(
                  hintText: '0',
                  suffixText: '%',
                ),
              ),

              const SizedBox(height: 20),

              _label(
                context,
                'TÀI KHOẢN LIÊN KẾT',
              ),

              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

                decoration: BoxDecoration(
                  color: theme.cardColor,

                  borderRadius:
                      BorderRadius.circular(
                    AppTheme.radiusMd,
                  ),
                ),

                child:
                    DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _accountId,

                    dropdownColor:
                        theme.cardColor,

                    isExpanded: true,

                    hint: const Text(
                      'Chọn tài khoản',
                    ),

                    items:
                        accounts
                            .map(
                              (a) =>
                                  DropdownMenuItem(
                                    value:
                                        a.id,

                                    child: Text(
                                      a.name,
                                    ),
                                  ),
                            )
                            .toList(),

                    onChanged:
                        (v) => setState(
                      () =>
                          _accountId = v,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        _label(
                          context,
                          'NGÀY BẮT ĐẦU',
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        _datePicker(
                          context,
                          _startDate,
                          (d) => setState(
                            () =>
                                _startDate =
                                    d,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        _label(
                          context,
                          'HẠN TRẢ',
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        _datePicker(
                          context,
                          _dueDate,
                          (d) => setState(
                            () =>
                                _dueDate =
                                    d,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _label(context, 'GHI CHÚ'),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _noteController,

                maxLines: 2,

                validator:
                    Validators.note,

                decoration:
                    const InputDecoration(
                  hintText: 'Tùy chọn',
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: _save,

                  child:
                      const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    final sel = _type == value;

    return GestureDetector(
      onTap:
          () => setState(
            () => _type = value,
          ),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color:
              sel
                  ? AppTheme.primary
                  : theme.cardColor,

          borderRadius:
              BorderRadius.circular(
            AppTheme.radiusFull,
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color:
                sel
                    ? AppTheme.onPrimary
                    : theme
                        .colorScheme
                        .onSurface,

            fontWeight:
                sel
                    ? FontWeight.w600
                    : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _label(
    BuildContext context,
    String t,
  ) {
    return Text(
      t,

      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(
            fontWeight:
                FontWeight.w600,

            letterSpacing: 0.8,

            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
    );
  }

  Widget _datePicker(
    BuildContext context,
    DateTime? date,
    ValueChanged<DateTime> onPicked,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () async {
        final d =
            await showDatePicker(
          context: context,

          initialDate:
              date ?? DateTime.now(),

          firstDate:
              DateTime(2020),

          lastDate:
              DateTime(2035),
        );

        if (d != null) {
          onPicked(d);
        }
      },

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration: BoxDecoration(
          color: theme.cardColor,

          borderRadius:
              BorderRadius.circular(
            AppTheme.radiusMd,
          ),
        ),

        child: Row(
          children: [
            Icon(
              Icons
                  .calendar_today_outlined,

              size: 16,

              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),

            const SizedBox(width: 8),

            Text(
              date != null
                  ? Formatters.date(date)
                  : 'Chọn ngày',

              style: TextStyle(
                color:
                    date != null
                        ? theme
                            .colorScheme
                            .onSurface
                        : theme
                            .colorScheme
                            .outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}