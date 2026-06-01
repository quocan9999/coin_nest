import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';

import '../../models/category.dart';
import '../../models/receipt_scan_result.dart';
import '../../models/transaction_model.dart';

import '../../theme/app_theme.dart';

import '../../utils/validators.dart';
import '../../utils/category_icons.dart';
import '../../utils/formatters.dart';
import '../loans/add_edit_loan_screen.dart';
import '../loans/loan_list_screen.dart';
import 'receipt_scan_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  final _noteController = TextEditingController();

  final _amountFocusNode = FocusNode();

  int? _selectedCategoryId;
  int? _selectedAccountId;
  int? _selectedToAccountId;

  DateTime _selectedDate = DateTime.now();

  int _previousTabIndex = 0;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      final txn = widget.transaction!;
      if (txn.isLoanLinked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showLoanLinkedMessage();
          Navigator.pop(context);
        });
      }

      String initialAmount = txn.amount.toInt().toString();

      String formatted = '';

      int count = 0;

      for (int i = initialAmount.length - 1; i >= 0; i--) {
        if (count != 0 && count % 3 == 0) {
          formatted = '.$formatted';
        }

        formatted = initialAmount[i] + formatted;

        count++;
      }

      _amountController.text = formatted;

      _noteController.text = txn.note ?? '';

      _selectedCategoryId = txn.categoryId;

      _selectedAccountId = txn.accountId;

      _selectedToAccountId = txn.toAccountId;

      _selectedDate = txn.date;

      if (txn.type == 'income') {
        _previousTabIndex = 1;
      } else if (txn.type == 'transfer') {
        _previousTabIndex = 2;
      }
    } else {
      final accounts = context.read<AccountProvider>().accounts;

      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
      }
    }

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _previousTabIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }

      if (_tabController.index != _previousTabIndex) {
        setState(() {
          _selectedCategoryId = null;
          _previousTabIndex = _tabController.index;
        });
      }
    });

    _amountFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountFocusNode.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _currentType {
    switch (_tabController.index) {
      case 0:
        return 'expense';

      case 1:
        return 'income';

      case 2:
        return 'transfer';

      default:
        return 'expense';
    }
  }

  bool get isEditMode => widget.transaction != null;
  bool get _isLoanLinkedEdit =>
      widget.transaction != null && widget.transaction!.isLoanLinked;

  // DIALOG XÁC NHẬN
  void _showConfirmDialog({
    required String message,
    required VoidCallback onConfirm,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,

        title: const Text(
          'Thông báo',

          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        content: Text(message),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: Text(
              'Không',

              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);

              onConfirm();
            },

            child: const Text(
              'Có',

              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // SAVE
  Future<void> _executeSave() async {
    if (_isLoanLinkedEdit) {
      _showLoanLinkedMessage();
      return;
    }

    final userId = context.read<AuthProvider>().currentUserId;
    bool success;

    if (isEditMode) {
      success = await context.read<TransactionProvider>().updateTransaction(
        txnId: widget.transaction!.id!,

        userId: userId,

        accountId: _selectedAccountId!,

        toAccountId: _currentType == 'transfer' ? _selectedToAccountId : null,

        categoryId: _selectedCategoryId,

        type: _currentType,

        amount: Validators.parseAmount(_amountController.text),

        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),

        date: _selectedDate,

        time: widget.transaction!.time ?? Formatters.time(DateTime.now()),

        createdAt: widget.transaction!.createdAt,
      );
    } else {
      success = await context.read<TransactionProvider>().addTransaction(
        userId: userId,

        accountId: _selectedAccountId!,

        toAccountId: _currentType == 'transfer' ? _selectedToAccountId : null,

        categoryId: _selectedCategoryId,

        type: _currentType,

        amount: Validators.parseAmount(_amountController.text),

        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),

        date: _selectedDate,

        time: Formatters.time(DateTime.now()),
      );
    }

    if (!mounted) return;

    if (success) {
      await context.read<AccountProvider>().loadAccounts(userId);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _save() async {
    if (_isLoanLinkedEdit) {
      _showLoanLinkedMessage();
      return;
    }

    if (!_finalizeAmountExpression(showError: true)) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tài khoản')));
      return;
    }

    // --- BỔ SUNG CÁC RÀNG BUỘC CHO CHUYỂN KHOẢN ---
    if (_currentType == 'transfer') {
      final accProv = context.read<AccountProvider>();

      // Ràng buộc 1: Phải có ít nhất 2 tài khoản trong hệ thống
      if (accProv.accounts.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần ít nhất 2 tài khoản để thực hiện chuyển khoản'),
          ),
        );
        return;
      }

      // Ràng buộc 2: Phải chọn tài khoản nhận
      if (_selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn đến tài khoản')),
        );
        return;
      }

      // Ràng buộc 3: Hai tài khoản không được trùng nhau
      if (_selectedAccountId == _selectedToAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chọn hai tài khoản giống nhau'),
          ),
        );
        return;
      }
    }
    // ----------------------------------------------

    if (isEditMode) {
      _showConfirmDialog(
        message:
            'Chú ý! Dữ liệu bị thay đổi sẽ không thể khôi phục lại được. Bạn có muốn tiếp tục?',

        onConfirm: _executeSave,
      );
    } else {
      await _executeSave();
    }
  }

  // DELETE
  Future<void> _executeDelete() async {
    if (_isLoanLinkedEdit) {
      _showLoanLinkedMessage();
      return;
    }

    final userId = context.read<AuthProvider>().currentUserId;
    final success = await context.read<TransactionProvider>().deleteTransaction(
      widget.transaction!.id!,
      userId,
    );

    if (!mounted) return;

    if (success) {
      await context.read<AccountProvider>().loadAccounts(userId);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _delete() async {
    if (!isEditMode) return;
    if (_isLoanLinkedEdit) {
      _showLoanLinkedMessage();
      return;
    }

    _showConfirmDialog(
      message:
          'Chú ý! Dữ liệu bị xoá sẽ không thể khôi phục lại được. Bạn có muốn tiếp tục?',

      onConfirm: _executeDelete,
    );
  }

  bool _isLoanWorkflowCategory(Category category) {
    if (_currentType == 'expense') {
      return category.name == 'Cho mượn' || category.name == 'Trả nợ';
    }

    if (_currentType == 'income') {
      return category.name == 'Vay mượn' || category.name == 'Thu nợ';
    }

    return false;
  }

  bool _isLoanCreationCategory(Category category) {
    return category.name == 'Cho mượn' || category.name == 'Vay mượn';
  }

  String _initialLoanTypeForCategory(Category category) {
    return category.name == 'Cho mượn' || category.name == 'Thu nợ'
        ? 'lend'
        : 'borrow';
  }

  Future<void> _handleCategoryTap(Category category) async {
    final isSelected = _selectedCategoryId == category.id;
    if (isSelected) {
      setState(() => _selectedCategoryId = null);
      return;
    }

    // Các hạng mục vay/cho vay phải đi qua domain khoản vay để số dư,
    // lịch sử thanh toán và linked transaction luôn đồng bộ.
    if (_isLoanWorkflowCategory(category)) {
      await _showLoanWorkflowDialog(category);
      return;
    }

    setState(() => _selectedCategoryId = category.id);
  }

  Future<void> _showLoanWorkflowDialog(Category category) async {
    final isCreation = _isLoanCreationCategory(category);
    final title = isCreation
        ? 'Tạo khoản vay/cho vay'
        : 'Chọn khoản vay/cho vay';
    final message = isCreation
        ? 'Bạn đang chọn hạng mục "${category.name}" để phát sinh khoản vay/cho vay mới. '
            'Bạn có muốn chuyển sang tạo khoản vay/cho vay không?'
        : 'Bạn đang chọn hạng mục "${category.name}" để thanh toán khoản vay/cho vay đã có. '
            'Bạn có muốn chuyển sang danh sách khoản vay/cho vay để chọn khoản cần xử lý không?';

    final shouldNavigate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chuyển sang'),
          ),
        ],
      ),
    );

    if (!mounted || shouldNavigate != true) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isCreation
            ? AddEditLoanScreen(
                initialType: _initialLoanTypeForCategory(category),
              )
            : LoanListScreen(
                initialType: _initialLoanTypeForCategory(category),
                selectForPayment: true,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    final catProv = context.watch<CategoryProvider>();

    final accProv = context.watch<AccountProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,

      bottomNavigationBar: _buildReceiptScanAccessory(theme),

      appBar: AppBar(
        backgroundColor: colorScheme.surface,

        elevation: 0,

        centerTitle: true,

        title: Text(isEditMode ? 'Sửa ghi chép' : 'Ghi chép giao dịch'),

        leading: IconButton(
          icon: const Icon(Icons.close_rounded),

          onPressed: () => Navigator.pop(context),
        ),

        bottom: TabBar(
          controller: _tabController,

          onTap: (index) {
            if (_previousTabIndex != index) {
              setState(() {
                _selectedCategoryId = null;

                _previousTabIndex = index;
              });
            }
          },

          tabs: const [
            Tab(text: 'Chi tiêu'),
            Tab(text: 'Thu nhập'),
            Tab(text: 'Chuyển khoản'),
          ],

          labelColor: AppTheme.primary,

          unselectedLabelColor: colorScheme.onSurfaceVariant,

          indicatorColor: AppTheme.primary,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // SỐ TIỀN
              _sectionLabel(context, 'SỐ TIỀN'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _amountController,

                focusNode: _amountFocusNode,

                readOnly: true,

                showCursor: true,

                enableInteractiveSelection: false,

                validator: Validators.amount,

                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),

                decoration: const InputDecoration(
                  hintText: '0',
                  suffixText: 'đ',
                ),
              ),

              const SizedBox(height: 20),

              // CATEGORY
              if (_currentType != 'transfer') ...[
                _sectionLabel(context, 'HẠNG MỤC'),

                const SizedBox(height: 8),

                _buildCategoryGrid(
                  _currentType == 'expense'
                      ? catProv.expenseCategories
                      : catProv.incomeCategories,
                ),

                const SizedBox(height: 20),
              ],

              // ACCOUNT
              _sectionLabel(
                context,
                _currentType == 'transfer' ? 'TỪ TÀI KHOẢN' : 'TÀI KHOẢN',
              ),

              const SizedBox(height: 8),

              _buildAccountDropdown(accProv, isSource: true),

              if (_currentType == 'transfer') ...[
                const SizedBox(height: 20),

                _sectionLabel(context, 'ĐẾN TÀI KHOẢN'),

                const SizedBox(height: 8),

                _buildAccountDropdown(accProv, isSource: false),
              ],

              const SizedBox(height: 20),

              // DATE
              _sectionLabel(context, 'NGÀY'),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: _pickDate,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),

                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,

                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,

                        size: 18,

                        color: colorScheme.onSurfaceVariant,
                      ),

                      const SizedBox(width: 12),

                      Text(
                        Formatters.date(_selectedDate),

                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // NOTE
              _sectionLabel(context, 'GHI CHÚ'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _noteController,

                maxLines: 2,

                validator: Validators.note,

                decoration: const InputDecoration(
                  hintText: 'Nhập ghi chú (tùy chọn)',
                ),
              ),

              const SizedBox(height: 28),

              // BUTTON
              if (isEditMode)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,

                        child: OutlinedButton(
                          onPressed: _delete,

                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.tertiary,
                              width: 1.5,
                            ),

                            backgroundColor: colorScheme.surface,

                            foregroundColor: AppTheme.tertiary,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                          ),

                          child: const Text(
                            'Xoá',

                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: SizedBox(
                        height: 52,

                        child: ElevatedButton(
                          onPressed: _save,

                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                          ),

                          child: const Text('Lưu lại'),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 52,

                  child: ElevatedButton(
                    onPressed: _save,

                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                    ),
                    child: const Text('Lưu ghi chép'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,

      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildReceiptScanAccessory(ThemeData theme) {
    final shouldShow = _amountFocusNode.hasFocus && !_isLoanLinkedEdit;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: shouldShow
          ? SafeArea(
              key: const ValueKey('receipt-scan-accessory'),
              top: false,
              child: _AmountKeyboard(
                onScanReceipt: _openReceiptScanner,
                onKeyPressed: _handleAmountKeyboardKey,
                shouldEvaluate: _amountExpressionNeedsEvaluation,
              ),
            )
          : const SizedBox.shrink(key: ValueKey('receipt-scan-hidden')),
    );
  }

  void _handleAmountKeyboardKey(_AmountKeyboardKey key) {
    switch (key.type) {
      case _AmountKeyboardKeyType.digit:
        _appendAmountToken(key.value);
        break;
      case _AmountKeyboardKeyType.operator:
        _appendAmountOperator(key.value);
        break;
      case _AmountKeyboardKeyType.clear:
        setState(() => _amountController.clear());
        break;
      case _AmountKeyboardKeyType.backspace:
        _deleteAmountToken();
        break;
      case _AmountKeyboardKeyType.done:
        if (_amountExpressionNeedsEvaluation) {
          _finalizeAmountExpression(showError: true);
        } else {
          _amountFocusNode.unfocus();
        }
        break;
      case _AmountKeyboardKeyType.spacer:
        break;
    }
  }

  bool get _amountExpressionNeedsEvaluation {
    final rawExpression = _rawAmountExpression();
    return _containsOperator(rawExpression);
  }

  void _appendAmountToken(String token) {
    final rawExpression = _rawAmountExpression();
    final nextExpression = rawExpression == '0' ? token : rawExpression + token;
    _setAmountExpression(nextExpression);
  }

  void _appendAmountOperator(String operator) {
    final rawExpression = _rawAmountExpression();
    if (rawExpression.isEmpty) {
      return;
    }

    final nextExpression = _endsWithOperator(rawExpression)
        ? rawExpression.substring(0, rawExpression.length - 1) + operator
        : rawExpression + operator;

    _setAmountExpression(nextExpression);
  }

  void _deleteAmountToken() {
    final rawExpression = _rawAmountExpression();
    if (rawExpression.isEmpty) {
      return;
    }

    _setAmountExpression(rawExpression.substring(0, rawExpression.length - 1));
  }

  bool _finalizeAmountExpression({required bool showError}) {
    final rawExpression = _rawAmountExpression();
    if (rawExpression.isEmpty || !_containsOperator(rawExpression)) {
      return true;
    }

    final evaluatedAmount = _evaluateAmountExpression(rawExpression);
    if (evaluatedAmount == null || evaluatedAmount <= 0) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biểu thức số tiền không hợp lệ')),
        );
      }
      return false;
    }

    setState(() {
      _amountController.text = _formatAmountForInput(evaluatedAmount);
    });
    return true;
  }

  String _rawAmountExpression() {
    return _amountController.text
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');
  }

  void _setAmountExpression(String expression) {
    setState(() {
      _amountController.text = _formatAmountExpression(expression);
    });
  }

  bool _containsOperator(String expression) {
    return RegExp(r'[+\-*/]').hasMatch(expression);
  }

  bool _endsWithOperator(String expression) {
    return expression.isNotEmpty && RegExp(r'[+\-*/]$').hasMatch(expression);
  }

  String _formatAmountExpression(String expression) {
    final buffer = StringBuffer();
    final currentNumber = StringBuffer();

    void flushNumber() {
      if (currentNumber.isEmpty) {
        return;
      }

      final parsed = int.tryParse(currentNumber.toString());
      buffer.write(
        parsed == null
            ? currentNumber.toString()
            : _formatAmountForInput(parsed),
      );
      currentNumber.clear();
    }

    for (final char in expression.split('')) {
      if (RegExp(r'\d').hasMatch(char)) {
        currentNumber.write(char);
      } else {
        flushNumber();
        buffer.write(_displayOperator(char));
      }
    }

    flushNumber();
    return buffer.toString();
  }

  String _displayOperator(String operator) {
    switch (operator) {
      case '*':
        return ' × ';
      case '/':
        return ' ÷ ';
      case '+':
      case '-':
        return ' $operator ';
      default:
        return operator;
    }
  }

  int? _evaluateAmountExpression(String expression) {
    if (_endsWithOperator(expression)) {
      return null;
    }

    final tokens = RegExp(
      r'\d+|[+\-*/]',
    ).allMatches(expression).map((match) => match.group(0)!).toList();

    if (tokens.isEmpty || tokens.length.isEven) {
      return null;
    }

    final values = <double>[double.parse(tokens.first)];
    final operators = <String>[];

    // Tính trước nhân/chia để bàn phím hoạt động giống máy tính cơ bản.
    for (var i = 1; i < tokens.length; i += 2) {
      final operator = tokens[i];
      final value = double.tryParse(tokens[i + 1]);
      if (value == null) {
        return null;
      }

      if (operator == '*' || operator == '/') {
        if (operator == '/' && value == 0) {
          return null;
        }
        final previous = values.removeLast();
        values.add(operator == '*' ? previous * value : previous / value);
      } else {
        operators.add(operator);
        values.add(value);
      }
    }

    var result = values.first;
    for (var i = 0; i < operators.length; i++) {
      result = operators[i] == '+'
          ? result + values[i + 1]
          : result - values[i + 1];
    }

    if (!result.isFinite || result <= 0) {
      return null;
    }
    return result.round();
  }

  Future<void> _openReceiptScanner() async {
    _amountFocusNode.unfocus();

    final result = await Navigator.push<ReceiptScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScanScreen()),
    );

    if (!mounted || result == null) {
      return;
    }

    await _showReceiptScanResult(result);
  }

  Future<void> _showReceiptScanResult(ReceiptScanResult result) async {
    final action = await showModalBottomSheet<_ReceiptScanAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kết quả scan hoá đơn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số tiền',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing2),
                      Text(
                        Formatters.currency(result.totalAmount.toDouble()),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Ghi chú gợi ý',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing2),
                      Text(
                        result.generatedNote,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pop(context, _ReceiptScanAction.dismiss),
                        child: const Text('Bỏ qua'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(context, _ReceiptScanAction.rescan),
                        child: const Text('Quét lại'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, _ReceiptScanAction.apply),
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    switch (action) {
      case _ReceiptScanAction.apply:
        _applyReceiptScanResult(result);
        break;
      case _ReceiptScanAction.rescan:
        await _openReceiptScanner();
        break;
      case _ReceiptScanAction.dismiss:
      case null:
        break;
    }
  }

  void _applyReceiptScanResult(ReceiptScanResult result) {
    setState(() {
      _amountController.text = _formatAmountForInput(result.totalAmount);

      // Không ghi đè ghi chú người dùng đã nhập để tránh làm mất ngữ cảnh giao dịch.
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = result.generatedNote;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã áp dụng kết quả scan hoá đơn')),
    );
  }

  String _formatAmountForInput(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,

      children: categories.map((cat) {
        final isSelected = _selectedCategoryId == cat.id;

        return GestureDetector(
          onTap: () => _handleCategoryTap(cat),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : colorScheme.surfaceContainerLow,

              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                Icon(
                  CategoryIcons.getIcon(cat.iconName),

                  size: 16,

                  color: isSelected
                      ? Colors.white
                      : CategoryIcons.getColor(cat.iconName),
                ),

                const SizedBox(width: 6),

                Text(
                  cat.name,

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight: FontWeight.w500,

                    color: isSelected ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountDropdown(AccountProvider prov, {required bool isSource}) {
    final colorScheme = Theme.of(context).colorScheme;

    final currentValue = isSource ? _selectedAccountId : _selectedToAccountId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentValue,

          isExpanded: true,

          dropdownColor: colorScheme.surface,

          hint: const Text('Chọn tài khoản'),

          items: prov.accounts
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),

          onChanged: (v) => setState(() {
            if (isSource) {
              _selectedAccountId = v;
            } else {
              _selectedToAccountId = v;
            }
          }),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,

      initialDate: _selectedDate,

      firstDate: DateTime(2020),

      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showLoanLinkedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Giao dịch khoản vay chỉ được chỉnh sửa trong chi tiết khoản vay',
        ),
      ),
    );
  }
}

class _AmountKeyboard extends StatelessWidget {
  static const double _keyHeight = AppTheme.spacing24;
  static const double _keyGap = AppTheme.spacing4;

  final VoidCallback onScanReceipt;
  final ValueChanged<_AmountKeyboardKey> onKeyPressed;
  final bool shouldEvaluate;

  const _AmountKeyboard({
    required this.onScanReceipt,
    required this.onKeyPressed,
    required this.shouldEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing8,
        AppTheme.spacing6,
        AppTheme.spacing8,
        AppTheme.spacing8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: FilledButton.tonalIcon(
              onPressed: onScanReceipt,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Scan hoá đơn'),
            ),
          ),
          const SizedBox(height: AppTheme.spacing6),
          // Keypad dùng từng hàng 4 cột cao cố định để các phím luôn thẳng cột
          // trong bottomNavigationBar và tránh lỗi ràng buộc chiều cao vô hạn.
          _keyboardRow(context, [
            _AmountKeyboardKey.clear(),
            _AmountKeyboardKey.operator('÷'),
            _AmountKeyboardKey.operator('×'),
            _AmountKeyboardKey.backspace(),
          ]),
          _keyboardRow(context, [
            _AmountKeyboardKey.digit('7'),
            _AmountKeyboardKey.digit('8'),
            _AmountKeyboardKey.digit('9'),
            _AmountKeyboardKey.operator('-'),
          ]),
          _keyboardRow(context, [
            _AmountKeyboardKey.digit('4'),
            _AmountKeyboardKey.digit('5'),
            _AmountKeyboardKey.digit('6'),
            _AmountKeyboardKey.operator('+'),
          ]),
          _keyboardRow(context, [
            _AmountKeyboardKey.digit('1'),
            _AmountKeyboardKey.digit('2'),
            _AmountKeyboardKey.digit('3'),
            _AmountKeyboardKey.spacer(),
          ]),
          _keyboardRow(context, [
            _AmountKeyboardKey.digit('0'),
            _AmountKeyboardKey.digit('000'),
            _AmountKeyboardKey.backspace(),
            _AmountKeyboardKey.done(shouldEvaluate ? '=' : 'Xong'),
          ], addBottomGap: false),
        ],
      ),
    );
  }

  Widget _keyboardRow(
    BuildContext context,
    List<_AmountKeyboardKey> keys, {
    bool addBottomGap = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: addBottomGap ? _keyGap : 0),
      child: Row(
        children: [
          for (var index = 0; index < keys.length; index++) ...[
            Expanded(
              child: keys[index].type == _AmountKeyboardKeyType.spacer
                  ? const SizedBox(height: _keyHeight)
                  : _keyboardButton(context, keys[index]),
            ),
            if (index != keys.length - 1) const SizedBox(width: _keyGap),
          ],
        ],
      ),
    );
  }

  Widget _keyboardButton(
    BuildContext context,
    _AmountKeyboardKey key, {
    double height = _keyHeight,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = key.type == _AmountKeyboardKeyType.done;

    return Material(
      color: isDone ? colorScheme.primary : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => onKeyPressed(key),
        child: SizedBox(
          height: height,
          child: Center(
            // Bàn phím custom không dùng IME hệ thống, nên mọi phím đều đi qua
            // callback này để kiểm soát định dạng tiền và phép tính trước khi lưu.
            child: key.icon == null
                ? Text(
                    key.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDone
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Icon(
                    key.icon,
                    color: isDone
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}

class _AmountKeyboardKey {
  final _AmountKeyboardKeyType type;
  final String value;
  final String label;
  final IconData? icon;

  const _AmountKeyboardKey._({
    required this.type,
    required this.value,
    required this.label,
    this.icon,
  });

  factory _AmountKeyboardKey.digit(String value) {
    return _AmountKeyboardKey._(
      type: _AmountKeyboardKeyType.digit,
      value: value,
      label: value,
    );
  }

  factory _AmountKeyboardKey.operator(String label) {
    return _AmountKeyboardKey._(
      type: _AmountKeyboardKeyType.operator,
      value: label == '×' ? '*' : (label == '÷' ? '/' : label),
      label: label,
    );
  }

  factory _AmountKeyboardKey.clear() {
    return const _AmountKeyboardKey._(
      type: _AmountKeyboardKeyType.clear,
      value: '',
      label: 'C',
    );
  }

  factory _AmountKeyboardKey.backspace() {
    return const _AmountKeyboardKey._(
      type: _AmountKeyboardKeyType.backspace,
      value: '',
      label: '',
      icon: Icons.backspace_outlined,
    );
  }

  factory _AmountKeyboardKey.done(String label) {
    return _AmountKeyboardKey._(
      type: _AmountKeyboardKeyType.done,
      value: '',
      label: label,
    );
  }

  factory _AmountKeyboardKey.spacer() {
    return const _AmountKeyboardKey._(
      type: _AmountKeyboardKeyType.spacer,
      value: '',
      label: '',
    );
  }
}

enum _AmountKeyboardKeyType { digit, operator, clear, backspace, done, spacer }

enum _ReceiptScanAction { apply, rescan, dismiss }

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';

    int count = 0;

    for (int i = newText.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }

      formatted = newText[i] + formatted;

      count++;
    }

    return TextEditingValue(
      text: formatted,

      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
