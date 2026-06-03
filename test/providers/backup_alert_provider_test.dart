import 'package:coin_nest/providers/backup_alert_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tăng và reset số thay đổi chưa sao lưu theo từng user', () async {
    final provider = BackupAlertProvider();

    await provider.loadForUser(1);
    await provider.markChanged(1, source: 'transaction');
    await provider.markChanged(1, source: 'budget');

    expect(provider.pendingCount, 2);
    expect(provider.pendingTransactionCount, 1);
    expect(provider.hasPendingTransactions, isTrue);
    expect(provider.hasPendingChanges, isTrue);
    expect(provider.badgeLabel, '2');

    await provider.clearPending(1);

    expect(provider.pendingCount, 0);
    expect(provider.pendingTransactionCount, 0);
    expect(provider.hasPendingTransactions, isFalse);
    expect(provider.hasPendingChanges, isFalse);
  });

  test('badge hiển thị 99+ khi số thay đổi vượt giới hạn', () async {
    final provider = BackupAlertProvider();

    await provider.loadForUser(1);
    for (var i = 0; i < 105; i++) {
      await provider.markChanged(1);
    }

    expect(provider.badgeLabel, '99+');
  });

  test('cap nhat badge khi service danh dau giao dich tu dong', () async {
    final provider = BackupAlertProvider();

    await provider.loadForUser(1);
    await BackupAlertProvider.markUserChanged(1, source: 'transaction');
    await BackupAlertProvider.markUserChanged(1, source: 'transaction');

    expect(provider.pendingCount, 2);
    expect(provider.pendingTransactionCount, 2);
    expect(provider.badgeLabel, '2');
  });
}
