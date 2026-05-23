import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account.dart';

import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';

import '../../screens/accounts/add_edit_account_screen.dart';
import '../../screens/accounts/account_detail_screen.dart';

import '../../screens/loans/loan_detail_screen.dart';

import '../../theme/app_theme.dart';

import '../../utils/formatters.dart';

class CurrentFinanceScreen extends StatefulWidget {
  const CurrentFinanceScreen({super.key});

  @override
  State<CurrentFinanceScreen> createState() =>
      _CurrentFinanceScreenState();
}

class _CurrentFinanceScreenState
    extends State<CurrentFinanceScreen> {
  @override
  void initState() {
    super.initState();

    final userId =
        context.read<AuthProvider>().currentUserId;

    if (userId != 0) {
      context
          .read<AccountProvider>()
          .loadAccounts(userId);

      context
          .read<LoanProvider>()
          .loadLoans(userId);
    }
  }

  IconData _getAccountIcon(Account acc) {
    switch (acc.type) {
      case 'cash':
        return Icons.wallet_rounded;

      case 'bank':
        return Icons.account_balance_rounded;

      case 'e_wallet':
        return Icons
            .account_balance_wallet_rounded;

      case 'savings':
        return Icons.savings_rounded;

      case 'credit_card':
        return Icons.credit_card_rounded;

      default:
        return Icons.savings_rounded;
    }
  }

  Color _getAccountColor(Account acc) {
    if (acc.color != null &&
        acc.color!.isNotEmpty) {
      try {
        return Color(
          int.parse(
            acc.color!.replaceAll(
              '#',
              '0xFF',
            ),
          ),
        );
      } catch (_) {}
    }

    switch (acc.type) {
      case 'cash':
        return AppTheme.secondary;

      case 'bank':
        return AppTheme.primary;

      case 'e_wallet':
        return const Color(0xFF9C27B0);

      case 'savings':
        return const Color(0xFFFF9800);

      case 'credit_card':
        return const Color(0xFFE53935);

      default:
        return AppTheme.primary;
    }
  }

  Future<void> _refreshData() async {
    final userId =
        context.read<AuthProvider>().currentUserId;

    if (userId == 0) return;

    await Future.wait([
      context
          .read<AccountProvider>()
          .loadAccounts(userId),

      context
          .read<LoanProvider>()
          .loadLoans(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final accountProv =
        context.watch<AccountProvider>();

    final loanProv =
        context.watch<LoanProvider>();

    final totalAssets =
        accountProv.accounts
            .where(
              (a) => a.isIncludedInTotal,
            )
            .fold<double>(
              0,
              (s, a) => s + a.balance,
            );

    double totalDebt = 0;

    for (final loan in loanProv.loans.where(
      (l) =>
          l.type == 'borrow' &&
          l.status != 'paid',
    )) {
      totalDebt += loan.remainingAmount;
    }

    final totalLent =
        loanProv.loans
            .where(
              (l) =>
                  l.type == 'lend' &&
                  l.status != 'paid',
            )
            .fold<double>(
              0,
              (s, l) =>
                  s + l.remainingAmount,
            );

    final netWorth =
        totalAssets +
        totalLent -
        totalDebt;

    return Scaffold(
      backgroundColor:
          colorScheme.surface,

      appBar: AppBar(
        backgroundColor:
            colorScheme.surface,

        elevation: 0,

        centerTitle: true,

        title: const Text(
          'Tài chính hiện tại',
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
            backgroundColor:
                AppTheme.primary,

            foregroundColor:
                Colors.white,

            onPressed: () {
              Navigator.push(
                context,

                MaterialPageRoute(
                  builder:
                      (_) =>
                          const AddEditAccountScreen(),
                ),
              ).then((_) {
                if (!context.mounted) {
                  return;
                }

                if (context
                        .read<AuthProvider>()
                        .currentUserId !=
                    0) {
                  context
                      .read<AccountProvider>()
                      .loadAccounts(
                        context
                            .read<
                              AuthProvider
                            >()
                            .currentUserId,
                      );
                }
              });
            },

            child: const Icon(
              Icons.add_rounded,
            ),
          ),

      body: RefreshIndicator(
        color: AppTheme.primary,

        onRefresh: _refreshData,

        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              // HEADER
              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(
                      24,
                    ),

                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme
                              .primaryContainer,
                        ],

                        begin:
                            Alignment
                                .topLeft,

                        end: Alignment
                            .bottomRight,
                      ),

                  borderRadius:
                      BorderRadius.circular(
                        AppTheme.radiusLg,
                      ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          AppTheme.primary
                              .withValues(
                                alpha: 0.3,
                              ),

                      blurRadius: 15,

                      offset:
                          const Offset(
                            0,
                            8,
                          ),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    Text(
                      'Tổng tài sản ròng',

                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: Colors.white
                                .withValues(
                                  alpha: 0.9,
                                ),
                          ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      Formatters.currency(
                        netWorth,
                      ),

                      style: theme
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w700,

                            color:
                                Colors
                                    .white,
                          ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Icon(
                          Icons
                              .sync_rounded,

                          color: Colors
                              .white
                              .withValues(
                                alpha: 0.8,
                              ),

                          size: 14,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          'Cập nhật hôm nay',

                          style: theme
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: Colors
                                    .white
                                    .withValues(
                                      alpha:
                                          0.8,
                                    ),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ACCOUNT TITLE
              Text(
                'TÀI KHOẢN',

                style: theme
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,

                      color: colorScheme
                          .outline,

                      letterSpacing:
                          1.2,
                    ),
              ),

              const SizedBox(height: 16),

              if (accountProv.isLoading)
                _buildSkeletonCards(
                  count: 2,
                )
              else ...[
                ...accountProv.accounts.map((
                  acc,
                ) {
                  final iconColor =
                      _getAccountColor(acc);

                  final amountColor =
                      acc.balance < 0
                          ? AppTheme
                              .tertiary
                          : AppTheme
                              .secondary;

                  return _buildCard(
                    context: context,

                    icon:
                        _getAccountIcon(
                          acc,
                        ),

                    iconBgColor:
                        iconColor
                            .withValues(
                              alpha: 0.15,
                            ),

                    iconColor:
                        iconColor,

                    title: acc.name,

                    subtitle:
                        acc.isIncludedInTotal
                            ? null
                            : 'Không tính vào tổng tài sản',

                    amount:
                        acc.balance,

                    amountColor:
                        acc.isIncludedInTotal
                            ? amountColor
                            : colorScheme
                                .outline,

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  AccountDetailScreen(
                                    account:
                                        acc,
                                  ),
                        ),
                      ).then((_) {
                        if (!context
                            .mounted) {
                          return;
                        }

                        final currentUserId =
                            context
                                .read<
                                  AuthProvider
                                >()
                                .currentUserId;

                        if (currentUserId !=
                            0) {
                          context
                              .read<
                                AccountProvider
                              >()
                              .loadAccounts(
                                currentUserId,
                              );
                        }
                      });
                    },
                  );
                }),

                if (accountProv
                    .accounts
                    .isEmpty)
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                            16,
                          ),

                      child: Text(
                        'Chưa có tài khoản',

                        style: TextStyle(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                      vertical: 8,
                    ),

                child: Text(
                  'Tổng tài khoản: ${Formatters.currency(totalAssets)}',

                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                ),
              ),

              const SizedBox(height: 32),

              // DEBT
              Text(
                'KHOẢN NỢ',

                style: theme
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,

                      color: colorScheme
                          .outline,

                      letterSpacing:
                          1.2,
                    ),
              ),

              const SizedBox(height: 16),

              if (loanProv.isLoading)
                _buildSkeletonCards(
                  count: 1,
                )
              else ...[
                ...loanProv.loans
                    .where(
                      (l) =>
                          l.type ==
                              'borrow' &&
                          l.status !=
                              'paid',
                    )
                    .map((loan) {
                      return _buildCard(
                        context: context,

                        icon:
                            Icons
                                .person_rounded,

                        iconBgColor:
                            AppTheme
                                .tertiary
                                .withValues(
                                  alpha:
                                      0.15,
                                ),

                        iconColor:
                            AppTheme
                                .tertiary,

                        title:
                            '${loan.personName} - Vay',

                        subtitle:
                            loan.dueDate !=
                                    null
                                ? 'Hạn: ${Formatters.date(loan.dueDate!)}'
                                : null,

                        amount:
                            loan
                                .remainingAmount,

                        amountColor:
                            AppTheme
                                .tertiary,

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      LoanDetailScreen(
                                        loan:
                                            loan,
                                      ),
                            ),
                          );
                        },
                      );
                    }),

                if (loanProv.loans
                    .where(
                      (l) =>
                          l.type ==
                              'borrow' &&
                          l.status !=
                              'paid',
                    )
                    .isEmpty)
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                            16,
                          ),

                      child: Text(
                        'Không có khoản nợ',

                        style: TextStyle(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],

              if (totalDebt > 0)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                        vertical: 8,
                      ),

                  child: Text(
                    'Tổng nợ: ${Formatters.currency(totalDebt)}',

                    style: theme
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w600,

                          color:
                              AppTheme
                                  .tertiary,
                        ),
                  ),
                ),

              const SizedBox(height: 32),

              // LEND
              Text(
                'KHOẢN CHO VAY',

                style: theme
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,

                      color: colorScheme
                          .outline,

                      letterSpacing:
                          1.2,
                    ),
              ),

              const SizedBox(height: 16),

              if (loanProv.isLoading)
                _buildSkeletonCards(
                  count: 1,
                )
              else ...[
                ...loanProv.loans
                    .where(
                      (l) =>
                          l.type ==
                              'lend' &&
                          l.status !=
                              'paid',
                    )
                    .map((loan) {
                      return _buildCard(
                        context: context,

                        icon:
                            Icons
                                .person_rounded,

                        iconBgColor:
                            AppTheme
                                .secondary
                                .withValues(
                                  alpha:
                                      0.15,
                                ),

                        iconColor:
                            AppTheme
                                .secondary,

                        title:
                            '${loan.personName} - Cho vay',

                        subtitle:
                            loan.dueDate !=
                                    null
                                ? 'Hạn: ${Formatters.date(loan.dueDate!)}'
                                : null,

                        amount:
                            loan
                                .remainingAmount,

                        amountColor:
                            AppTheme
                                .secondary,

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      LoanDetailScreen(
                                        loan:
                                            loan,
                                      ),
                            ),
                          );
                        },
                      );
                    }),

                if (loanProv.loans
                    .where(
                      (l) =>
                          l.type ==
                              'lend' &&
                          l.status !=
                              'paid',
                    )
                    .isEmpty)
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                            16,
                          ),

                      child: Text(
                        'Không có khoản cho vay',

                        style: TextStyle(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],

              // SUMMARY
              Container(
                margin:
                    const EdgeInsets.only(
                      top: 8,
                    ),

                padding:
                    const EdgeInsets.all(
                      20,
                    ),

                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(
                        colors: [
                          AppTheme
                              .primaryContainer,
                          colorScheme
                              .surface,
                        ],

                        begin:
                            Alignment
                                .topLeft,

                        end: Alignment
                            .bottomRight,
                      ),

                  borderRadius:
                      BorderRadius.circular(
                        AppTheme.radiusLg,
                      ),
                ),

                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                'Tổng tài sản',

                                style: theme
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                Formatters.currency(
                                  totalAssets,
                                ),

                                style: theme
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .secondary,

                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),

                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                'Cho vay',

                                style: theme
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                Formatters.currency(
                                  totalLent,
                                ),

                                style: theme
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .secondary,

                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),

                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                'Tổng nợ',

                                style: theme
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                '- ${Formatters.currency(totalDebt)}',

                                style: theme
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .tertiary,

                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),

                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                'Tài sản ròng',

                                style: theme
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                Formatters.currency(
                                  netWorth,
                                ),

                                style: theme
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color:
                                          netWorth >=
                                                  0
                                              ? AppTheme
                                                  .secondary
                                              : AppTheme
                                                  .tertiary,

                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),

                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCards({
    required int count,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Opacity(
      opacity: 0.5,

      child: Column(
        children: List.generate(
          count,

          (_) => Container(
            height: 72,
            width: double.infinity,

            margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),

            decoration: BoxDecoration(
              color:
                  colorScheme
                      .surfaceContainerHigh,

              borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    String? subtitle,
    required double amount,
    required Color amountColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
              AppTheme.radiusLg,
            ),

        onTap: onTap,

        child: Container(
          margin:
              const EdgeInsets.only(
                bottom: 12,
              ),

          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: colorScheme
                .surfaceContainerLowest,

            borderRadius:
                BorderRadius.circular(
                  AppTheme.radiusLg,
                ),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                      alpha: 0.04,
                    ),

                blurRadius: 10,

                offset: const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),

          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      title,

                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                    ),

                    if (subtitle !=
                        null) ...[
                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        subtitle,

                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Text(
                Formatters.currency(
                  amount.abs(),
                ),

                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,

                      color:
                          amountColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}