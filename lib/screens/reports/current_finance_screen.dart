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
  State<CurrentFinanceScreen> createState() => _CurrentFinanceScreenState();
}

class _CurrentFinanceScreenState extends State<CurrentFinanceScreen> {
  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId != 0) {
      context.read<AccountProvider>().loadAccounts(userId);
      context.read<LoanProvider>().loadLoans(userId);
    }
  }

  IconData _getAccountIcon(Account acc) {
    switch (acc.type) {
      case 'cash':
        return Icons.wallet_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'e_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  Color _getAccountColor(Account acc) {
    if (acc.color != null && acc.color!.isNotEmpty) {
      try {
        return Color(int.parse(acc.color!.replaceAll('#', '0xFF')));
      } catch (_) {}
    }
    switch (acc.type) {
      case 'cash':
        return AppTheme.colors(context).income;
      case 'bank':
        return AppTheme.colors(context).primary;
      case 'e_wallet':
        return AppTheme.colors(context).transfer;
      case 'savings':
        return AppTheme.colors(context).warning;
      case 'credit_card':
        return AppTheme.colors(context).expense;
      default:
        return AppTheme.colors(context).primary;
    }
  }

  Future<void> _refreshData() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;
    await Future.wait([
      context.read<AccountProvider>().loadAccounts(userId),
      context.read<LoanProvider>().loadLoans(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final accountProv = context.watch<AccountProvider>();
    final loanProv = context.watch<LoanProvider>();

    final totalAssets = accountProv.accounts
        .where((a) => a.isIncludedInTotal)
        .fold<double>(0, (s, a) => s + a.balance);

    double totalDebt = 0;
    for (final loan in loanProv.loans.where(
      (l) => l.type == 'borrow' && l.status != 'paid',
    )) {
      totalDebt += loan.remainingAmount;
    }
    final totalLent = loanProv.loans
        .where((l) => l.type == 'lend' && l.status != 'paid')
        .fold<double>(0, (s, l) => s + l.remainingAmount);

    final netWorth = totalAssets + totalLent - totalDebt;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text('Tài chính hiện tại'),
        backgroundColor: AppTheme.colors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.colors(context).primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditAccountScreen()),
          ).then((_) {
            if (!context.mounted) return;
            if (context.read<AuthProvider>().currentUserId != 0) {
              context.read<AccountProvider>().loadAccounts(
                context.read<AuthProvider>().currentUserId,
              );
            }
          });
        },
        child: Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        color: AppTheme.colors(context).primary,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.colors(context).primary,
                      AppTheme.colors(context).transferBg,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.colors(
                        context,
                      ).primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Tổng tài sản ròng',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      Formatters.currency(netWorth),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sync_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.8),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Cập nhật hôm nay',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text(
                'TÀI KHOẢN',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textDisabled,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16),
              if (accountProv.isLoading)
                _buildSkeletonCards(count: 2)
              else ...[
                ...accountProv.accounts.map((acc) {
                  final iconColor = _getAccountColor(acc);
                  final amountColor = acc.balance < 0
                      ? AppTheme.colors(context).expense
                      : AppTheme.colors(context).income;
                  return _buildCard(
                    context: context,
                    icon: _getAccountIcon(acc),
                    iconBgColor: iconColor.withValues(alpha: 0.15),
                    iconColor: iconColor,
                    title: acc.name,
                    subtitle: acc.isIncludedInTotal
                        ? null
                        : 'Không tính vào tổng tài sản',
                    amount: acc.balance,
                    amountColor: acc.isIncludedInTotal
                        ? amountColor
                        : AppTheme.colors(context).textDisabled,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountDetailScreen(account: acc),
                        ),
                      ).then((_) {
                        if (!context.mounted) return;
                        final currentUserId = context
                            .read<AuthProvider>()
                            .currentUserId;
                        if (currentUserId != 0) {
                          context.read<AccountProvider>().loadAccounts(
                            currentUserId,
                          );
                        }
                      });
                    },
                  );
                }),
                if (accountProv.accounts.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có tài khoản'),
                    ),
                  ),
              ],
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tổng tài khoản: ${Formatters.currency(totalAssets)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'KHOẢN NỢ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textDisabled,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16),
              if (loanProv.isLoading)
                _buildSkeletonCards(count: 1)
              else ...[
                ...loanProv.loans
                    .where((l) => l.type == 'borrow' && l.status != 'paid')
                    .map((loan) {
                      return _buildCard(
                        context: context,
                        icon: Icons.person_rounded,
                        iconBgColor: AppTheme.colors(
                          context,
                        ).expense.withValues(alpha: 0.15),
                        iconColor: AppTheme.colors(context).expense,
                        title: '${loan.personName} - Vay',
                        subtitle: loan.dueDate != null
                            ? 'Hạn: ${Formatters.date(loan.dueDate!)}'
                            : null,
                        amount: loan.remainingAmount,
                        amountColor: AppTheme.colors(context).expense,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoanDetailScreen(loan: loan),
                            ),
                          ).then((_) {
                            if (!context.mounted) return;
                            final currentUserId = context
                                .read<AuthProvider>()
                                .currentUserId;
                            if (currentUserId != 0) {
                              context.read<LoanProvider>().loadLoans(
                                currentUserId,
                              );
                            }
                          });
                        },
                      );
                    }),
                if (loanProv.loans
                    .where((l) => l.type == 'borrow' && l.status != 'paid')
                    .isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không có khoản nợ'),
                    ),
                  ),
              ],
              if (totalDebt > 0)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Tổng nợ: ${Formatters.currency(totalDebt)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colors(context).expense,
                    ),
                  ),
                ),
              SizedBox(height: 32),
              Text(
                'KHOẢN CHO VAY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textDisabled,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16),
              if (loanProv.isLoading)
                _buildSkeletonCards(count: 1)
              else ...[
                ...loanProv.loans
                    .where((l) => l.type == 'lend' && l.status != 'paid')
                    .map((loan) {
                      return _buildCard(
                        context: context,
                        icon: Icons.person_rounded,
                        iconBgColor: AppTheme.colors(
                          context,
                        ).income.withValues(alpha: 0.15),
                        iconColor: AppTheme.colors(context).income,
                        title: '${loan.personName} - Cho vay',
                        subtitle: loan.dueDate != null
                            ? 'Hạn: ${Formatters.date(loan.dueDate!)}'
                            : null,
                        amount: loan.remainingAmount,
                        amountColor: AppTheme.colors(context).income,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoanDetailScreen(loan: loan),
                            ),
                          ).then((_) {
                            if (!context.mounted) return;
                            final currentUserId = context
                                .read<AuthProvider>()
                                .currentUserId;
                            if (currentUserId != 0) {
                              context.read<LoanProvider>().loadLoans(
                                currentUserId,
                              );
                            }
                          });
                        },
                      );
                    }),
                if (loanProv.loans
                    .where((l) => l.type == 'lend' && l.status != 'paid')
                    .isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không có khoản cho vay'),
                    ),
                  ),
              ],
              if (totalLent > 0)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Tổng cho vay: ${Formatters.currency(totalLent)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colors(context).income,
                    ),
                  ),
                ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCards({required int count}) {
    return Opacity(
      opacity: 0.5,
      child: Column(
        children: List.generate(
          count,
          (_) => Container(
            height: 72,
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.colors(context).input,
              borderRadius: BorderRadius.circular(12),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.colors(context).card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppTheme.colors(
                  context,
                ).textPrimary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
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
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 16),
              Text(
                Formatters.currency(amount.abs()),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
