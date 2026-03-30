import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final accountProv = context.watch<AccountProvider>();
    final loanProv = context.watch<LoanProvider>();

    final totalAssets = accountProv.accounts.fold<double>(0, (s, a) => s + a.balance);
    
    // Total debt: sum of unpaid borrow amounts
    double totalDebt = 0;
    for (var loan in loanProv.loans.where((l) => l.type == 'borrow' && l.status != 'paid')) {
      totalDebt += loan.remainingAmount;
    }

    final netWorth = totalAssets - totalDebt;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Tài chính hiện tại'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Tổng tài sản ròng',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency(netWorth),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync_rounded, color: Colors.white.withValues(alpha: 0.8), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Cập nhật hôm nay',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Accounts Section
            Text(
              'TÀI KHOẢN',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ...accountProv.accounts.map((acc) => _buildCard(
              context: context,
              icon: Icons.account_balance_wallet_rounded, 
              iconBgColor: AppTheme.secondaryContainer,
              iconColor: AppTheme.secondary,
              title: acc.name,
              amount: acc.balance,
              amountColor: AppTheme.secondary,
            )),
            if (accountProv.accounts.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Chưa có tài khoản'))),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tổng tài khoản: ${Formatters.currency(totalAssets)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Debt Section
            Text(
              'KHOẢN NỢ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ...loanProv.loans.where((l) => l.type == 'borrow' && l.status != 'paid').map((loan) {
              return _buildCard(
                context: context,
                icon: Icons.person_rounded,
                iconBgColor: AppTheme.tertiaryContainer,
                iconColor: AppTheme.tertiary,
                title: '${loan.personName} - Vay',
                subtitle: loan.dueDate != null ? 'Hạn: ${Formatters.date(loan.dueDate!)}' : null,
                amount: -loan.remainingAmount,
                amountColor: AppTheme.tertiary,
              );
            }),
            if (loanProv.loans.where((l) => l.type == 'borrow' && l.status != 'paid').isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Không có khoản nợ'))),
            
            if (totalDebt > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tổng nợ: ${Formatters.signedCurrency(-totalDebt)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tertiary,
                  ),
                ),
              ),
            
            const SizedBox(height: 40),
          ],
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            amount < 0 ? Formatters.signedCurrency(amount) : Formatters.currency(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
