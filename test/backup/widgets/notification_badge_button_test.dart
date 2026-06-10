import 'package:coin_nest/providers/backup_alert_provider.dart';
import 'package:coin_nest/widgets/notification_badge_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ẩn badge khi không có thay đổi chưa sao lưu', (tester) async {
    final provider = BackupAlertProvider();
    await provider.loadForUser(1);

    await tester.pumpWidget(_host(provider));

    expect(find.text('1'), findsNothing);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('hiển thị số thay đổi trên badge', (tester) async {
    final provider = BackupAlertProvider();
    await provider.loadForUser(1);
    await provider.markChanged(1);

    await tester.pumpWidget(_host(provider));

    expect(find.text('1'), findsOneWidget);
  });
}

Widget _host(BackupAlertProvider provider) {
  return ChangeNotifierProvider<BackupAlertProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(body: NotificationBadgeButton(onPressed: () {})),
    ),
  );
}
