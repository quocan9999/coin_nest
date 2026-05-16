import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> {
  int _selectedFilter = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    final now = DateTime.now();
    DateTime from;
    DateTime to;

    if (_selectedFilter == 0) {
      from = DateTime(now.year, now.month, now.day);
      to = from;
    } else if (_selectedFilter == 1) {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 0);
    } else {
      from = DateTime(now.year, 1, 1);
      to = DateTime(now.year, 12, 31);
    }

    context.read<ReportProvider>().loadReport(userId, from: from, to: to);
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    if (_selectedFilter == 0) return 'Hôm nay: ${Formatters.date(now)}';
    if (_selectedFilter == 1) return 'Tháng ${now.month}/${now.year}';
    return 'Năm ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final totalSum = report.totalIncome + report.totalExpense;
    final incomeRatio = totalSum == 0 ? 0.0 : report.totalIncome / totalSum;
    final expenseRatio = totalSum == 0 ? 0.0 : report.totalExpense / totalSum;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Tình hình thu chi'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: report.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Hôm nay', 0),
                      _buildFilterChip('Tháng', 1),
                      _buildFilterChip('Năm', 2),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  _getPeriodLabel(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context: context,
                        title: 'Thu nhập',
                        amount: report.totalIncome,
                        color: AppTheme.secondary,
                        icon: Icons.trending_up_rounded,
                        ratio: totalSum == 0 ? 0 : 1.0, 
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context: context,
                        title: 'Chi tiêu',
                        amount: report.totalExpense,
                        color: AppTheme.tertiary,
                        icon: Icons.trending_down_rounded,
                        ratio: totalSum == 0 ? 0 : 1.0, 
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Chênh lệch', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.signedCurrency(report.netBalance),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: report.netBalance >= 0 ? AppTheme.secondary : AppTheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            if (incomeRatio > 0)
                              Expanded(
                                flex: (incomeRatio * 100).toInt(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary,
                                    borderRadius: BorderRadius.horizontal(
                                      left: const Radius.circular(4), 
                                      right: expenseRatio == 0 ? const Radius.circular(4) : Radius.zero,
                                    ),
                                  ),
                                ),
                              ),
                            if (expenseRatio > 0)
                              Expanded(
                                flex: (expenseRatio * 100).toInt(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.tertiary,
                                    borderRadius: BorderRadius.horizontal(
                                      right: const Radius.circular(4),
                                      left: incomeRatio == 0 ? const Radius.circular(4) : Radius.zero,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (report.incomeByCategory.isNotEmpty) ...[
                  Text(
                    'CHI TIẾT THU NHẬP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.outline,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...report.incomeByCategory.map((c) => _buildBreakdownRow(
                    context, 
                    c['name'] ?? 'Khác', 
                    (c['total'] as num).toDouble(), 
                    report.totalIncome, 
                    AppTheme.secondary,
                  )),
                  const SizedBox(height: 24),
                ],

                if (report.expenseByCategory.isNotEmpty) ...[
                  Text(
                    'CHI TIẾT CHI TIÊU',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.outline,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...report.expenseByCategory.map((c) => _buildBreakdownRow(
                    context, 
                    c['name'] ?? 'Khác', 
                    (c['total'] as num).toDouble(), 
                    report.totalExpense, 
                    AppTheme.tertiary,
                  )),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final sel = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = index);
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(
          label, 
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: sel ? Colors.white : AppTheme.onSurface
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required double ratio,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
           Text(
            Formatters.currency(amount), 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, 
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(2),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context, String name, double amount, double total, Color color) {
    final pct = total > 0 ? (amount / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(Formatters.currency(amount), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  '${(pct * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceVariant),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
