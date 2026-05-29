import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../categories/category_list_screen.dart';
import '../loans/loan_list_screen.dart';
import '../budgets/budget_list_screen.dart';
import 'general_settings_screen.dart';
import 'data_settings_screen.dart';
import 'feedback_screen.dart';
import '../auth/login_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Khác',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20),

              // Profile card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.colors(context).card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.colors(
                        context,
                      ).transferBg.withAlpha(51),
                      child: Text(
                        (auth.currentUser?.fullName ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colors(context).primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser?.fullName ?? 'Người dùng',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            auth.currentUser?.phone ??
                                auth.currentUser?.email ??
                                '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.colors(context).textDisabled,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Management section
              _sectionTitle(context, 'QUẢN LÝ'),
              SizedBox(height: 8),
              _menuItem(
                context,
                Icons.category_outlined,
                'Quản lý hạng mục',
                () => _push(context, CategoryListScreen()),
              ),
              _menuItem(
                context,
                Icons.handshake_outlined,
                'Vay / Cho vay',
                () => _push(context, LoanListScreen()),
              ),
              _menuItem(
                context,
                Icons.pie_chart_outline_rounded,
                'Hạn mức chi',
                () => _push(context, BudgetListScreen()),
              ),

              SizedBox(height: 20),

              // Settings section
              _sectionTitle(context, 'CÀI ĐẶT'),
              SizedBox(height: 8),
              _menuItem(
                context,
                Icons.settings_outlined,
                'Cài đặt chung',
                () => _push(context, GeneralSettingsScreen()),
              ),
              _menuItem(
                context,
                Icons.cloud_outlined,
                'Sao lưu & Phục hồi',
                () => _push(context, DataSettingsScreen()),
              ),
              _menuItem(
                context,
                Icons.feedback_outlined,
                'Góp ý',
                () => _push(context, FeedbackScreen()),
              ),

              SizedBox(height: 20),

              // Logout
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: Icon(
                    Icons.logout_rounded,
                    color: AppTheme.colors(context).expense,
                  ),
                  label: Text(
                    'Đăng xuất',
                    style: TextStyle(color: AppTheme.colors(context).expense),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.colors(context).expense),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppTheme.colors(context).textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.colors(context).card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppTheme.colors(context).primary),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.colors(context).textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
