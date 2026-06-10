import 'package:coin_nest/models/account.dart';
import 'package:coin_nest/models/budget.dart';
import 'package:coin_nest/models/financial_assistant.dart';
import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/providers/financial_assistant_provider.dart';
import 'package:coin_nest/providers/report_provider.dart';
import 'package:coin_nest/providers/transaction_provider.dart';
import 'package:coin_nest/services/financial_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('buildRequest gửi tóm tắt tài chính, không gửi toàn bộ giao dịch', () {
    final provider = FinancialAssistantProvider();
    final now = DateTime(2026, 6, 4);

    final request = provider.buildRequest(
      userId: 7,
      question: 'Tôi có đang chi quá nhiều không?',
      reportProvider: ReportProvider(),
      transactionProvider: TransactionProvider(),
      accounts: [
        _account(balance: 12000000, isIncludedInTotal: true),
        _account(balance: 3000000, isIncludedInTotal: false),
      ],
      loans: [
        _loan(
          type: 'borrow',
          remainingAmount: 2500000,
          interestOutstanding: 100000,
        ),
        _loan(
          type: 'lend',
          remainingAmount: 1000000,
          interestOutstanding: 50000,
        ),
      ],
      budgets: [
        _budget(amount: 2000000, spentAmount: 2500000),
        _budget(amount: 5000000, spentAmount: 1000000),
      ],
      now: now,
      recentMessages: [
        FinancialAssistantMessage(
          role: 'user',
          content: 'Câu hỏi cũ',
          createdAt: now,
        ),
      ],
    );

    expect(request.userId, '7');
    expect(request.period, '2026-06');
    expect(request.reportSummary['accountBalance'], 12000000);
    expect(request.debtSummary?['borrowedRemaining'], 2600000);
    expect(request.debtSummary?['borrowedPrincipalRemaining'], 2500000);
    expect(request.debtSummary?['borrowedInterestOutstanding'], 100000);
    expect(request.debtSummary?['borrowedTotalOutstanding'], 2600000);
    expect(request.debtSummary?['lentRemaining'], 1050000);
    expect(request.debtSummary?['lentPrincipalRemaining'], 1000000);
    expect(request.debtSummary?['lentInterestOutstanding'], 50000);
    expect(request.debtSummary?['lentTotalOutstanding'], 1050000);
    expect(request.budgetSummary?['exceededCount'], 1);
    expect(request.recentMessages.single.content, 'Câu hỏi cũ');
    expect(request.toJson(), isNot(contains('transactions')));
  });

  test('askQuestion lưu và nạp lại lịch sử chat theo user', () async {
    final service = _FakeFinancialAssistantService();
    final provider = FinancialAssistantProvider(service: service);

    await provider.askQuestion(
      userId: 9,
      question: 'Tôi nên tiết kiệm ở khoản nào?',
      reportProvider: ReportProvider(),
      transactionProvider: TransactionProvider(),
      accounts: [_account(balance: 8000000)],
      loans: [],
      budgets: [],
    );

    expect(service.capturedRequest?.question, 'Tôi nên tiết kiệm ở khoản nào?');
    expect(provider.messages, hasLength(2));
    expect(provider.messages.first.role, 'user');
    expect(
      provider.messages.last.content,
      'Nên ưu tiên giảm chi tiêu ăn uống.',
    );
    expect(
      provider.suggestedQuestions.single,
      'Tôi nên đặt ngân sách bao nhiêu?',
    );

    final reloaded = FinancialAssistantProvider(service: service);
    await reloaded.loadHistory(9);

    expect(reloaded.messages, hasLength(2));
    expect(
      reloaded.messages.last.content,
      'Nên ưu tiên giảm chi tiêu ăn uống.',
    );
  });
}

class _FakeFinancialAssistantService implements FinancialAssistantService {
  FinancialAssistantRequest? capturedRequest;

  @override
  bool get isConfigured => true;

  @override
  Future<bool> isConfiguredAsync() async => true;

  @override
  Future<FinancialAssistantResponse> ask(
    FinancialAssistantRequest request,
  ) async {
    capturedRequest = request;
    return FinancialAssistantResponse(
      answer: 'Nên ưu tiên giảm chi tiêu ăn uống.',
      suggestedQuestions: ['Tôi nên đặt ngân sách bao nhiêu?'],
      model: 'fake-model',
      generatedAt: DateTime(2026, 6, 4, 10),
    );
  }
}

Account _account({required double balance, bool isIncludedInTotal = true}) {
  final now = DateTime(2026, 6, 4);
  return Account(
    userId: 1,
    name: 'Ví chính',
    type: 'cash',
    balance: balance,
    isIncludedInTotal: isIncludedInTotal,
    createdAt: now,
    updatedAt: now,
  );
}

Loan _loan({
  required String type,
  required double remainingAmount,
  double interestOutstanding = 0,
}) {
  final now = DateTime(2026, 6, 4);
  return Loan(
    userId: 1,
    type: type,
    personName: 'Bạn A',
    amount: remainingAmount,
    remainingAmount: remainingAmount,
    interestOutstanding: interestOutstanding,
    startDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

Budget _budget({required double amount, required double spentAmount}) {
  final now = DateTime(2026, 6, 4);
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
