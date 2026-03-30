import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Cài đặt chung'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle(context, 'HIỂN THỊ'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            SwitchListTile(
              title: const Text('Hiện số dư'), subtitle: const Text('Hiển thị số dư trên trang tổng quan'),
              value: settings.showBalance, onChanged: settings.setShowBalance, activeTrackColor: AppTheme.primary,
            ),
          ]),
          const SizedBox(height: 20),

          _sectionTitle(context, 'NHẮC NHỞ'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            SwitchListTile(
              title: const Text('Nhắc nhở ghi chép'), subtitle: const Text('Nhắc bạn ghi chép mỗi ngày'),
              value: settings.dailyReminder, onChanged: settings.setDailyReminder, activeTrackColor: AppTheme.primary,
            ),
          ]),
          const SizedBox(height: 20),

          _sectionTitle(context, 'ĐƠN VỊ TIỀN TỆ'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            ListTile(
              title: const Text('Đơn vị tiền tệ'),
              trailing: Text(settings.currency, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),

          _sectionTitle(context, 'THÔNG TIN'),
          const SizedBox(height: 8),
          _settingsCard(children: [
            const ListTile(title: Text('Phiên bản'), trailing: Text('1.0.0', style: TextStyle(color: AppTheme.onSurfaceVariant))),
            const Divider(height: 1),
            const ListTile(title: Text('Liên hệ hỗ trợ'), trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.outline)),
          ]),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 1));
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
