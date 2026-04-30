import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  const ExpenseAnalysisScreen({super.key});

  @override
  State<ExpenseAnalysisScreen> createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen> {
  int _selectedTab = 1;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _localDailyData = [];
  List<Map<String, dynamic>> _localMonthlyData = [];
  double _localTotal = 0;
  bool _localLoading = false;
  bool _localHasError = false;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final seq = ++_loadSeq;
    if (!mounted) return;
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    setState(() {
      _localLoading = true;
      _localHasError = false;
    });

    final report = context.read<ReportProvider>();
    if (_selectedTab == 0) {
      final day = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      await report.loadReport(userId, from: day, to: day);
    } else if (_selectedTab == 1) {
      await report.loadReport(
        userId,
        from: DateTime(_selectedDate.year, _selectedDate.month, 1),
        to: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
      );
    } else {
      await report.loadYearlyReport(userId, year: _selectedDate.year);
    }

    if (!mounted || seq != _loadSeq) return;

    if (_selectedTab == 2) {
      final monthly = List<Map<String, dynamic>>.from(report.monthlyExpense);
      final total = monthly.fold<double>(0, (s, e) => s + (e['total'] as num).toDouble());
      setState(() {
        _localMonthlyData = monthly;
        _localDailyData = [];
        _localTotal = total;
        _localHasError = report.hasError;
        _localLoading = false;
      });
    } else {
      setState(() {
        _localDailyData = List<Map<String, dynamic>>.from(report.dailyExpense);
        _localMonthlyData = [];
        _localTotal = report.totalExpense;
        _localHasError = report.hasError;
        _localLoading = false;
      });
    }
  }

  String _periodLabel() {
    if (_selectedTab == 0) return 'Hôm nay, ${Formatters.date(_selectedDate)}';
    if (_selectedTab == 1) return 'Tháng ${_selectedDate.month}/${_selectedDate.year}';
    return 'Năm ${_selectedDate.year}';
  }

  bool _isForwardDisabled() {
    final now = DateTime.now();
    if (_selectedTab == 0) {
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return !selectedDay.isBefore(today);
    }
    if (_selectedTab == 1) {
      return _selectedDate.year > now.year ||
          (_selectedDate.year == now.year && _selectedDate.month >= now.month);
    }
    if (_selectedTab == 2) return _selectedDate.year >= now.year;
    return true;
  }

  void _changePeriod(int delta) {
    setState(() {
      if (_selectedTab == 0) {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + delta);
      } else if (_selectedTab == 1) {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
      } else if (_selectedTab == 2) {
        _selectedDate = DateTime(_selectedDate.year + delta, 1, 1);
      }
    });
    _loadData();
  }

  Widget _buildNavigationRow() {
    final disabledForward = _isForwardDisabled();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _changePeriod(-1),
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            color: AppTheme.primary,
            disabledColor: AppTheme.outlineVariant,
          ),
          Text(
            _selectedTab == 0
                ? Formatters.date(_selectedDate)
                : _selectedTab == 1
                    ? 'Tháng ${_selectedDate.month}/${_selectedDate.year}'
                    : 'Năm ${_selectedDate.year}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
          ),
          IconButton(
            onPressed: disabledForward ? null : () => _changePeriod(1),
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            color: AppTheme.primary,
            disabledColor: AppTheme.outlineVariant,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ReportProvider>();

    final chartData = _selectedTab == 2 ? _localMonthlyData : _localDailyData;
    final totalAmount = _localTotal;

    final listData = List<Map<String, dynamic>>.from(chartData)
      ..sort((a, b) {
        if (_selectedTab == 2) {
          final ma = a['month'] as String? ?? '';
          final mb = b['month'] as String? ?? '';
          return mb.compareTo(ma);
        }
        final da = a['date'] as String? ?? '';
        final db = b['date'] as String? ?? '';
        return db.compareTo(da);
      });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Phân tích chi tiêu',
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
          _buildNavigationRow(),
          Expanded(
            child: _localLoading
                ? const Center(child: CircularProgressIndicator())
                : _localHasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: AppTheme.outlineVariant),
                            const SizedBox(height: 12),
                            const Text('Không thể tải dữ liệu'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.tertiary,
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
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
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BIỂU ĐỒ CHI TIÊU',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(letterSpacing: 1.2),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      Formatters.currency(totalAmount),
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.tertiary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _periodLabel(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 180,
                                      child: _selectedTab == 0
                                          ? _buildDaySummary(totalAmount)
                                          : _buildChart(chartData, _selectedTab),
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
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'XEM CHI TIẾT',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(letterSpacing: 1.2),
                                    ),
                                    const SizedBox(height: 16),
                                    if (listData.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(child: Text('Không có dữ liệu')),
                                      ),
                                    ...listData.map((d) {
                                      final monthStr = d['month'] as String? ?? '0';
                                      final monthInt = int.tryParse(monthStr) ?? 0;
                                      final label = _selectedTab == 2
                                          ? 'Tháng $monthInt/${_selectedDate.year}'
                                          : Formatters.date(DateTime.parse(d['date'] as String));
                                      final amt = (d['total'] as num).toDouble();
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              label,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(color: AppTheme.onSurfaceVariant),
                                            ),
                                            Text(
                                              Formatters.currency(amt),
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.tertiary,
                                                  ),
                                            ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final sel = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _selectedDate = DateTime.now();
        });
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: sel ? AppTheme.tertiary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? AppTheme.tertiary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data, int tabIndex) {
    if (data.isEmpty) {
      return _buildEmptyChartState(_periodLabel());
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    double maxX = 30;
    final labelMap = <double, String>{};

    if (tabIndex == 1) {
      final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      maxX = (daysInMonth - 1).toDouble();
      for (final row in data) {
        final amount = (row['total'] as num).toDouble();
        final date = DateTime.parse(row['date'] as String);
        final x = (date.day - 1).toDouble();
        spots.add(FlSpot(x, amount));
        if (amount > maxY) maxY = amount;
      }
      labelMap[0] = '1';
      if (daysInMonth >= 5) labelMap[4] = '5';
      if (daysInMonth >= 10) labelMap[9] = '10';
      if (daysInMonth >= 15) labelMap[14] = '15';
      if (daysInMonth >= 20) labelMap[19] = '20';
      if (daysInMonth >= 25) labelMap[24] = '25';
      labelMap[(daysInMonth - 1).toDouble()] = '$daysInMonth';
    } else {
      maxX = 11;
      for (final row in data) {
        final amount = (row['total'] as num).toDouble();
        final monthStr = row['month'] as String? ?? '0';
        final monthInt = int.tryParse(monthStr) ?? 0;
        final x = (monthInt - 1).toDouble();
        spots.add(FlSpot(x, amount));
        if (amount > maxY) maxY = amount;
      }
      labelMap[0] = '1';
      labelMap[2] = '3';
      labelMap[5] = '6';
      labelMap[8] = '9';
      labelMap[11] = '12';
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
                final key = v.toInt().toDouble();
                if (!labelMap.containsKey(key)) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labelMap[key]!,
                    style: TextStyle(fontSize: 10, color: AppTheme.outlineVariant),
                  ),
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
        maxX: maxX,
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.tertiary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.tertiary.withValues(alpha: 0.3),
                  AppTheme.tertiary.withValues(alpha: 0.0),
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

  Widget _buildEmptyChartState(String periodLabel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppTheme.outlineVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            periodLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummary(double totalAmount) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Formatters.currency(totalAmount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tertiary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng trong ngày',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
