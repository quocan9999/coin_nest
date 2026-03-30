import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class IncomeAnalysisScreen extends StatefulWidget {
  const IncomeAnalysisScreen({super.key});

  @override
  State<IncomeAnalysisScreen> createState() => _IncomeAnalysisScreenState();
}

class _IncomeAnalysisScreenState extends State<IncomeAnalysisScreen> {
  int _selectedTab = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    if (_selectedTab == 1) { 
      final now = DateTime.now();
      context.read<ReportProvider>().loadReport(userId, 
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0),
      );
    } else if (_selectedTab == 2) { 
      context.read<ReportProvider>().loadYearlyReport(userId, year: DateTime.now().year);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final isMonth = _selectedTab == 1;

    final chartData = isMonth ? report.dailyIncome : report.monthlyIncome;
    final totalAmount = isMonth ? report.totalIncome : chartData.fold<double>(0, (s, e) => s + (e['total'] as num).toDouble());
    
    final listData = List<Map<String, dynamic>>.from(chartData)..sort((a, b) {
      if (isMonth) {
        return (b['date'] as String).compareTo(a['date'] as String);
      } else {
        return (b['month'] as String).compareTo(a['month'] as String);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Phân tích thu nhập',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildTab('Ngày', 0),
                const SizedBox(width: 16),
                _buildTab('Tháng', 1),
                const SizedBox(width: 16),
                _buildTab('Năm', 2),
              ],
            ),
          ),
          
          Expanded(
            child: report.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                            Text('BIỂU ĐỒ THU NHẬP', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            Text(Formatters.currency(totalAmount), style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                            )),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 180,
                              child: _buildChart(chartData, isMonth),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('XEM CHI TIẾT', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
                            const SizedBox(height: 16),
                            if (listData.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: Text('Không có dữ liệu')),
                              ),
                            ...listData.map((d) {
                              final label = isMonth 
                                ? Formatters.date(DateTime.parse(d['date']))
                                : 'Tháng ${d['month']}';
                              final amt = (d['total'] as num).toDouble();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    )),
                                    Text(Formatters.currency(amt), style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.secondary,
                                    )),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final sel = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) return;
        setState(() => _selectedTab = index);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: sel ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data, bool isMonth) {
    if (data.isEmpty) return const Center(child: Text('Chưa đủ dữ liệu biểu đồ'));

    double maxY = 0;
    final spots = <FlSpot>[];
    
    for (int i = 0; i < data.length; i++) {
      final amt = (data[i]['total'] as num).toDouble();
      if (amt > maxY) maxY = amt;
      
      double x = i.toDouble();
      if (isMonth) {
        final dateStr = data[i]['date'] as String;
        x = double.parse(dateStr.split('-').last) - 1; 
      } else {
        x = double.parse(data[i]['month'] as String) - 1; 
      }
      
      spots.add(FlSpot(x, amt));
    }

    if (maxY == 0) maxY = 1000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.outlineVariant.withValues(alpha: 0.2),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                if (v % 5 != 0 && v != meta.max) return const SizedBox();
                final val = (v.toInt() + 1).toString();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(val, style: TextStyle(fontSize: 10, color: AppTheme.outlineVariant)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: isMonth ? 30 : 11,
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondary.withValues(alpha: 0.3),
                  AppTheme.secondary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
