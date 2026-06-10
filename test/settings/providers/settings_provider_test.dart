import 'package:coin_nest/providers/settings_provider.dart';
import 'package:coin_nest/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('lưu và tải lại cài đặt nhắc nhở', () async {
    final settings = SettingsProvider();

    await settings.setDailyReminder(true);
    await settings.setDebtReminder(true);
    await settings.setReminderTime('21:30');

    final reloaded = SettingsProvider();
    await reloaded.loadSettings();

    expect(reloaded.dailyReminder, isTrue);
    expect(reloaded.debtReminder, isTrue);
    expect(reloaded.reminderTime, '21:30');
  });

  test('dùng giờ nhắc mặc định khi chưa có cấu hình', () async {
    final settings = SettingsProvider();

    await settings.loadSettings();

    expect(settings.reminderTime, AppConstants.defaultReminderTime);
    expect(settings.dailyReminder, isFalse);
    expect(settings.debtReminder, isFalse);
  });
}
