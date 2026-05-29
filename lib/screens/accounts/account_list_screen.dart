import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';
import '../../utils/category_icons.dart';
import 'add_edit_account_screen.dart';
import 'account_detail_screen.dart';

class AccountListScreen extends StatelessWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>();

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Tài khoản',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppTheme.colors(context).primary,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditAccountScreen()),
                    ),
                  ),
                ],
              ),
            ),

            // Total balance
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng tài sản',
                      style: TextStyle(
                        color: AppTheme.colors(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      Formatters.currency(accounts.totalBalance),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Account list
            Expanded(
              child: accounts.accounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 56,
                            color: AppTheme.colors(context).border,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Chưa có tài khoản nào',
                            style: TextStyle(
                              color: AppTheme.colors(context).textSecondary,
                            ),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditAccountScreen(),
                              ),
                            ),
                            child: Text('Thêm tài khoản'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: accounts.accounts.length,
                      itemBuilder: (context, i) {
                        final acc = accounts.accounts[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccountDetailScreen(account: acc),
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 10),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.colors(context).card,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: CategoryIcons.getColor(
                                      acc.iconName ?? acc.type,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    CategoryIcons.getIcon(
                                      acc.iconName ?? acc.type,
                                    ),
                                    color: CategoryIcons.getColor(
                                      acc.iconName ?? acc.type,
                                    ),
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        AppConstants.accountTypeLabels[acc
                                                .type] ??
                                            acc.type,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Formatters.currency(acc.balance),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
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
      ),
    );
  }
}
