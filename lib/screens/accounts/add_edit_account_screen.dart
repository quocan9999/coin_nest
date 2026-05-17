import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../models/account.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/category_icons.dart';

class AddEditAccountScreen extends StatefulWidget {
  final Account? account;
  const AddEditAccountScreen({super.key, this.account});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'cash';
  bool _includeInTotal = true;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toStringAsFixed(0);
      _selectedType = widget.account!.type;
      _includeInTotal = widget.account!.isIncludedInTotal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().currentUserId;
    final prov = context.read<AccountProvider>();
    bool success;

    if (_isEditing) {
      success = await prov.updateAccount(widget.account!.copyWith(
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: Validators.parseAmount(_balanceController.text),
        iconName: _selectedType,
        isIncludedInTotal: _includeInTotal,
      ));
    } else {
      success = await prov.addAccount(
        userId: userId,
        name: _nameController.text.trim(),
        type: _selectedType,
        initialBalance: Validators.parseAmount(_balanceController.text),
        isIncludedInTotal: _includeInTotal,
      );
    }

    if (!mounted) return;
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa tài khoản' : 'Thêm tài khoản'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('TÊN TÀI KHOẢN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (v) => Validators.entityName(v, 'Tên tài khoản'),
                decoration: const InputDecoration(hintText: 'VD: Ví tiền mặt'),
              ),
              const SizedBox(height: 20),

              _label('LOẠI TÀI KHOẢN'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.accountTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CategoryIcons.getIcon(type), size: 18,
                              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            AppConstants.accountTypeLabels[type]!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _label('SỐ DƯ BAN ĐẦU'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '0', suffixText: 'đ'),
              ),
              const SizedBox(height: 20),

              SwitchListTile(
                title: const Text('Tính vào tổng số dư'),
                value: _includeInTotal,
                onChanged: (v) => setState(() => _includeInTotal = v),
                activeTrackColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(onPressed: _save, child: Text(_isEditing ? 'Cập nhật' : 'Thêm tài khoản')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8));
}
