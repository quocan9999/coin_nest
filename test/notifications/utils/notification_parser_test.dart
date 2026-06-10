import 'package:coin_nest/models/account.dart';
import 'package:coin_nest/models/category.dart';
import 'package:coin_nest/utils/constants.dart';
import 'package:coin_nest/utils/notification_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationParser', () {
    final receivedAt = DateTime(2026, 6, 1, 23, 59);
    final accounts = [
      Account(
        id: 1,
        userId: 7,
        name: 'Ví chi',
        type: 'bank',
        createdAt: receivedAt,
        updatedAt: receivedAt,
      ),
      Account(
        id: 2,
        userId: 7,
        name: 'Ví thu',
        type: 'bank',
        createdAt: receivedAt,
        updatedAt: receivedAt,
      ),
    ];
    final expenseCategories = [
      Category(
        id: 10,
        userId: 7,
        name: 'Ăn uống',
        type: AppConstants.typeExpense,
        iconName: 'category',
        createdAt: receivedAt,
      ),
      Category(
        id: 11,
        userId: 7,
        name: AppConstants.autoExpenseCategoryName,
        type: AppConstants.typeExpense,
        iconName: 'auto_record',
        createdAt: receivedAt,
      ),
    ];
    final incomeCategories = [
      Category(
        id: 20,
        userId: 7,
        name: 'Lương',
        type: AppConstants.typeIncome,
        iconName: 'category',
        createdAt: receivedAt,
      ),
      Category(
        id: 21,
        userId: 7,
        name: AppConstants.autoIncomeCategoryName,
        type: AppConstants.typeIncome,
        iconName: 'auto_record',
        createdAt: receivedAt,
      ),
    ];

    test('parse thông báo VCB nhận tiền từ nội dung text', () {
      final result = _parse(
        title: 'Thông báo VCB',
        text:
            'Số dư TK VCB 1234567899 +5,000 VND lúc 01-06-2026 23:05:08. '
            'Số dư 5,141 VND. Ref 6152IBT1iJADSPUY.TRINH QUOC AN chuyen '
            'tien.20260601.230508.0123123123.TRINH QUOC AN.970432',
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        receivedAt: receivedAt,
      );

      expect(result?.type, AppConstants.typeIncome);
      expect(result?.amount, 5000);
      expect(result?.accountId, 2);
      expect(result?.categoryId, 21);
      expect(result?.note, 'TRINH QUOC AN chuyen tien');
      expect(result?.date, DateTime(2026, 6, 1, 23, 5, 8));
      expect(result?.time, '23:05');
    });

    test('parse thông báo VPBank nhận tiền từ title', () {
      final result = _parse(
        title: '+ 5,000 đ',
        text: '''
Tài khoản: 01******23
Số dư: 5,000 đ
CASHOUT 0123123123
1316118045363897ee539ae24d78bf9526ab941aaa65
''',
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        receivedAt: receivedAt,
      );

      expect(result?.type, AppConstants.typeIncome);
      expect(result?.amount, 5000);
      expect(result?.accountId, 2);
      expect(result?.note, 'CASHOUT 0123123123');
      expect(result?.date, receivedAt);
      expect(result?.time, '23:59');
    });

    test('parse thông báo VPBank trừ tiền từ title', () {
      final result = _parse(
        title: '- 5,000 đ',
        text: '''
Tài khoản: 01******23
Số dư: 0 đ
TRINH QUOC AN chuyen tien
''',
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        receivedAt: receivedAt,
      );

      expect(result?.type, AppConstants.typeExpense);
      expect(result?.amount, 5000);
      expect(result?.accountId, 1);
      expect(result?.categoryId, 11);
      expect(result?.note, 'TRINH QUOC AN chuyen tien');
    });

    test('parse thông báo MoMo nhận tiền theo từ khóa title', () {
      final result = _parse(
        title: 'Nhận tiền chuyển khoản từ TRINH QUOC AN',
        text: 'Số tiền 5.000 đ, kèm lời nhắn: "TRINH QUOC AN chuyen tien".',
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        receivedAt: receivedAt,
      );

      expect(result?.type, AppConstants.typeIncome);
      expect(result?.amount, 5000);
      expect(result?.accountId, 2);
      expect(result?.note, 'TRINH QUOC AN chuyen tien');
    });

    test('parse thông báo TPBank trừ tiền theo PS và ND', () {
      final result = _parse(
        title: 'TPBANK',
        text: '''
(TPBank): 01/06/26;18:00
TK: xxxx7385936
PS: -5.000VND
SD: 142VND
SD KHA DUNG: 142VND
ND: TRINH QUOC AN chuyen tien
SO GD: 868V00926152A2EX
''',
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        receivedAt: receivedAt,
      );

      expect(result?.type, AppConstants.typeExpense);
      expect(result?.amount, 5000);
      expect(result?.accountId, 1);
      expect(result?.note, 'TRINH QUOC AN chuyen tien');
      expect(result?.date, DateTime(2026, 6, 1, 18));
      expect(result?.time, '18:00');
    });

    test('parse thông báo MB Bank trừ tiền theo GD và ND', () {
      final result = _parse(
        title: 'Thông báo biến động số dư',
        text: '''
TK 09xxx125|GD: -20,000VND 01/06/26 07:30 |SD: 6,000,000VND|
ND:MOMO-CASHIN-0938173125-OQCITVTSPFQW-13148928206
''',
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        receivedAt: receivedAt,
      );

      expect(result?.type, AppConstants.typeExpense);
      expect(result?.amount, 20000);
      expect(result?.accountId, 1);
      expect(result?.note, 'MOMO-CASHIN-0938173125-OQCITVTSPFQW-13148928206');
      expect(result?.date, DateTime(2026, 6, 1, 7, 30));
      expect(result?.time, '07:30');
    });
  });
}

dynamic _parse({
  required String title,
  required String text,
  required List<Account> accounts,
  required List<Category> expenseCategories,
  required List<Category> incomeCategories,
  required DateTime receivedAt,
}) {
  return NotificationParser.parseNotification(
    notificationText: '$title\n$text',
    accounts: accounts,
    expenseCategories: expenseCategories,
    incomeCategories: incomeCategories,
    savedExpenseAccountId: 1,
    savedIncomeAccountId: 2,
    userId: 7,
    receivedAt: receivedAt,
  );
}
