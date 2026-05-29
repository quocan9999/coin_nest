import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class AddEditBudgetScreen extends StatefulWidget {
  const AddEditBudgetScreen({super.key});
  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _period = 'monthly';
  int? _categoryId;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUserId;
    final success = await context.read<BudgetProvider>().addBudget(
      userId: userId,
      categoryId: _categoryId,
      name: _nameController.text.trim(),
      amount: Validators.parseAmount(_amountController.text),
      period: _period,
      startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
    if (!mounted) return;
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().expenseCategories;
    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text('Thêm hạn mức'),
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
              _label('TÊN HẠN MỨC'),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (v) => Validators.entityName(v, 'Tên'),
                decoration: InputDecoration(hintText: 'VD: Ăn uống tháng này'),
              ),
              SizedBox(height: 20),
              _label('SỐ TIỀN'),
              SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: Validators.amount,
                decoration: InputDecoration(hintText: '0', suffixText: 'đ'),
              ),
              SizedBox(height: 20),
              _label('CHU KỲ'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.budgetPeriodLabels.entries.map((e) {
                  final sel = _period == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _period = e.key),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.colors(context).primary
                            : AppTheme.colors(context).input,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: sel
                              ? Theme.of(context).colorScheme.onPrimary
                              : AppTheme.colors(context).textPrimary,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              _label('HẠNG MỤC (TÙY CHỌN)'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.colors(context).input,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _categoryId,
                    isExpanded: true,
                    hint: Text('Tất cả hạng mục'),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả hạng mục'),
                      ),
                      ...categories.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text('Lưu hạn mức'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );
}
