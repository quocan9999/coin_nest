import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../accounts/account_list_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../reports/report_screen.dart';
import '../settings/more_screen.dart';

/// Root home screen with bottom navigation bar (5 tabs).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const <Widget>[
    DashboardScreen(),
    AccountListScreen(),
    SizedBox(), // Placeholder — FAB opens add transaction sheet
    ReportScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    final accountProv = context.read<AccountProvider>();
    final txnProv = context.read<TransactionProvider>();
    final catProv = context.read<CategoryProvider>();

    await Future.wait([
      accountProv.loadAccounts(userId),
      txnProv.loadTransactions(userId),
      catProv.loadCategories(userId),
    ]);
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Center tab → open add transaction
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Tổng quan'),
                _buildNavItem(1, Icons.account_balance_rounded, 'Tài khoản'),
                // Center FAB
                GestureDetector(
                  onTap: () => _onTabTapped(2),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
                _buildNavItem(3, Icons.bar_chart_rounded, 'Báo cáo'),
                _buildNavItem(4, Icons.more_horiz_rounded, 'Khác'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppTheme.primary : AppTheme.outline,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
