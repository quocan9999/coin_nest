import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/money_amount_input.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddEditBudgetScreen({super.key, this.budget});

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  int? _categoryId;
  int? _accountId;
  String _period = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // NOTE: none/quarterly đang được giữ để resolve conflict theo tính năng hiện tại.
  // DB chưa chấp nhận hai giá trị này trong CHECK constraint của bảng budgets.
  // Người sửa tiếp cần đồng bộ AppConstants, DatabaseHelper, BudgetDao và BudgetListScreen.
  final Map<String, String> _periodOptions = {
    'none': 'Không lặp lại',
    'daily': 'Theo ngày',
    'weekly': 'Theo tuần',
    'monthly': 'Theo tháng',
    'quarterly': 'Theo quý',
    'yearly': 'Theo năm',
  };

  bool get isEditMode => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAccounts();

    if (isEditMode) {
      final budget = widget.budget!;
      _nameController.text = budget.name;
      _amountController.text = MoneyAmountInput.formatAmount(budget.amount);
      _categoryId = budget.categoryId;
      _accountId = budget.accountId;
      _period = budget.period;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _accountId != null) return;
        final accounts = context.read<AccountProvider>().accounts;
        if (accounts.isNotEmpty) {
          setState(() => _accountId = accounts.first.id);
        }
      });
    }
  }

  Future<void> _loadAccounts() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().currentUserId;
      await context.read<AccountProvider>().loadAccounts(userId);
      if (!mounted || isEditMode || _accountId != null) return;
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) {
        setState(() => _accountId = accounts.first.id);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _showConfirmDialog({
    required String message,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Thông báo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
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
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSave() async {
    final userId = context.read<AuthProvider>().currentUserId;
    final amount = Validators.parseAmount(_amountController.text);
    final now = DateTime.now();
    final budgetProvider = context.read<BudgetProvider>();

    final success = isEditMode
        ? await budgetProvider.updateBudget(
            Budget(
              id: widget.budget!.id,
              userId: userId,
              categoryId: _categoryId,
              accountId: _accountId,
              name: _nameController.text.trim(),
              amount: amount,
              period: _period,
              startDate: _startDate,
              endDate: _endDate,
              isActive: widget.budget!.isActive,
              createdAt: widget.budget!.createdAt,
              updatedAt: now,
            ),
          )
        : await budgetProvider.addBudget(
            userId: userId,
            categoryId: _categoryId,
            accountId: _accountId,
            name: _nameController.text.trim(),
            amount: amount,
            period: _period,
            startDate: _startDate,
            endDate: _endDate,
          );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (!_finalizeAmountExpression(showError: true)) return;

    if (!_formKey.currentState!.validate()) return;

    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tài khoản áp dụng hạn mức'),
        ),
      );
      return;
    }

    final startDay = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );
    if (_endDate != null && _endDate!.isBefore(startDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc không được trước ngày bắt đầu'),
        ),
      );
      return;
    }

    // NOTE: Nếu _period là none hoặc quarterly, luồng lưu vẫn có thể lỗi SQLite
    // cho tới khi DB/DAO được đồng bộ theo note bàn giao sau conflict.
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

  Future<void> _executeDelete() async {
    final userId = context.read<AuthProvider>().currentUserId;
    final success = await context.read<BudgetProvider>().deleteBudget(
      widget.budget!.id!,
      userId,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
  }

  void _delete() {
    if (!isEditMode) return;
    _showConfirmDialog(
      message:
          'Chú ý! Dữ liệu bị xoá sẽ không thể khôi phục lại được. Bạn có muốn tiếp tục?',
      onConfirm: _executeDelete,
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = context.watch<CategoryProvider>().expenseCategories;
    final accounts = context.watch<AccountProvider>().accounts;

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
          title: Text(isEditMode ? 'Sửa hạn mức' : 'Thêm hạn mức'),
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
                _label('SỐ TIỀN'),
                const SizedBox(height: AppTheme.spacing4),
                MoneyAmountField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  validator: Validators.amount,
                  textStyle: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing10),
                _label('TÊN HẠN MỨC'),
                const SizedBox(height: AppTheme.spacing4),
                TextFormField(
                  controller: _nameController,
                  validator: (value) => Validators.entityName(value, 'Tên'),
                  decoration: const InputDecoration(
                    hintText: 'VD: Ăn uống tháng này',
                  ),
                ),
                const SizedBox(height: AppTheme.spacing10),
                _label('HẠNG MỤC (TÙY CHỌN)'),
                const SizedBox(height: AppTheme.spacing4),
                _buildCategoryDropdown(categories, colorScheme),
                const SizedBox(height: AppTheme.spacing10),
                _label('TÀI KHOẢN'),
                const SizedBox(height: AppTheme.spacing4),
                _buildAccountDropdown(accounts, colorScheme),
                const SizedBox(height: AppTheme.spacing10),
                _label('CHU KỲ'),
                const SizedBox(height: AppTheme.spacing4),
                _buildPeriodDropdown(colorScheme),
                const SizedBox(height: AppTheme.spacing10),
                _label('NGÀY BẮT ĐẦU'),
                const SizedBox(height: AppTheme.spacing4),
                _buildDateTile(
                  icon: Icons.calendar_today_outlined,
                  text: Formatters.date(_startDate),
                  colorScheme: colorScheme,
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: AppTheme.spacing10),
                _label('NGÀY KẾT THÚC'),
                const SizedBox(height: AppTheme.spacing4),
                _buildDateTile(
                  icon: Icons.event_busy_outlined,
                  text: _endDate != null
                      ? Formatters.date(_endDate!)
                      : 'Không xác định',
                  colorScheme: colorScheme,
                  onTap: _pickEndDate,
                  trailing: _endDate == null
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close, color: colorScheme.tertiary),
                          onPressed: () => setState(() => _endDate = null),
                        ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                _buildActions(colorScheme),
                const SizedBox(height: AppTheme.spacing10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(
    List<dynamic> categories,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _categoryId,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          hint: const Text('Tất cả hạng mục'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Tất cả hạng mục'),
            ),
            ...categories.map(
              (category) => DropdownMenuItem<int?>(
                value: category.id,
                child: Text(category.name),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _categoryId = value),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(
    List<dynamic> accounts,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _accountId,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          hint: const Text('Chọn tài khoản'),
          items: accounts
              .map(
                (account) => DropdownMenuItem<int?>(
                  value: account.id,
                  child: Text(account.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _accountId = value),
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _period,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          items: _periodOptions.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _period = value);
          },
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing8,
          vertical: AppTheme.spacing6,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppTheme.spacing6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: _endDate != null || text != 'Không xác định'
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ColorScheme colorScheme) {
    if (!isEditMode) {
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _save,
          child: const Text('Lưu hạn mức'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.tertiary,
                side: BorderSide(color: colorScheme.tertiary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
              child: const Text(
                'Xoá',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing6),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
              child: const Text('Lưu lại'),
            ),
          ),
        ),
      ],
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
}
