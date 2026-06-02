import 'package:flutter/material.dart';
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
import '../../widgets/money_amount_input.dart';
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

      _amountController.text = MoneyAmountInput.formatAmount(txn.amount);

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

              MoneyAmountField(
                controller: _amountController,

                focusNode: _amountFocusNode,

                validator: Validators.amount,

                textStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              // CATEGORY
              if (_currentType != 'transfer') ...[
                _sectionLabel(context, 'HẠNG MỤC'),

                const SizedBox(height: 8),

                _buildCategoryDropdown(
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
      child: MoneyAmountKeyboardPanel(
        key: ValueKey(
          shouldShow ? 'receipt-scan-accessory' : 'receipt-scan-hidden',
        ),
        isVisible: shouldShow,
        onScanReceipt: _openReceiptScanner,
        onKeyPressed: _handleAmountKeyboardKey,
        shouldEvaluate: _amountExpressionNeedsEvaluation,
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

  bool get _amountExpressionNeedsEvaluation =>
      MoneyAmountInput.needsEvaluation(_amountController.text);

  bool _finalizeAmountExpression({required bool showError}) {
    return MoneyAmountInput.finalizeExpression(
      context: context,
      controller: _amountController,
      refresh: () => setState(() {}),
      showError: showError,
    );
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
      _amountController.text = MoneyAmountInput.formatAmount(
        result.totalAmount,
      );

      // Không ghi đè ghi chú người dùng đã nhập để tránh làm mất ngữ cảnh giao dịch.
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = result.generatedNote;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã áp dụng kết quả scan hoá đơn')),
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelectedCategory = categories.any(
      (category) => category.id == _selectedCategoryId,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: hasSelectedCategory ? _selectedCategoryId : null,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          hint: const Text('Ch\u1ecdn h\u1ea1ng m\u1ee5c'),
          items: categories
              .map(
                (category) => DropdownMenuItem<int>(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        CategoryIcons.getIcon(category.iconName),
                        size: 18,
                        color: CategoryIcons.getColor(category.iconName),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (categoryId) async {
            if (categoryId == null) return;

            final category = categories.firstWhere(
              (category) => category.id == categoryId,
            );
            await _handleCategoryTap(category);
          },
        ),
      ),
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

enum _ReceiptScanAction { apply, rescan, dismiss }
