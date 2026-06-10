import 'dart:convert';

import 'package:coin_nest/database/backup_dao.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../debt/helpers/debt_database_fixture.dart';
import '../../debt/helpers/debt_ffi_database.dart';

void main() {
  late DebtDatabaseFixture fixture;
  late BackupDao backupDao;

  setUp(() async {
    fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
    backupDao = BackupDao();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('export chi lay du lieu tai chinh cua user hien tai', () async {
    await _insertLinkedFinancialData(fixture);
    final otherUserId = await fixture.insertOtherUser();
    await fixture.db.insert('accounts', {
      'user_id': otherUserId,
      'name': 'Other Cash',
      'type': 'cash',
      'balance': 999,
      'currency': 'VND',
      'icon_name': 'cash',
      'is_included_in_total': 1,
      'is_active': 1,
      'created_at': _now,
      'updated_at': _now,
    });

    final snapshot = await backupDao.createSnapshot(fixture.userId);

    expect(snapshot.formatVersion, BackupDao.formatVersion);
    expect(snapshot.recordCounts['accounts'], 1);
    expect(snapshot.recordCounts['loans'], 1);
    expect(snapshot.recordCounts['transactions'], 1);
    expect(snapshot.recordCounts['loan_payments'], 1);
    expect(snapshot.recordCounts['budgets'], 1);
    expect(
      (snapshot.payload['accounts'] as List).any(
        (row) => (row as Map)['user_id'] == otherUserId,
      ),
      isFalse,
    );
  });

  test('restore remap id va khoi phuc lien ket FK', () async {
    await _insertLinkedFinancialData(fixture);
    final snapshot = await backupDao.createSnapshot(fixture.userId);
    final oldAccountId = fixture.accountId!;

    await fixture.insertAccount(name: 'Temp Account', balance: 1);

    final result = await backupDao.restoreSnapshot(
      userId: fixture.userId,
      payload: snapshot.payload,
      expectedSha256: snapshot.payloadSha256,
    );

    expect(result.recordCounts['accounts'], 1);
    final accounts = await fixture.db.query(
      'accounts',
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
    );
    expect(accounts, hasLength(1));
    expect(accounts.single['id'], isNot(oldAccountId));
    expect(accounts.single['balance'], 1000);

    final loans = await fixture.db.query(
      'loans',
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
    );
    final transactions = await fixture.db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
    );
    final payments = await fixture.db.query(
      'loan_payments',
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
    );
    final budgets = await fixture.db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
    );

    expect(loans, hasLength(1));
    expect(transactions, hasLength(1));
    expect(payments, hasLength(1));
    expect(budgets, hasLength(1));
    expect(loans.single['transaction_id'], transactions.single['id']);
    expect(transactions.single['loan_id'], loans.single['id']);
    expect(payments.single['loan_id'], loans.single['id']);
    expect(payments.single['transaction_id'], transactions.single['id']);
    expect(budgets.single['account_id'], accounts.single['id']);
    expect(budgets.single['account_id'], isNot(oldAccountId));
    expect(
      budgets.single['category_id'],
      isNot(fixture.borrowInitialCategoryId),
    );
    expect(await fixture.db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('restore remap nhieu account, transfer va budget', () async {
    final secondAccountId = await fixture.insertAccount(
      name: 'Savings',
      balance: 2500,
    );
    await _insertLinkedFinancialData(fixture);
    await fixture.db.insert('transactions', {
      'user_id': fixture.userId,
      'account_id': fixture.accountId,
      'to_account_id': secondAccountId,
      'category_id': null,
      'type': 'transfer',
      'amount': 300,
      'note': 'backup transfer',
      'date': '2026-05-12',
      'time': '09:00',
      'loan_id': null,
      'created_at': _now,
      'updated_at': _now,
    });
    await fixture.db.insert('budgets', {
      'user_id': fixture.userId,
      'category_id': fixture.lendInitialCategoryId,
      'account_id': secondAccountId,
      'name': 'Savings Budget',
      'amount': 2000,
      'period': 'monthly',
      'start_date': '2026-05-01',
      'end_date': '2026-05-31',
      'is_active': 1,
      'created_at': _now,
      'updated_at': _now,
    });

    final snapshot = await backupDao.createSnapshot(fixture.userId);
    await fixture.insertAccount(name: 'Temp Account', balance: 1);

    final result = await backupDao.restoreSnapshot(
      userId: fixture.userId,
      payload: snapshot.payload,
      expectedSha256: snapshot.payloadSha256,
    );

    final accounts = await fixture.db.query(
      'accounts',
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
      orderBy: 'id ASC',
    );
    final transfer = (await fixture.db.query(
      'transactions',
      where: 'user_id = ? AND type = ?',
      whereArgs: [fixture.userId, 'transfer'],
    )).single;
    final budgets = await fixture.db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
      orderBy: 'id ASC',
    );

    expect(result.recordCounts['accounts'], 2);
    expect(result.recordCounts['transactions'], 2);
    expect(result.recordCounts['budgets'], 2);
    expect(accounts, hasLength(2));
    expect(transfer['account_id'], isNot(fixture.accountId));
    expect(transfer['to_account_id'], isNot(secondAccountId));
    expect(transfer['account_id'], accounts.first['id']);
    expect(transfer['to_account_id'], accounts.last['id']);
    expect(budgets.map((row) => row['account_id']).toSet(), {
      accounts.first['id'],
      accounts.last['id'],
    });
    expect(await fixture.db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('restore rollback khi checksum khong hop le', () async {
    await _insertLinkedFinancialData(fixture);
    final snapshot = await backupDao.createSnapshot(fixture.userId);

    expect(
      () => backupDao.restoreSnapshot(
        userId: fixture.userId,
        payload: snapshot.payload,
        expectedSha256: 'invalid',
      ),
      throwsA(isA<BackupDataException>()),
    );

    expect(await fixture.transactionCount(), 1);
    expect(await fixture.paymentCount(), 1);
  });

  test('restore rollback khi snapshot tham chieu id khong hop le', () async {
    await _insertLinkedFinancialData(fixture);
    final snapshot = await backupDao.createSnapshot(fixture.userId);
    final invalidPayload = Map<String, dynamic>.from(snapshot.payload)
      ..['accounts'] = <Map<String, dynamic>>[];
    final invalidSnapshot = BackupSnapshot(
      formatVersion: snapshot.formatVersion,
      sourceDbVersion: snapshot.sourceDbVersion,
      appVersion: snapshot.appVersion,
      payload: invalidPayload,
      payloadSha256: snapshot.payloadSha256,
      recordCounts: snapshot.recordCounts,
    );
    final expectedSha256 = sha256
        .convert(utf8.encode(jsonEncode(invalidSnapshot.payload)))
        .toString();

    expect(
      () => backupDao.restoreSnapshot(
        userId: fixture.userId,
        payload: invalidSnapshot.payload,
        expectedSha256: expectedSha256,
      ),
      throwsA(isA<BackupDataException>()),
    );

    expect(await fixture.transactionCount(), 1);
    expect(await fixture.paymentCount(), 1);
  });
}

const _now = '2026-05-30T10:00:00.000';

Future<void> _insertLinkedFinancialData(DebtDatabaseFixture fixture) async {
  final loanId = await fixture.db.insert('loans', {
    'user_id': fixture.userId,
    'type': 'borrow',
    'person_name': 'Alice',
    'amount': 500,
    'remaining_amount': 400,
    'interest_rate': 0,
    'interest_calculated': 0,
    'note': 'backup test',
    'start_date': '2026-05-01',
    'due_date': '2026-06-01',
    'status': 'active',
    'account_id': fixture.accountId,
    'transaction_id': null,
    'created_at': _now,
    'updated_at': _now,
  });
  final transactionId = await fixture.db.insert('transactions', {
    'user_id': fixture.userId,
    'account_id': fixture.accountId,
    'to_account_id': null,
    'category_id': fixture.borrowInitialCategoryId,
    'type': 'loan',
    'amount': 500,
    'note': 'backup test',
    'date': '2026-05-01',
    'time': '10:00',
    'loan_id': loanId,
    'created_at': _now,
    'updated_at': _now,
  });
  await fixture.db.update(
    'loans',
    {'transaction_id': transactionId},
    where: 'id = ?',
    whereArgs: [loanId],
  );
  await fixture.db.insert('loan_payments', {
    'loan_id': loanId,
    'user_id': fixture.userId,
    'transaction_id': transactionId,
    'amount': 100,
    'payment_date': '2026-05-10',
    'note': 'backup payment',
    'created_at': _now,
  });
  await fixture.db.insert('budgets', {
    'user_id': fixture.userId,
    'category_id': fixture.borrowInitialCategoryId,
    'account_id': fixture.accountId,
    'name': 'Debt Budget',
    'amount': 1000,
    'period': 'monthly',
    'start_date': '2026-05-01',
    'end_date': '2026-05-31',
    'is_active': 1,
    'created_at': _now,
    'updated_at': _now,
  });
}
