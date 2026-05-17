import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/category_icons.dart';
import '../../utils/formatters.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedAccountId;
  int? _selectedToAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final accounts = context.read<AccountProvider>().accounts;
    if (accounts.isNotEmpty) _selectedAccountId = accounts.first.id;
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
      case 0: return 'expense';
      case 1: return 'income';
      case 2: return 'transfer';
      default: return 'expense';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tài khoản')));
      return;
    }

    final userId = context.read<AuthProvider>().currentUserId;
    final success = await context.read<TransactionProvider>().addTransaction(
      userId: userId,
      accountId: _selectedAccountId!,
      toAccountId: _currentType == 'transfer' ? _selectedToAccountId : null,
      categoryId: _selectedCategoryId,
      type: _currentType,
      amount: Validators.parseAmount(_amountController.text),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: _selectedDate,
      time: Formatters.time(DateTime.now()),
    );

    if (!mounted) return;
    if (success) {
      await context.read<AccountProvider>().loadAccounts(userId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CategoryProvider>();
    final accProv = context.watch<AccountProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Ghi chép giao dịch'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [Tab(text: 'Chi tiêu'), Tab(text: 'Thu nhập'), Tab(text: 'Chuyển khoản')],
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
              // Amount
              Text('SỐ TIỀN', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: Validators.amount,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: '0', suffixText: 'đ'),
              ),

              const SizedBox(height: 20),

              // Category (not for transfer)
              if (_currentType != 'transfer') ...[
                Text('HẠNG MỤC', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _buildCategoryGrid(
                  _currentType == 'expense' ? catProv.expenseCategories : catProv.incomeCategories,
                ),
                const SizedBox(height: 20),
              ],

              // Account
              Text(_currentType == 'transfer' ? 'TỪ TÀI KHOẢN' : 'TÀI KHOẢN',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              _buildAccountDropdown(accProv, isSource: true),

              if (_currentType == 'transfer') ...[
                const SizedBox(height: 20),
                Text('ĐẾN TÀI KHOẢN', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _buildAccountDropdown(accProv, isSource: false),
              ],

              const SizedBox(height: 20),

              // Date
              Text('NGÀY', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(Formatters.date(_selectedDate)),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // Note
              Text('GHI CHÚ', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                validator: Validators.note,
                decoration: const InputDecoration(hintText: 'Nhập ghi chú (tùy chọn)'),
              ),

              const SizedBox(height: 28),

              SizedBox(height: 52, child: ElevatedButton(onPressed: _save, child: const Text('Lưu giao dịch'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategoryId == cat.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategoryId = cat.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CategoryIcons.getIcon(cat.iconName), size: 16, color: isSelected ? Colors.white : CategoryIcons.getColor(cat.iconName)),
              const SizedBox(width: 6),
              Text(cat.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppTheme.onSurface)),
            ]),
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
          items: prov.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
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
