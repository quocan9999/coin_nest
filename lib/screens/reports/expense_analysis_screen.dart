import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  final int initialTab;
  final DateTime? initialDate;

  const ExpenseAnalysisScreen({
    super.key,
    this.initialTab = 1,
    this.initialDate,
  });

  @override
  State<ExpenseAnalysisScreen> createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen> {
  int _selectedTab = 1;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _localDailyData = [];
  List<Map<String, dynamic>> _localHourlyData = [];
  List<Map<String, dynamic>> _localMonthlyData = [];
  double _localTotal = 0;
  bool _localLoading = false;
  bool _localHasError = false;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
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
      final day = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
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
      final total = monthly.fold<double>(
        0,
        (s, e) => s + (e['total'] as num).toDouble(),
      );
      setState(() {
        _localMonthlyData = monthly;
        _localDailyData = [];
        _localHourlyData = [];
        _localTotal = total;
        _localHasError = report.hasError;
        _localLoading = false;
      });
    } else {
      setState(() {
        _localDailyData = List<Map<String, dynamic>>.from(report.dailyExpense);
        _localHourlyData = _selectedTab == 0
            ? List<Map<String, dynamic>>.from(report.hourlyExpense)
            : [];
        _localMonthlyData = [];
        _localTotal = report.totalExpense;
        _localHasError = report.hasError;
        _localLoading = false;
      });
    }
  }

  String _periodLabel() {
    if (_selectedTab == 0) return 'Hôm nay, ${Formatters.date(_selectedDate)}';
    if (_selectedTab == 1) {
      return 'Tháng ${_selectedDate.month}/${_selectedDate.year}';
    }
    return 'Năm ${_selectedDate.year}';
  }

  bool _isForwardDisabled() {
    final now = DateTime.now();
    if (_selectedTab == 0) {
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      return !selectedDay.isBefore(today);
    }
    if (_selectedTab == 1) {
      return _selectedDate.year > now.year ||
          (_selectedDate.year == now.year && _selectedDate.month >= now.month);
    }
    if (_selectedTab == 2) return _selectedDate.year >= now.year;
    return true;
  }

  String _detailLabel(Map<String, dynamic> data) {
    if (_selectedTab == 0) {
      final rawHour = data['hour'];
      final hour = rawHour is num
          ? rawHour.toInt()
          : int.tryParse(rawHour?.toString() ?? '');
      if (hour == null) return 'N/A';
      return '${hour.toString().padLeft(2, '0')}:00';
    }

    if (_selectedTab == 2) {
      final monthInt = int.tryParse(data['month']?.toString() ?? '') ?? 0;
      return monthInt > 0 ? 'Tháng $monthInt/${_selectedDate.year}' : 'N/A';
    }

    if (!data.containsKey('date') || data['date'] == null) {
      return 'N/A';
    }

    final rawDate = data['date'].toString();
    if (rawDate.isEmpty) return 'N/A';

    try {
      return Formatters.date(DateTime.parse(rawDate));
    } catch (_) {
      return rawDate;
    }
  }

  void _onDetailTap(Map<String, dynamic> data) {
    if (_selectedTab == 0) return;

    if (_selectedTab == 2) {
      final monthInt = int.tryParse(data['month']?.toString() ?? '');
      if (monthInt == null) return;
      final target = DateTime(_selectedDate.year, monthInt, 1);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ExpenseAnalysisScreen(initialTab: 1, initialDate: target),
        ),
      );
      return;
    }

    if (_selectedTab == 1) {
      final rawDate = data['date']?.toString();
      if (rawDate == null || rawDate.isEmpty) return;
      late DateTime target;
      try {
        target = DateTime.parse(rawDate);
      } catch (_) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ExpenseAnalysisScreen(initialTab: 0, initialDate: target),
        ),
      );
    }
  }

  void _changePeriod(int delta) {
    setState(() {
      if (_selectedTab == 0) {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day + delta,
        );
      } else if (_selectedTab == 1) {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + delta,
          1,
        );
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

    final listData =
        (_selectedTab == 0
              ? List<Map<String, dynamic>>.from(_localHourlyData)
              : List<Map<String, dynamic>>.from(chartData))
          ..sort((a, b) {
            if (_selectedTab == 0) {
              final ha = a['hour'];
              final hb = b['hour'];
              final hourA = ha is num ? ha.toInt() : 0;
              final hourB = hb is num ? hb.toInt() : 0;
              return hourA.compareTo(hourB);
            }
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
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppTheme.outlineVariant,
                        ),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg,
                              ),
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
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.currency(totalAmount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.tertiary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _periodLabel(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 180,
                                  child: _selectedTab == 0
                                      ? _buildHourlyChart(_localHourlyData)
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
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg,
                              ),
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
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 16),
                                if (listData.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        _selectedTab == 0
                                            ? 'Không có giao dịch trong ngày'
                                            : 'Không có dữ liệu',
                                      ),
                                    ),
                                  ),
                                ...listData.map((d) {
                                  final label = _detailLabel(d);
                                  final amt = (d['total'] as num).toDouble();
                                  final tappable =
                                      _selectedTab == 1 || _selectedTab == 2;
                                  return InkWell(
                                    onTap: tappable
                                        ? () => _onDetailTap(d)
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: AppTheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                              if (tappable) ...[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 16,
                                                  color:
                                                      AppTheme.outlineVariant,
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            Formatters.currency(amt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.tertiary,
                                                ),
                                          ),
                                        ],
                                      ),
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

  String _formatYLabel(double value) {
    if (value == 0) return '0';
    final absValue = value.abs();
    if (absValue >= 1000000000) {
      return '${(absValue / 1000000000).toStringAsFixed(1)}tỷ'.replaceAll(
        '.0',
        '',
      );
    }
    if (absValue >= 1000000) {
      return '${(absValue / 1000000).toStringAsFixed(1)}tr'.replaceAll(
        '.0',
        '',
      );
    }
    if (absValue >= 1000) {
      return '${(absValue / 1000).toStringAsFixed(0)}k'.replaceAll('.0', '');
    }
    return absValue.toStringAsFixed(0);
  }

  AxisTitles _buildLeftTitles(double chartMaxY) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 52,
        interval: chartMaxY / 4,
        getTitlesWidget: (value, meta) {
          if (value == 0 || value == meta.max) return const SizedBox();
          return Text(
            _formatYLabel(value),
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.outlineVariant,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourlyChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return _buildEmptyChartState(_periodLabel());
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (final row in data) {
      final rawHour = row['hour'];
      final hour = rawHour is num
          ? rawHour.toInt()
          : int.tryParse(rawHour?.toString() ?? '');
      if (hour == null || hour < 0 || hour > 23) continue;
      final amount = (row['total'] as num).toDouble();
      spots.add(FlSpot(hour.toDouble(), amount));
      if (amount > maxY) maxY = amount;
    }

    if (spots.isEmpty) {
      return _buildEmptyChartState(_periodLabel());
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    if (maxY == 0) maxY = 1000;
    final chartMaxY = maxY * 1.2;
    final labelMap = <double, String>{
      0: '0',
      6: '6',
      12: '12',
      18: '18',
      23: '23',
    };

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
              interval: 1,
              getTitlesWidget: (v, meta) {
                final key = v.roundToDouble();
                if (!labelMap.containsKey(key)) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labelMap[key]!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: _buildLeftTitles(chartMaxY),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: chartMaxY,
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

  Widget _buildChart(List<Map<String, dynamic>> data, int tabIndex) {
    if (data.isEmpty) {
      return _buildEmptyChartState(_periodLabel());
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    late final double minX;
    late final double maxX;
    final labelMap = <double, String>{};

    if (tabIndex == 1) {
      final daysInMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
      ).day;
      minX = 1;
      maxX = daysInMonth.toDouble();
      for (final row in data) {
        final amount = (row['total'] as num).toDouble();
        final rawDate = row['date']?.toString();
        if (rawDate == null || rawDate.isEmpty) continue;
        late DateTime date;
        try {
          date = DateTime.parse(rawDate);
        } catch (_) {
          continue;
        }
        final x = date.day.toDouble();
        spots.add(FlSpot(x, amount));
        if (amount > maxY) maxY = amount;
      }
      labelMap[1] = '1';
      if (daysInMonth >= 5) labelMap[5] = '5';
      if (daysInMonth >= 10) labelMap[10] = '10';
      if (daysInMonth >= 15) labelMap[15] = '15';
      if (daysInMonth >= 20) labelMap[20] = '20';
      if (daysInMonth >= 25) labelMap[25] = '25';
      labelMap[daysInMonth.toDouble()] = '$daysInMonth';
    } else {
      minX = 1;
      maxX = 12;
      for (final row in data) {
        final amount = (row['total'] as num).toDouble();
        final monthStr = row['month'] as String? ?? '0';
        final monthInt = int.tryParse(monthStr) ?? 0;
        if (monthInt < 1 || monthInt > 12) continue;
        final x = monthInt.toDouble();
        spots.add(FlSpot(x, amount));
        if (amount > maxY) maxY = amount;
      }
      labelMap[1] = '1';
      labelMap[3] = '3';
      labelMap[6] = '6';
      labelMap[9] = '9';
      labelMap[12] = '12';
    }

    if (spots.isEmpty) {
      return _buildEmptyChartState(_periodLabel());
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    if (maxY == 0) maxY = 1000;
    final chartMaxY = maxY * 1.2;

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
              interval: 1,
              getTitlesWidget: (v, meta) {
                final key = v.roundToDouble();
                if (!labelMap.containsKey(key)) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labelMap[key]!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: _buildLeftTitles(chartMaxY),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: chartMaxY,
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.outline),
          ),
        ],
      ),
    );
  }
}
