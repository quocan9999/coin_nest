import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';


class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedTab = 0; // 0=overview, 1=byCategory, 2=trend

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthProvider>().currentUserId;
    context.read<ReportProvider>().loadReport(userId);
    context.read<ReportProvider>().loadYearlyReport(userId);
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Báo cáo', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),

            // Tab pills
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _tabPill('Tổng quan', 0),
                  _tabPill('Theo hạng mục', 1),
                  _tabPill('Xu hướng', 2),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: report.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTabContent(context, report),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabPill(String label, int index) {
    final sel = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppTheme.onSurface)),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ReportProvider report) {
    switch (_selectedTab) {
      case 0: return _overviewTab(context, report);
      case 1: return _categoryTab(context, report);
      case 2: return _trendTab(context, report);
      default: return const SizedBox();
    }
  }

  Widget _overviewTab(BuildContext context, ReportProvider report) {
    return Column(children: [
      // Summary cards
      Row(children: [
        Expanded(child: _card(context, 'Thu nhập', report.totalIncome, AppTheme.secondary, Icons.arrow_downward_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _card(context, 'Chi tiêu', report.totalExpense, AppTheme.tertiary, Icons.arrow_upward_rounded)),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chênh lệch', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(Formatters.signedCurrency(report.netBalance),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: report.netBalance >= 0 ? AppTheme.secondary : AppTheme.tertiary,
                  )),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _categoryTab(BuildContext context, ReportProvider report) {
    if (report.expenseByCategory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.pie_chart_outline_rounded, size: 56, color: AppTheme.outlineVariant),
          const SizedBox(height: 12),
          Text('Chưa có dữ liệu chi tiêu', style: TextStyle(color: AppTheme.onSurfaceVariant)),
        ])),
      );
    }

    final total = report.expenseByCategory.fold<double>(0, (s, m) => s + ((m['total'] as num?)?.toDouble() ?? 0));
    final colors = [
      AppTheme.tertiary, const Color(0xFF42A5F5), const Color(0xFFFFA726),
      const Color(0xFF66BB6A), const Color(0xFFAB47BC), const Color(0xFF26C6DA),
      const Color(0xFFFF7043), const Color(0xFF8D6E63),
    ];

    return Column(children: [
      // Pie chart
      SizedBox(
        height: 200,
        child: PieChart(PieChartData(
          sections: report.expenseByCategory.asMap().entries.map((e) {
            final m = e.value;
            final pct = total > 0 ? ((m['total'] as num).toDouble() / total * 100) : 0.0;
            return PieChartSectionData(
              value: (m['total'] as num).toDouble(),
              color: colors[e.key % colors.length],
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              radius: 60,
            );
          }).toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        )),
      ),
      const SizedBox(height: 20),

      // Legend
      ...report.expenseByCategory.asMap().entries.map((e) {
        final m = e.value;
        final amt = (m['total'] as num).toDouble();
        final pct = total > 0 ? (amt / total * 100) : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 12),
            Expanded(child: Text(m['name'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Formatters.currency(amt), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text('${pct.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
        );
      }),
      const SizedBox(height: 24),
    ]);
  }

  Widget _trendTab(BuildContext context, ReportProvider report) {
    if (report.monthlyExpense.isEmpty && report.monthlyIncome.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(child: Text('Chưa có dữ liệu xu hướng', style: TextStyle(color: AppTheme.onSurfaceVariant))),
      );
    }

    return Column(children: [
      Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: BarChart(BarChartData(
          barGroups: List.generate(12, (i) {
            final exp = report.monthlyExpense.firstWhere((m) => int.parse(m['month'] as String) == i + 1, orElse: () => {'total': 0});
            final inc = report.monthlyIncome.firstWhere((m) => int.parse(m['month'] as String) == i + 1, orElse: () => {'total': 0});
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: (inc['total'] as num).toDouble() / 1e6, color: AppTheme.secondary, width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
              BarChartRodData(toY: (exp['total'] as num).toDouble() / 1e6, color: AppTheme.tertiary, width: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
            ]);
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('T${v.toInt() + 1}', style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
            ))),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}M', style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.outlineVariant.withAlpha(38), strokeWidth: 1)),
          barTouchData: BarTouchData(enabled: false),
        )),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendDot(AppTheme.secondary, 'Thu nhập'),
        const SizedBox(width: 20),
        _legendDot(AppTheme.tertiary, 'Chi tiêu'),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _card(BuildContext context, String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 6),
        Text(Formatters.currency(amount), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
