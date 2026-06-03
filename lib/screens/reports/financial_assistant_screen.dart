import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/financial_assistant.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/financial_assistant_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';

class FinancialAssistantScreen extends StatefulWidget {
  const FinancialAssistantScreen({super.key});

  @override
  State<FinancialAssistantScreen> createState() =>
      _FinancialAssistantScreenState();
}

class _FinancialAssistantScreenState extends State<FinancialAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadContext();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    final now = DateTime.now();
    await Future.wait([
      context.read<FinancialAssistantProvider>().loadHistory(userId),
      context.read<AccountProvider>().loadAccounts(userId),
      context.read<TransactionProvider>().loadTransactions(userId),
      context.read<LoanProvider>().loadLoans(userId),
      context.read<BudgetProvider>().loadBudgets(userId),
      context.read<ReportProvider>().loadReport(
        userId,
        from: DateTime(now.year, now.month),
        to: DateTime(now.year, now.month + 1, 0),
      ),
    ]);
  }

  Future<void> _sendQuestion(String question) async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    await context.read<FinancialAssistantProvider>().askQuestion(
      userId: userId,
      question: question,
      reportProvider: context.read<ReportProvider>(),
      transactionProvider: context.read<TransactionProvider>(),
      accounts: context.read<AccountProvider>().accounts,
      loans: context.read<LoanProvider>().loans,
      budgets: context.read<BudgetProvider>().budgets,
    );

    if (!mounted) return;
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = AppTheme.colors(context);
    final assistant = context.watch<FinancialAssistantProvider>();
    final userId = context.watch<AuthProvider>().currentUserId;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Trợ lý tài chính AI'),
        actions: [
          IconButton(
            tooltip: 'Xóa lịch sử',
            onPressed: userId == 0 || assistant.messages.isEmpty
                ? null
                : () => context.read<FinancialAssistantProvider>().clearHistory(
                    userId,
                  ),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing8,
                AppTheme.spacing8,
                AppTheme.spacing8,
                AppTheme.spacing12,
              ),
              children: [
                _buildHeader(context),
                const SizedBox(height: AppTheme.spacing8),
                if (assistant.messages.isEmpty)
                  _buildSuggestedQuestions(context, assistant)
                else ...[
                  for (final message in assistant.messages)
                    _MessageBubble(message: message),
                  if (assistant.isLoading) _buildLoadingBubble(context),
                  const SizedBox(height: AppTheme.spacing8),
                  _buildSuggestedQuestions(context, assistant),
                ],
              ],
            ),
          ),
          if (assistant.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing8,
                0,
                AppTheme.spacing8,
                AppTheme.spacing4,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacing6),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  assistant.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          Container(
            color: colors.card,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing8,
              AppTheme.spacing6,
              AppTheme.spacing8,
              AppTheme.spacing8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    enabled: !assistant.isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi tài chính',
                    ),
                    onSubmitted: assistant.isLoading
                        ? null
                        : (value) => _sendQuestion(value),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing6),
                FilledButton(
                  onPressed: assistant.isLoading
                      ? null
                      : () => _sendQuestion(_controller.text),
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    minimumSize: const Size(
                      AppTheme.spacing20,
                      AppTheme.spacing20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: assistant.isLoading
                      ? SizedBox(
                          width: AppTheme.spacing8,
                          height: AppTheme.spacing8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppTheme.spacing20,
            height: AppTheme.spacing20,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý tài chính AI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  'Dữ liệu tháng hiện tại',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions(
    BuildContext context,
    FinancialAssistantProvider assistant,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: AppTheme.spacing4,
      runSpacing: AppTheme.spacing4,
      children: assistant.suggestedQuestions.map((question) {
        return ActionChip(
          label: Text(
            question,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          backgroundColor: colorScheme.surfaceContainerLow,
          onPressed: assistant.isLoading ? null : () => _sendQuestion(question),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingBubble(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing6),
        padding: const EdgeInsets.all(AppTheme.spacing6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: SizedBox(
          width: AppTheme.spacing8,
          height: AppTheme.spacing8,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final FinancialAssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: AppTheme.spacing6),
        padding: const EdgeInsets.all(AppTheme.spacing8),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
