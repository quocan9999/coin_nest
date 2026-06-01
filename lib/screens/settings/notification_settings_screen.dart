import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification/notification_record_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccounts();
    });
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    await context.read<AccountProvider>().loadAccounts(userId);
  }

  Future<void> _handleToggle(bool value) async {
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.setAutoNotificationRecord(value);

    final started = await NotificationRecordService.syncFromPreferences(
      requestPermission: value,
    );

    if (!mounted || !value || started) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Hãy cấp quyền đọc thông báo trong cài đặt Android để bật tự động ghi chép.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;
    final theme = Theme.of(context);
    final isSupported = NotificationRecordService.isSupported;
    final canChooseAccounts =
        isSupported && settings.autoNotificationRecord && accounts.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Ghi chép từ thông báo')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing10),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.autoNotificationRecord && isSupported,
                  onChanged: isSupported ? _handleToggle : null,
                  activeThumbColor: AppTheme.primary,
                  title: Text(
                    'Tự động ghi chép',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    isSupported
                        ? 'Nhận diện thông báo biến động số dư và tạo giao dịch tương ứng.'
                        : 'Tính năng này chỉ hỗ trợ Android.',
                  ),
                ),
                if (settings.autoNotificationRecord && isSupported) ...[
                  const SizedBox(height: AppTheme.spacing8),
                  _AccountDropdown(
                    label: 'Tài khoản mặc định khi chi',
                    accounts: accounts,
                    value: settings.autoExpenseAccountId,
                    enabled: canChooseAccounts,
                    onChanged: context
                        .read<SettingsProvider>()
                        .setAutoExpenseAccountId,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  _AccountDropdown(
                    label: 'Tài khoản mặc định khi thu',
                    accounts: accounts,
                    value: settings.autoIncomeAccountId,
                    enabled: canChooseAccounts,
                    onChanged: context
                        .read<SettingsProvider>()
                        .setAutoIncomeAccountId,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              'CoinNest chỉ tạo giao dịch khi thông báo có cấu trúc DG/ND của ngân hàng. Các thông báo trùng nội dung sẽ được bỏ qua để tránh ghi sai số dư.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final List<Account> accounts;
  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final validValue =
        value != null && accounts.any((account) => account.id == value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: validValue ? value : null,
              hint: const Text('Chọn tài khoản'),
              items: [
                const DropdownMenuItem<int?>(
                  child: Text('Tự chọn tài khoản đầu tiên'),
                ),
                ...accounts
                    .where((account) => account.id != null)
                    .map(
                      (account) => DropdownMenuItem<int?>(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    ),
              ],
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
