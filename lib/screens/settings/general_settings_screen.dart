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
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text('Cài đặt chung'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _sectionTitle(context, 'HIỂN THỊ'),
          SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              SwitchListTile(
                title: Text('Hiện số dư'),
                subtitle: Text('Hiển thị số dư trên trang tổng quan'),
                value: settings.showBalance,
                onChanged: settings.setShowBalance,
              ),
              SwitchListTile(
                title: Text('Giao diện tối'),
                subtitle: Text('Bật chế độ nền tối'),
                value: settings.isDarkMode,
                onChanged: settings.setDarkMode,
              ),
            ],
          ),
          SizedBox(height: 20),

          _sectionTitle(context, 'NHẮC NHỞ'),
          SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              SwitchListTile(
                title: Text('Nhắc nhở ghi chép'),
                subtitle: Text('Nhắc bạn ghi chép mỗi ngày'),
                value: settings.dailyReminder,
                onChanged: settings.setDailyReminder,
              ),
            ],
          ),
          SizedBox(height: 20),

          _sectionTitle(context, 'ĐƠN VỊ TIỀN TỆ'),
          SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              ListTile(
                title: Text('Đơn vị tiền tệ'),
                trailing: Text(
                  settings.currency,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colors(context).primary,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: 20),

          _sectionTitle(context, 'THÔNG TIN'),
          SizedBox(height: 8),
          _settingsCard(
            context,
            children: [
              ListTile(
                title: Text('Phiên bản'),
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: AppTheme.colors(context).textSecondary,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                title: Text('Liên hệ hỗ trợ'),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.colors(context).textDisabled,
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
        color: AppTheme.colors(context).textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _settingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
