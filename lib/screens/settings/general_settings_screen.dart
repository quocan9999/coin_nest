import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Cài đặt chung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing10),
        children: [
          _sectionTitle(context, 'HIỂN THỊ'),
          const SizedBox(height: AppTheme.spacing4),
          _settingsCard(
            children: [
              SwitchListTile(
                title: const Text('Hiện số dư'),
                subtitle: const Text('Hiển thị số dư trên trang tổng quan'),
                value: settings.showBalance,
                onChanged: settings.setShowBalance,
                activeTrackColor: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing10),

          _sectionTitle(context, 'ĐƠN VỊ TIỀN TỆ'),
          const SizedBox(height: AppTheme.spacing4),
          _settingsCard(
            children: [
              ListTile(
                title: const Text('Đơn vị tiền tệ'),
                trailing: Text(
                  settings.currency,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing10),

          _sectionTitle(context, 'NHẮC NHỞ GHI CHÉP'),
          const SizedBox(height: AppTheme.spacing4),
          _settingsCard(
            children: [
              SwitchListTile(
                title: const Text('Nhắc nhở ghi chép hằng ngày'),
                subtitle: const Text(
                  'Quản lý các giờ nhắc bạn ghi chép thu chi mỗi ngày',
                ),
                value: settings.dailyReminderEnabled,
                onChanged: (enabled) async {
                  try {
                    await context.read<SettingsProvider>().setDailyReminder(
                      enabled,
                    );
                  } catch (error, stackTrace) {
                    debugPrint(
                      'GeneralSettingsScreen.setDailyReminder failed: $error',
                    );
                    debugPrintStack(stackTrace: stackTrace);
                  }
                },
                activeTrackColor: AppTheme.primary,
              ),
              if (settings.reminderTimeSlots.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  child: Text(
                    'Chưa có giờ nhắc nào. Thêm để bật nhắc nhở.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ...settings.reminderTimeSlots.map(
                (slot) => ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text(_formatTime(context, slot)),
                  trailing: IconButton(
                    tooltip: 'Xóa giờ nhắc',
                    icon: const Icon(Icons.close, color: AppTheme.outline),
                    onPressed: () async {
                      try {
                        await context
                            .read<SettingsProvider>()
                            .removeReminderSlot(slot);
                      } catch (error, stackTrace) {
                        debugPrint(
                          'GeneralSettingsScreen.removeReminderSlot failed: $error',
                        );
                        debugPrintStack(stackTrace: stackTrace);
                      }
                    },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.primary,
                ),
                title: const Text('Thêm giờ nhắc'),
                onTap: () => _pickReminderSlot(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing10),

          _sectionTitle(context, 'NHẮC NHỞ NỢ/VAY'),
          const SizedBox(height: AppTheme.spacing4),
          _settingsCard(
            children: [
              SwitchListTile(
                title: const Text('Nhắc nhở nợ/vay'),
                subtitle: const Text(
                  'Nhắc trước 7, 3, 1 ngày và ngay ngày đến hạn',
                ),
                value: settings.loanReminderEnabled,
                onChanged: (enabled) async {
                  try {
                    await context.read<SettingsProvider>().setLoanReminder(
                      enabled,
                    );
                  } catch (error, stackTrace) {
                    debugPrint(
                      'GeneralSettingsScreen.setLoanReminder failed: $error',
                    );
                    debugPrintStack(stackTrace: stackTrace);
                  }
                },
                activeTrackColor: AppTheme.primary,
              ),
              if (settings.loanReminderDays.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  child: Text(
                    'Chưa có mốc nhắc nào. Thêm để nhắc khi đến hạn.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ...settings.loanReminderDays.map(
                (days) => ListTile(
                  leading: const Icon(
                    Icons.event_available_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text(_formatLoanReminderDay(days)),
                  trailing: IconButton(
                    tooltip: 'Xóa mốc nhắc',
                    icon: const Icon(Icons.close, color: AppTheme.outline),
                    onPressed: () async {
                      try {
                        await context
                            .read<SettingsProvider>()
                            .removeLoanReminderDay(days);
                      } catch (error, stackTrace) {
                        debugPrint(
                          'GeneralSettingsScreen.removeLoanReminderDay failed: $error',
                        );
                        debugPrintStack(stackTrace: stackTrace);
                      }
                    },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.primary,
                ),
                title: const Text('Thêm mốc nhắc'),
                onTap: () => _showAddLoanReminderDayDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing10),

          _sectionTitle(context, 'THÔNG TIN'),
          const SizedBox(height: AppTheme.spacing4),
          _settingsCard(
            children: const [
              ListTile(
                title: Text('Phiên bản'),
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
              Divider(height: 1),
              ListTile(
                title: Text('Liên hệ hỗ trợ'),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppTheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    return time.format(context);
  }

  String _formatLoanReminderDay(int days) {
    return days == 0 ? 'Ngày đến hạn' : '$days ngày trước';
  }

  Future<void> _pickReminderSlot(BuildContext context) async {
    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (picked == null || !context.mounted) return;

      await context.read<SettingsProvider>().addReminderSlot(picked);
    } catch (error, stackTrace) {
      debugPrint('GeneralSettingsScreen._pickReminderSlot failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _showAddLoanReminderDayDialog(BuildContext context) async {
    final controller = TextEditingController();
    try {
      final existingDays = context.read<SettingsProvider>().loanReminderDays;
      final pickedDays = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          String? errorText;

          return StatefulBuilder(
            builder: (context, setState) {
              void submit() {
                final rawValue = controller.text.trim();
                final days = int.tryParse(rawValue);

                if (days == null ||
                    days < AppConstants.minLoanReminderDayOffset ||
                    days > AppConstants.maxLoanReminderDayOffset) {
                  setState(() {
                    errorText =
                        'Nhập số nguyên từ '
                        '${AppConstants.minLoanReminderDayOffset} đến '
                        '${AppConstants.maxLoanReminderDayOffset}';
                  });
                  return;
                }

                if (existingDays.contains(days)) {
                  setState(() {
                    errorText = 'Mốc nhắc này đã tồn tại';
                  });
                  return;
                }

                Navigator.pop(dialogContext, days);
              }

              return AlertDialog(
                title: const Text('Thêm mốc nhắc'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số ngày trước hạn',
                    hintText: 'Ví dụ: 7',
                    errorText: errorText,
                  ),
                  onSubmitted: (_) => submit(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(onPressed: submit, child: const Text('Thêm')),
                ],
              );
            },
          );
        },
      );

      if (pickedDays == null || !context.mounted) return;

      await context.read<SettingsProvider>().addLoanReminderDay(pickedDays);
    } catch (error, stackTrace) {
      debugPrint(
        'GeneralSettingsScreen._showAddLoanReminderDayDialog failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      controller.dispose();
    }
  }
}
