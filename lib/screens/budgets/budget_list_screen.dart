import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import '../../utils/formatters.dart';
import 'add_edit_budget_screen.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBudgets();
    });
  }

  Future<void> _loadBudgets() async {
    final userId = context.read<AuthProvider>().currentUserId;
    await context.read<BudgetProvider>().loadBudgets(userId);
  }

  Future<void> _openBudgetEditor([Budget? budget]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditBudgetScreen(budget: budget)),
    );
    if (!mounted) return;
    await _loadBudgets();
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  DateTime _cycleStart(Budget budget, DateTime today) {
    switch (budget.period) {
      case 'daily':
        return today;
      case 'weekly':
        return today.subtract(Duration(days: today.weekday - DateTime.monday));
      case 'monthly':
        return DateTime(today.year, today.month);
      case 'yearly':
        return DateTime(today.year);
      default:
        return DateTime(
          budget.startDate.year,
          budget.startDate.month,
          budget.startDate.day,
        );
    }
  }

  DateTime? _cycleEnd(Budget budget, DateTime cycleStart, DateTime today) {
    switch (budget.period) {
      case 'daily':
        return today;
      case 'weekly':
        return cycleStart.add(const Duration(days: 6));
      case 'monthly':
        return DateTime(today.year, today.month + 1, 0);
      case 'yearly':
        return DateTime(today.year, 12, 31);
      default:
        final endDate = budget.endDate;
        if (endDate == null) return null;
        return DateTime(endDate.year, endDate.month, endDate.day);
    }
  }

  double _timePercent(DateTime start, DateTime end, DateTime today) {
    if (today.isBefore(start)) return 0;
    if (today.isAfter(end)) return 1;

    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) return 1;

    final passedDays = today.difference(start).inDays;
    return (passedDays / totalDays).clamp(0.0, 1.0);
  }

  int _remainingDays(DateTime end, DateTime today, String period) {
    if (today.isAfter(end)) return 0;
    return end.difference(today).inDays + (period == 'daily' ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final budgetProv = context.watch<BudgetProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Hạn mức chi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: colorScheme.primary,
            ),
            onPressed: () => _openBudgetEditor(),
          ),
        ],
      ),
      body: budgetProv.budgets.isEmpty
          ? _buildEmptyState(theme, colorScheme)
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing10),
              itemCount: budgetProv.budgets.length,
              itemBuilder: (_, index) {
                return _buildBudgetCard(
                  budgetProv.budgets[index],
                  theme,
                  colorScheme,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 56,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: AppTheme.spacing6),
          Text(
            'Chưa có hạn mức nào',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacing6),
          ElevatedButton(
            onPressed: () => _openBudgetEditor(),
            child: const Text('Thêm hạn mức'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    Budget budget,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final cycleStart = _cycleStart(budget, normalizedToday);
    final cycleEnd = _cycleEnd(budget, cycleStart, normalizedToday);
    final hasCycleEnd = cycleEnd != null;
    final timePercent = hasCycleEnd
        ? _timePercent(cycleStart, cycleEnd, normalizedToday)
        : 0.0;
    final remainingDays = hasCycleEnd
        ? _remainingDays(cycleEnd, normalizedToday, budget.period)
        : 0;
    final subtitleParts = [
      if (budget.categoryName != null) budget.categoryName!,
      if (budget.accountName != null) budget.accountName!,
    ];

    return GestureDetector(
      onTap: () => _openBudgetEditor(budget),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
        padding: const EdgeInsets.all(AppTheme.spacing8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildCategoryIcon(budget, colorScheme),
                const SizedBox(width: AppTheme.spacing6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              budget.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (budget.isExceeded)
                            _buildExceededBadge(theme, colorScheme),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing2),
                      Text(
                        subtitleParts.isEmpty
                            ? 'Tất cả hạng mục'
                            : subtitleParts.join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasCycleEnd
                            ? '${_formatShortDate(cycleStart)} - ${_formatShortDate(cycleEnd)}'
                            : '${_formatShortDate(cycleStart)} - Liên tục',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacing6),
                Text(
                  '${Formatters.currency(budget.amount)} đ',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing10),
            if (hasCycleEnd) ...[
              _buildTimelineBar(timePercent, colorScheme, theme),
              const SizedBox(height: AppTheme.spacing8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasCycleEnd
                      ? (remainingDays > 0
                            ? 'Còn $remainingDays ngày'
                            : 'Ngày cuối')
                      : 'Dài hạn',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: 'Còn lại ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${Formatters.currency(budget.remainingAmount)} đ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: budget.remainingAmount < 0
                              ? colorScheme.tertiary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Budget budget, ColorScheme colorScheme) {
    final iconName = budget.categoryIconName;
    final iconColor = iconName != null
        ? CategoryIcons.getColor(iconName)
        : colorScheme.onSurfaceVariant;

    return Container(
      width: AppTheme.spacing24,
      height: AppTheme.spacing24,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(
        iconName != null
            ? CategoryIcons.getIcon(iconName)
            : Icons.pie_chart_rounded,
        color: iconColor,
        size: AppTheme.spacing12,
      ),
    );
  }

  Widget _buildExceededBadge(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(left: AppTheme.spacing4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing4,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withAlpha(28),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        'Vượt mức',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.tertiary,
        ),
      ),
    );
  }

  Widget _buildTimelineBar(
    double percent,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final clampedPercent = percent.clamp(0.0, 1.0);
        const tooltipWidth = 64.0;

        var left = (maxWidth * clampedPercent) - (tooltipWidth / 2);
        if (left < 0) left = 0;
        if (left > maxWidth - tooltipWidth) left = maxWidth - tooltipWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(height: AppTheme.spacing12, width: maxWidth),
                Positioned(
                  left: left,
                  top: 0,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: -AppTheme.spacing2,
                        child: Transform.rotate(
                          angle: 3.14159 / 4,
                          child: Container(
                            width: AppTheme.spacing4,
                            height: AppTheme.spacing4,
                            color: colorScheme.inverseSurface,
                          ),
                        ),
                      ),
                      Container(
                        width: tooltipWidth,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.inverseSurface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Hôm nay',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing2),
            Container(
              height: AppTheme.spacing4,
              width: maxWidth,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clampedPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
