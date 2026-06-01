import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'add_edit_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoanListScreen extends StatefulWidget {
  final String? initialType;
  final bool selectForPayment;

  const LoanListScreen({
    super.key,
    this.initialType,
    this.selectForPayment = false,
  });

  @override
  State<LoanListScreen> createState() =>
      _LoanListScreenState();
}

class _LoanListScreenState
    extends State<LoanListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
          if (!mounted) return;

          final userId =
              context
                  .read<AuthProvider>()
                  .currentUserId;

          context
              .read<LoanProvider>()
              .loadLoans(userId);
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final loanProv = context.watch<LoanProvider>();
    final visibleLoans = loanProv.loans.where((loan) {
      final matchesType =
          widget.initialType == null || loan.type == widget.initialType;
      final matchesPaymentFlow = !widget.selectForPayment || !loan.isPaid;
      return matchesType && matchesPaymentFlow;
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,

      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,

        title: Text(_screenTitle),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
          ),

          onPressed:
              () => Navigator.pop(context),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primary,
            ),

            onPressed: _openAddLoan,
          ),
        ],
      ),

      body: Column(
        children: [
          // SUMMARY
          Padding(
            padding: const EdgeInsets.all(20),

            child: Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    context,
                    'Đang vay',
                    loanProv.summary['borrowed'] ??
                        0,
                    AppTheme.tertiary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _summaryCard(
                    context,
                    'Cho vay',
                    loanProv.summary['lent'] ?? 0,
                    AppTheme.loanColor,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                visibleLoans.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Icon(
                            Icons
                                .handshake_outlined,

                            size: 56,

                            color: colorScheme
                                .outlineVariant,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            _emptyStateText,

                            style: TextStyle(
                              color: colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),

                      itemCount:
                          visibleLoans.length,

                      itemBuilder: (_, i) {
                        final loan =
                            visibleLoans[i];

                        return GestureDetector(
                          onTap:
                              () => _openLoanDetail(
                                loan,
                              ),

                          child: Container(
                            margin:
                                const EdgeInsets.only(
                                  bottom: 10,
                                ),

                            padding:
                                const EdgeInsets.all(
                                  16,
                                ),

                            decoration: BoxDecoration(
                              color:
                                  colorScheme
                                      .surfaceContainerLowest,

                              borderRadius:
                                  BorderRadius.circular(
                                    AppTheme
                                        .radiusMd,
                                  ),
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                            horizontal:
                                                8,
                                            vertical:
                                                3,
                                          ),

                                      decoration: BoxDecoration(
                                        color:
                                            loan.type ==
                                                    'borrow'
                                                ? AppTheme
                                                    .tertiary
                                                    .withAlpha(
                                                      20,
                                                    )
                                                : AppTheme
                                                    .loanColor
                                                    .withAlpha(
                                                      20,
                                                    ),

                                        borderRadius:
                                            BorderRadius.circular(
                                              AppTheme
                                                  .radiusSm,
                                            ),
                                      ),

                                      child: Text(
                                        loan.type ==
                                                'borrow'
                                            ? 'Vay'
                                            : 'Cho vay',

                                        style: TextStyle(
                                          fontSize:
                                              11,

                                          fontWeight:
                                              FontWeight
                                                  .w600,

                                          color:
                                              loan.type ==
                                                      'borrow'
                                                  ? AppTheme
                                                      .tertiary
                                                  : AppTheme
                                                      .loanColor,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    _statusBadge(
                                      context,
                                      loan,
                                    ),

                                    const Spacer(),

                                    Text(
                                      Formatters
                                          .currency(
                                            loan
                                                .remainingAmount,
                                          ),

                                      style:
                                          theme
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  loan.personName,

                                  style:
                                      theme
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                LinearProgressIndicator(
                                  value:
                                      (loan.paidPercentage /
                                              100)
                                          .clamp(
                                            0,
                                            1,
                                          ),

                                  backgroundColor:
                                      colorScheme
                                          .outlineVariant
                                          .withAlpha(
                                            50,
                                          ),

                                  valueColor:
                                      AlwaysStoppedAnimation(
                                        loan.type ==
                                                'borrow'
                                            ? AppTheme
                                                .tertiary
                                            : AppTheme
                                                .loanColor,
                                      ),

                                  borderRadius:
                                      BorderRadius.circular(
                                        AppTheme
                                            .radiusSm,
                                      ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  '${Formatters.percent(loan.paidPercentage)} đã trả • ${Formatters.date(loan.startDate)}',

                                  style:
                                      theme
                                          .textTheme
                                          .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    final userId =
        context.read<AuthProvider>().currentUserId;

    await context
        .read<LoanProvider>()
        .loadLoans(userId);
  }

  Future<void> _openAddLoan() async {
    final changed =
        await Navigator.push<bool>(
          context,

          MaterialPageRoute(
            builder:
                (_) =>
                    AddEditLoanScreen(
                      initialType: widget.initialType,
                    ),
          ),
        );

    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openLoanDetail(
    dynamic loan,
  ) async {
    final changed =
        await Navigator.push<bool>(
          context,

          MaterialPageRoute(
            builder:
                (_) =>
                    LoanDetailScreen(
                      loan: loan,
                    ),
          ),
        );

    if (changed == true) {
      await _refresh();
    }
  }

  String get _screenTitle {
    if (widget.selectForPayment && widget.initialType == 'borrow') {
      return 'Chọn khoản cần trả';
    }
    if (widget.selectForPayment && widget.initialType == 'lend') {
      return 'Chọn khoản cần thu';
    }
    return 'Vay / Cho vay';
  }

  String get _emptyStateText {
    if (widget.initialType == 'borrow') {
      return 'Chưa có khoản vay nào';
    }
    if (widget.initialType == 'lend') {
      return 'Chưa có khoản cho vay nào';
    }
    return 'Chưa có khoản vay nào';
  }

  Widget _statusBadge(
    BuildContext context,
    dynamic loan,
  ) {
    final label =
        loan.isPaid
            ? 'Đã trả'
            : (loan.isOverdue
                ? 'Quá hạn'
                : 'Đang hoạt động');

    final color =
        loan.isPaid
            ? AppTheme.secondary
            : (loan.isOverdue
                ? AppTheme.tertiary
                : AppTheme.primary);

    return Container(
      padding:
          const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),

      decoration: BoxDecoration(
        color: color.withAlpha(18),

        borderRadius:
            BorderRadius.circular(6),
      ),

      child: Text(
        label,

        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: color.withAlpha(15),

        borderRadius: BorderRadius.circular(
          AppTheme.radiusMd,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style: theme.textTheme.labelMedium
                ?.copyWith(color: color),
          ),

          const SizedBox(height: 4),

          Text(
            Formatters.currency(amount),

            style: theme.textTheme.titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
