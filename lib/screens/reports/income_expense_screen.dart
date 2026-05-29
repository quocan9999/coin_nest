import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> {
  int _selectedFilter = 1;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUserId;
    if (userId == 0) return;

    DateTime from;
    DateTime to;

    if (_selectedFilter == 0) {
      from = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      to = from;
    } else if (_selectedFilter == 1) {
      from = DateTime(_selectedDate.year, _selectedDate.month, 1);
      to = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    } else {
      from = DateTime(_selectedDate.year, 1, 1);
      to = DateTime(_selectedDate.year, 12, 31);
    }

    await context.read<ReportProvider>().loadReport(userId, from: from, to: to);
  }

  String _getPeriodLabel() {
    if (_selectedFilter == 0) {
      return 'Hôm nay, ${Formatters.date(_selectedDate)}';
    }
    if (_selectedFilter == 1) {
      return 'Tháng ${_selectedDate.month}/${_selectedDate.year}';
    }
    return 'Năm ${_selectedDate.year}';
  }

  void _changeFilter(int index) {
    setState(() {
      _selectedFilter = index;
      if (_selectedFilter == 0) {
        _selectedDate = DateTime.now();
      }
    });
    _loadData();
  }

  void _shiftPeriod(int delta) {
    setState(() {
      if (_selectedFilter == 1) {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + delta,
          1,
        );
      } else if (_selectedFilter == 2) {
        _selectedDate = DateTime(_selectedDate.year + delta, 1, 1);
      }
    });
    _loadData();
  }

  bool _isForwardDisabled() {
    final now = DateTime.now();
    if (_selectedFilter == 0) return true;
    if (_selectedFilter == 1) {
      return _selectedDate.year > now.year ||
          (_selectedDate.year == now.year && _selectedDate.month >= now.month);
    }
    return _selectedDate.year >= now.year;
  }

  Color _parseCategoryColor(String? value) {
    if (value == null || value.isEmpty) return AppTheme.colors(context).primary;
    try {
      return Color(int.parse(value.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.colors(context).primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final totalSum = report.totalIncome + report.totalExpense;
    final incomeRatio = totalSum == 0 ? 0.0 : report.totalIncome / totalSum;
    final expenseRatio = totalSum == 0 ? 0.0 : report.totalExpense / totalSum;
    final maxAmount = math.max(report.totalIncome, report.totalExpense);
    final incomeBarRatio = maxAmount > 0 ? report.totalIncome / maxAmount : 0.0;
    final expenseBarRatio = maxAmount > 0
        ? report.totalExpense / maxAmount
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text('Tình hình thu chi'),
        backgroundColor: AppTheme.colors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: report.isLoading
          ? Center(child: CircularProgressIndicator())
          : report.hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.colors(context).border,
                  ),
                  SizedBox(height: 12),
                  Text('Không thể tải dữ liệu'),
                  SizedBox(height: 8),
                  TextButton(onPressed: _loadData, child: Text('Thử lại')),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.colors(context).primary,
              onRefresh: () async {
                await _loadData();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
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
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_selectedFilter != 0)
                          IconButton(
                            onPressed: () => _shiftPeriod(-1),
                            icon: Icon(Icons.chevron_left_rounded),
                            color: AppTheme.colors(context).primary,
                          ),
                        Text(
                          _getPeriodLabel(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (_selectedFilter != 0)
                          IconButton(
                            onPressed: _isForwardDisabled()
                                ? null
                                : () => _shiftPeriod(1),
                            icon: Icon(Icons.chevron_right_rounded),
                            color: AppTheme.colors(context).primary,
                            disabledColor: AppTheme.colors(context).border,
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context: context,
                            title: 'Thu nhập',
                            amount: report.totalIncome,
                            color: AppTheme.colors(context).income,
                            icon: Icons.trending_up_rounded,
                            ratio: incomeBarRatio,
                            percentageLabel: totalSum > 0
                                ? '${(incomeRatio * 100).toStringAsFixed(1)}% tổng'
                                : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context: context,
                            title: 'Chi tiêu',
                            amount: report.totalExpense,
                            color: AppTheme.colors(context).expense,
                            icon: Icons.trending_down_rounded,
                            ratio: expenseBarRatio,
                            percentageLabel: report.totalIncome > 0
                                ? '${(report.totalExpense / report.totalIncome * 100).toStringAsFixed(1)}% so với thu'
                                : (report.totalExpense > 0
                                      ? '100% so với thu'
                                      : null),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.colors(context).card,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.colors(
                              context,
                            ).textPrimary.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Chênh lệch',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppTheme.colors(context).textSecondary,
                                ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                report.netBalance > 0
                                    ? Icons.trending_up_rounded
                                    : report.netBalance < 0
                                    ? Icons.trending_down_rounded
                                    : Icons.remove_rounded,
                                color: report.netBalance > 0
                                    ? AppTheme.colors(context).income
                                    : report.netBalance < 0
                                    ? AppTheme.colors(context).expense
                                    : AppTheme.colors(context).textDisabled,
                              ),
                              SizedBox(width: 8),
                              Text(
                                Formatters.signedCurrency(report.netBalance),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: report.netBalance >= 0
                                          ? AppTheme.colors(context).income
                                          : AppTheme.colors(context).expense,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.colors(context).input,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                if (incomeRatio > 0)
                                  Expanded(
                                    flex: (incomeRatio * 100).toInt(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.colors(context).income,
                                        borderRadius: BorderRadius.horizontal(
                                          left: Radius.circular(4),
                                          right: expenseRatio == 0
                                              ? Radius.circular(4)
                                              : Radius.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (expenseRatio > 0)
                                  Expanded(
                                    flex: (expenseRatio * 100).toInt(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.colors(context).expense,
                                        borderRadius: BorderRadius.horizontal(
                                          right: Radius.circular(4),
                                          left: incomeRatio == 0
                                              ? Radius.circular(4)
                                              : Radius.zero,
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
                    SizedBox(height: 32),
                    if (report.totalIncome == 0 && report.totalExpense == 0)
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.insert_chart_outlined_rounded,
                                size: 64,
                                color: AppTheme.colors(context).border,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Không có dữ liệu',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Chưa có giao dịch trong kỳ này',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.colors(
                                        context,
                                      ).textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (report.totalIncome > 0 &&
                        report.incomeByCategory.isNotEmpty) ...[
                      Text(
                        'CHI TIẾT THU NHẬP',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colors(context).textDisabled,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 16),
                      ...report.incomeByCategory.map(
                        (c) => _buildBreakdownRow(
                          context,
                          c['name'] ?? 'Khác',
                          (c['total'] as num).toDouble(),
                          report.totalIncome,
                          AppTheme.colors(context).income,
                          subtitleSuffix: 'tổng thu',
                          categoryColor: _parseCategoryColor(
                            c['color'] as String?,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                    if (report.totalExpense > 0 &&
                        report.expenseByCategory.isNotEmpty) ...[
                      Text(
                        'CHI TIẾT CHI TIÊU',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colors(context).textDisabled,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 16),
                      ...report.expenseByCategory.map(
                        (c) => _buildBreakdownRow(
                          context,
                          c['name'] ?? 'Khác',
                          (c['total'] as num).toDouble(),
                          report.totalExpense,
                          AppTheme.colors(context).expense,
                          subtitleSuffix: 'tổng chi',
                          categoryColor: _parseCategoryColor(
                            c['color'] as String?,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final sel = _selectedFilter == index;
    return GestureDetector(
      onTap: () => _changeFilter(index),
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? AppTheme.colors(context).primary
              : AppTheme.colors(context).input,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: sel
                ? Theme.of(context).colorScheme.onPrimary
                : AppTheme.colors(context).textPrimary,
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
    required String? percentageLabel,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.04),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.colors(context).textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            Formatters.currency(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (percentageLabel != null) ...[
            SizedBox(height: 4),
            Text(
              percentageLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
          SizedBox(height: 12),
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

  Widget _buildBreakdownRow(
    BuildContext context,
    String name,
    double amount,
    double total,
    Color color, {
    required String subtitleSuffix,
    required Color categoryColor,
  }) {
    final pct = total > 0 ? (amount / total) : 0.0;
    final isFallbackColor = categoryColor == AppTheme.colors(context).primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isFallbackColor ? Icons.label_rounded : Icons.circle,
                      size: 14,
                      color: categoryColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(1)}% $subtitleSuffix',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.colors(context).textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text(
                Formatters.currency(amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppTheme.colors(context).input,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 4,
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  '${(pct * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.colors(context).textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppTheme.colors(context).border,
          ),
        ],
      ),
    );
  }
}
