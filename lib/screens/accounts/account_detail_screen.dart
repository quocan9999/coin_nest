import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/account.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';
import '../../utils/category_icons.dart';
import 'add_edit_account_screen.dart';
import 'balance_adjustment_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Chi tiết tài khoản'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAccountScreen(account: account))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.tertiary),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Account card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: CategoryIcons.getColor(account.iconName ?? account.type).withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(CategoryIcons.getIcon(account.iconName ?? account.type),
                        color: CategoryIcons.getColor(account.iconName ?? account.type), size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(account.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(AppConstants.accountTypeLabels[account.type] ?? account.type,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  Text(Formatters.currency(account.balance),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => BalanceAdjustmentScreen(account: account))),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Điều chỉnh số dư'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Bạn có chắc chắn muốn xóa "${account.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final userId = context.read<AuthProvider>().currentUserId;
              await context.read<AccountProvider>().deleteAccount(account.id!, userId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: AppTheme.tertiary)),
          ),
        ],
      ),
    );
  }
}
