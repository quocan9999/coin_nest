import 'package:coin_nest/models/budget.dart';
import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/models/transaction_model.dart';
import 'package:coin_nest/providers/ai_spending_insight_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildMonthlyRequest chỉ tổng hợp giao dịch trong tháng hiện tại', () {
    final provider = AiSpendingInsightProvider();
    final now = DateTime(2026, 6, 3);

    final request = provider.buildMonthlyRequest(
      userId: 7,
      totalBalance: 12000000,
      now: now,
      transactions: [
        _txn(type: 'income', amount: 10000000, date: DateTime(2026, 6, 1)),
        _txn(
          type: 'expense',
          amount: 2500000,
          date: DateTime(2026, 6, 2),
          categoryName: 'Ăn uống',
        ),
        _txn(
          type: 'expense',
          amount: 1000000,
          date: DateTime(2026, 5, 30),
          categoryName: 'Mua sắm',
        ),
      ],
      loans: [
        _loan(type: 'borrow', remainingAmount: 3000000),
        _loan(
          type: 'lend',
          remainingAmount: 2000000,
          dueDate: DateTime(2026, 5, 1),
        ),
      ],
      budgets: [
        _budget(amount: 2000000, spentAmount: 2500000),
        _budget(amount: 5000000, spentAmount: 1000000),
      ],
    );

    expect(request.period, '2026-06');
    expect(request.totalIncome, 10000000);
    expect(request.totalExpense, 2500000);
    expect(request.topExpenseCategories, hasLength(1));
    expect(request.topExpenseCategories.first['name'], 'Ăn uống');
    expect(request.debtSummary?['borrowedRemaining'], 3000000);
    expect(request.debtSummary?['lentRemaining'], 2000000);
    expect(request.debtSummary?['overdueCount'], 1);
    expect(request.budgetSummary?['exceededCount'], 1);
  });
}

TransactionModel _txn({
  required String type,
  required double amount,
  required DateTime date,
  String? categoryName,
}) {
  return TransactionModel(
    userId: 1,
    accountId: 1,
    type: type,
    amount: amount,
    date: date,
    createdAt: date,
    updatedAt: date,
    categoryName: categoryName,
  );
}

Loan _loan({
  required String type,
  required double remainingAmount,
  DateTime? dueDate,
}) {
  final now = DateTime(2026, 6, 3);

  return Loan(
    userId: 1,
    type: type,
    personName: 'Bạn A',
    amount: remainingAmount,
    remainingAmount: remainingAmount,
    startDate: now,
    dueDate: dueDate,
    createdAt: now,
    updatedAt: now,
  );
}

Budget _budget({required double amount, required double spentAmount}) {
  final now = DateTime(2026, 6, 3);

  return Budget(
    userId: 1,
    name: 'Ăn uống',
    amount: amount,
    startDate: now,
    spentAmount: spentAmount,
    createdAt: now,
    updatedAt: now,
  );
}
