import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'current_finance_screen.dart';
import 'income_expense_screen.dart';
import 'expense_analysis_screen.dart';
import 'income_analysis_screen.dart';
import 'loan_tracking_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Báo cáo', 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          )
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildMenuCard(
            context: context,
            icon: Icons.account_balance_wallet_rounded,
            iconBgColor: AppTheme.primaryContainer,
            iconColor: AppTheme.primary,
            title: 'Tài chính hiện tại',
            subtitle: 'Tổng quan tài sản và khoản nợ',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrentFinanceScreen()));
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.bar_chart_rounded,
            iconBgColor: AppTheme.secondaryContainer,
            iconColor: AppTheme.secondary,
            title: 'Tình hình thu chi',
            subtitle: 'Phân tích thu nhập và chi tiêu',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeExpenseScreen()));
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.pie_chart_rounded,
            iconBgColor: AppTheme.tertiaryContainer,
            iconColor: AppTheme.tertiary,
            title: 'Phân tích chi tiêu',
            subtitle: 'Chi tiết chi tiêu theo hạng mục',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseAnalysisScreen()));
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.show_chart_rounded,
            iconBgColor: const Color(0xFFC8E6C9), // Light green for income
            iconColor: const Color(0xFF2E7D32),
            title: 'Phân tích thu',
            subtitle: 'Chi tiết thu nhập theo hạng mục',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeAnalysisScreen()));
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.receipt_long_rounded,
            iconBgColor: const Color(0xFFFFE0B2), // Light amber for loans
            iconColor: const Color(0xFFE65100),
            title: 'Theo dõi vay nợ',
            subtitle: 'Quản lý các khoản vay và cho vay',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanTrackingScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
