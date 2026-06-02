import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';

import '../../models/account.dart';

import '../../theme/app_theme.dart';

import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/category_icons.dart';
import '../../widgets/money_amount_input.dart';

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
  final _balanceFocusNode = FocusNode();

  String _selectedType = 'cash';

  bool _includeInTotal = true;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _balanceFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    if (_isEditing) {
      _nameController.text = widget.account!.name;

      _balanceController.text = MoneyAmountInput.formatAmount(
        widget.account!.balance,
      );

      _selectedType = widget.account!.type;

      _includeInTotal = widget.account!.isIncludedInTotal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _balanceController.dispose();
    _balanceFocusNode.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_finalizeBalanceExpression(showError: true)) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = context.read<AuthProvider>().currentUserId;

    final prov = context.read<AccountProvider>();

    bool success;

    if (_isEditing) {
      success = await prov.updateAccount(
        widget.account!.copyWith(
          name: _nameController.text.trim(),

          type: _selectedType,

          balance: Validators.parseAmount(_balanceController.text),

          iconName: _selectedType,

          isIncludedInTotal: _includeInTotal,
        ),
      );
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

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MoneyAmountKeyboardBackGuard(
      focusNode: _balanceFocusNode,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBar: MoneyAmountKeyboardPanel(
          isVisible: _balanceFocusNode.hasFocus,
          onKeyPressed: _handleBalanceKeyboardKey,
          shouldEvaluate: MoneyAmountInput.needsEvaluation(
            _balanceController.text,
          ),
        ),

        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,

          title: Text(_isEditing ? 'Sửa tài khoản' : 'Thêm tài khoản'),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),

            onPressed: () => Navigator.pop(context),
          ),
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

                  decoration: const InputDecoration(
                    hintText: 'VD: Ví tiền mặt',
                  ),
                ),

                const SizedBox(height: 20),

                _label('LOẠI TÀI KHOẢN'),

                const SizedBox(height: 8),

                _buildAccountTypeDropdown(theme),
                const SizedBox(height: 20),

                _label('SỐ DƯ BAN ĐẦU'),

                const SizedBox(height: 8),

                MoneyAmountField(
                  controller: _balanceController,
                  focusNode: _balanceFocusNode,
                  validator: Validators.amount,
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

                  child: ElevatedButton(
                    onPressed: _save,

                    child: Text(_isEditing ? 'Cập nhật' : 'Thêm tài khoản'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBalanceKeyboardKey(MoneyAmountKeyboardKey key) {
    MoneyAmountInput.handleKey(
      context: context,
      controller: _balanceController,
      focusNode: _balanceFocusNode,
      key: key,
      refresh: () => setState(() {}),
    );
  }

  bool _finalizeBalanceExpression({required bool showError}) {
    return MoneyAmountInput.finalizeExpression(
      context: context,
      controller: _balanceController,
      refresh: () => setState(() {}),
      showError: showError,
    );
  }

  Widget _buildAccountTypeDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          dropdownColor: theme.colorScheme.surface,
          items: AppConstants.accountTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    CategoryIcons.getIcon(type),
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(AppConstants.accountTypeLabels[type] ?? type),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedType = value);
          },
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,

      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,

        letterSpacing: 0.8,

        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
