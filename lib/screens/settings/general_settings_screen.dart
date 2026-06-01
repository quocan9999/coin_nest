import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification/reminder_coordinator.dart';
import '../../theme/app_theme.dart';
import 'support_map_screen.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Cài đặt chung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle(context, 'HIỂN THỊ'),
          const SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              SwitchListTile(
                title: const Text('Hiện số dư'),
                subtitle: const Text('Hiển thị số dư trên trang tổng quan'),
                value: settings.showBalance,
                onChanged: settings.setShowBalance,
              ),
              SwitchListTile(
                title: const Text('Giao diện tối'),
                subtitle: const Text('Bật chế độ nền tối'),
                value: settings.isDarkMode,
                onChanged: settings.setDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'NHẮC NHỞ'),
          const SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              SwitchListTile(
                title: const Text('Nhắc nhở ghi chép'),
                subtitle: const Text('Nhắc bạn ghi chép mỗi ngày'),
                value: settings.dailyReminder,
                onChanged: (value) =>
                    _setDailyReminder(context, settings, value),
              ),
              SwitchListTile(
                title: const Text('Nhắc trả nợ / thu nợ'),
                subtitle: const Text(
                  'Nhắc khi còn khoản vay hoặc cho vay đang hoạt động',
                ),
                value: settings.debtReminder,
                onChanged: (value) =>
                    _setDebtReminder(context, settings, value),
              ),
              ListTile(
                title: const Text('Giờ nhắc'),
                subtitle: const Text(
                  'Áp dụng cho nhắc ghi chép và nhắc vay nợ',
                ),
                trailing: Text(
                  settings.reminderTime,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _pickReminderTime(context, settings),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'ĐƠN VỊ TIỀN TỆ'),
          const SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              ListTile(
                title: const Text('Đơn vị tiền tệ'),
                trailing: Text(
                  settings.currency,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'THÔNG TIN'),
          const SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              ListTile(
                title: const Text('Phiên bản'),
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              ListTile(
                title: const Text('Liên hệ hỗ trợ'),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.outline,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportMapScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }

  Widget _settingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Future<void> _setDailyReminder(
    BuildContext context,
    SettingsProvider settings,
    bool value,
  ) async {
    final loans = context.read<LoanProvider>().loans;
    await settings.setDailyReminder(value);
    final synced = await _syncReminders(settings, loans);
    if (!context.mounted) return;

    if (!synced && value) {
      await settings.setDailyReminder(false);
      if (!context.mounted) return;
      _showPermissionMessage(context);
    }
  }

  Future<void> _setDebtReminder(
    BuildContext context,
    SettingsProvider settings,
    bool value,
  ) async {
    final loans = context.read<LoanProvider>().loans;
    await settings.setDebtReminder(value);
    final synced = await _syncReminders(settings, loans);
    if (!context.mounted) return;

    if (!synced && value) {
      await settings.setDebtReminder(false);
      if (!context.mounted) return;
      _showPermissionMessage(context);
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final initial = _timeOfDayFrom(settings.reminderTime);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !context.mounted) return;

    final loans = context.read<LoanProvider>().loans;
    await settings.setReminderTime(_formatTime(picked));
    final synced = await _syncReminders(settings, loans);
    if (!context.mounted) return;

    if (!synced && (settings.dailyReminder || settings.debtReminder)) {
      _showPermissionMessage(context);
    }
  }

  Future<bool> _syncReminders(SettingsProvider settings, Iterable<Loan> loans) {
    return ReminderCoordinator().syncReminders(
      dailyReminderEnabled: settings.dailyReminder,
      debtReminderEnabled: settings.debtReminder,
      reminderTime: settings.reminderTime,
      loans: loans,
    );
  }

  TimeOfDay _timeOfDayFrom(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return TimeOfDay(hour: hour ?? 20, minute: minute ?? 0);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  void _showPermissionMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bạn cần cấp quyền thông báo để bật nhắc nhở.'),
      ),
    );
  }
}
