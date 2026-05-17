import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/category_icons.dart';
import '../../utils/formatters.dart';

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

      String initialAmount = txn.amount.toInt().toString();
      String formatted = '';
      int count = 0;
      for (int i = initialAmount.length - 1; i >= 0; i--) {
        if (count != 0 && count % 3 == 0) formatted = '.$formatted';
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
      if (accounts.isNotEmpty) _selectedAccountId = accounts.first.id;
    }

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _previousTabIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index != _previousTabIndex) {
        setState(() {
          _selectedCategoryId = null;
          _previousTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  // HÀM HIỂN THỊ HỘP THOẠI XÁC NHẬN
  void _showConfirmDialog({
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text(
              'Không',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng hộp thoại
              onConfirm(); // Thực thi hành động
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

  // LOGIC LƯU DỮ LIỆU
  Future<void> _executeSave() async {
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
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tài khoản')));
      return;
    }

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

  // LOGIC XOÁ DỮ LIỆU
  Future<void> _executeDelete() async {
    final userId = context.read<AuthProvider>().currentUserId;
    final success = await context.read<TransactionProvider>().deleteTransaction(
      widget.transaction!.id!,
      userId,
    );

    if (!mounted) return;
    if (success) {
      await context.read<AccountProvider>().loadAccounts(userId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    if (!isEditMode) return;
    _showConfirmDialog(
      message:
          'Chú ý! Dữ liệu bị xoá sẽ không thể khôi phục lại được. Bạn có muốn tiếp tục?',
      onConfirm: _executeDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CategoryProvider>();
    final accProv = context.watch<AccountProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(isEditMode ? 'Sửa giao dịch' : 'Ghi chép giao dịch'),
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
          unselectedLabelColor: AppTheme.onSurfaceVariant,
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
              Text(
                'SỐ TIỀN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                validator: Validators.amount,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: '0',
                  suffixText: 'đ',
                ),
              ),
              const SizedBox(height: 20),

              if (_currentType != 'transfer') ...[
                Text(
                  'HẠNG MỤC',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCategoryGrid(
                  _currentType == 'expense'
                      ? catProv.expenseCategories
                      : catProv.incomeCategories,
                ),
                const SizedBox(height: 20),
              ],

              Text(
                _currentType == 'transfer' ? 'TỪ TÀI KHOẢN' : 'TÀI KHOẢN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _buildAccountDropdown(accProv, isSource: true),

              if (_currentType == 'transfer') ...[
                const SizedBox(height: 20),
                Text(
                  'ĐẾN TÀI KHOẢN',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAccountDropdown(accProv, isSource: false),
              ],

              const SizedBox(height: 20),

              Text(
                'NGÀY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(Formatters.date(_selectedDate)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'GHI CHÚ',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
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
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.tertiary,
                            // Bo góc giống hệt nút Lưu
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
                            // Bo góc giống hệt nút Xoá
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
                    child: const Text('Lưu giao dịch'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategoryId == cat.id;
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedCategoryId = isSelected ? null : cat.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.surfaceContainerLow,
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
                    color: isSelected ? Colors.white : AppTheme.onSurface,
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
    final currentValue = isSource ? _selectedAccountId : _selectedToAccountId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentValue,
          isExpanded: true,
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
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    String formatted = '';
    int count = 0;
    for (int i = newText.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) formatted = '.$formatted';
      formatted = newText[i] + formatted;
      count++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
