import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/category_icons.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;
  const AddEditCategoryScreen({super.key, this.category});
  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _type = 'expense';
  String _selectedIcon = 'food';
  int? _selectedParentId;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.category!.name;
      _type = widget.category!.type;
      _selectedIcon = widget.category!.iconName;
      _selectedParentId = widget.category!.parentId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUserId;
    final prov = context.read<CategoryProvider>();
    bool success;

    if (_isEditing) {
      success = await prov.updateCategory(
        widget.category!.copyWith(
          name: _nameController.text.trim(),
          iconName: _selectedIcon,
          parentId: _selectedParentId,
        ),
      );
    } else {
      success = await prov.addCategory(
        userId: userId,
        name: _nameController.text.trim(),
        type: _type,
        iconName: _selectedIcon,
        parentId: _selectedParentId,
      );
    }
    if (!mounted) return;
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final iconKeys = _type == 'expense'
        ? CategoryIcons.expenseIconKeys
        : CategoryIcons.incomeIconKeys;
    final catProv = context.watch<CategoryProvider>();
    final allCats = _type == 'expense'
        ? catProv.expenseCategories
        : catProv.incomeCategories;

    // Logic: A category cannot choose itself as parent. Also, only top-level categories can be parents.
    final parentCandidates = allCats
        .where((c) => c.parentId == null && c.id != widget.category?.id)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa hạng mục' : 'Thêm hạng mục'),
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
              if (!_isEditing) ...[
                Text(
                  'LOẠI',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _typeChip('Chi tiêu', 'expense'),
                    SizedBox(width: 8),
                    _typeChip('Thu nhập', 'income'),
                  ],
                ),
                SizedBox(height: 20),
              ],
              Text(
                'TÊN HẠNG MỤC',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (v) => Validators.entityName(v, 'Tên hạng mục'),
                decoration: InputDecoration(hintText: 'VD: Ăn uống'),
              ),
              SizedBox(height: 20),

              Text(
                'HẠNG MỤC CHA (TÙY CHỌN)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedParentId,
                    hint: Text('Không có (Hạng mục gốc)'),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Không có (Hạng mục gốc)'),
                      ),
                      ...parentCandidates.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedParentId = val),
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text(
                'BIỂU TƯỢNG',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: iconKeys.map((key) {
                  final sel = _selectedIcon == key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = key),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.colors(context).primary
                            : CategoryIcons.getColor(key).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: sel
                            ? null
                            : Border.all(
                                color: AppTheme.colors(
                                  context,
                                ).border.withAlpha(51),
                              ),
                      ),
                      child: Icon(
                        CategoryIcons.getIcon(key),
                        color: sel
                            ? Theme.of(context).colorScheme.onPrimary
                            : CategoryIcons.getColor(key),
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Cập nhật' : 'Thêm hạng mục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final sel = _type == value;
    return GestureDetector(
      onTap: () => setState(() {
        _type = value;
        _selectedIcon = value == 'expense' ? 'food' : 'salary';
        _selectedParentId = null; // reset parent when changing type
      }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: sel
              ? AppTheme.colors(context).primary
              : AppTheme.colors(context).input,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel
                ? Theme.of(context).colorScheme.onPrimary
                : AppTheme.colors(context).textPrimary,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
