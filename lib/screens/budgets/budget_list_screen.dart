import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/category_icons.dart';
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
      final userId = context.read<AuthProvider>().currentUserId;
      context.read<BudgetProvider>().loadBudgets(userId);
    });
  }

  String _formatShortDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final budgetProv = context.watch<BudgetProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Hạn mức chi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditBudgetScreen()),
            ),
          ),
        ],
      ),
      body: budgetProv.budgets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 56,
                    color: AppTheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có hạn mức nào',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditBudgetScreen(),
                      ),
                    ),
                    child: const Text('Thêm hạn mức'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: budgetProv.budgets.length,
              itemBuilder: (_, i) {
                final b = budgetProv.budgets[i];
                
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                DateTime cycleStart;
                DateTime? cycleEnd;

                if (b.period == 'monthly') {
                  cycleStart = DateTime(today.year, today.month, 1);
                  cycleEnd = DateTime(today.year, today.month + 1, 0); 
                } else if (b.period == 'yearly') {
                  cycleStart = DateTime(today.year, 1, 1);
                  cycleEnd = DateTime(today.year, 12, 31);
                } else if (b.period == 'weekly') {
                  int diff = today.weekday - DateTime.monday;
                  cycleStart = today.subtract(Duration(days: diff));
                  cycleEnd = cycleStart.add(const Duration(days: 6));
                } else if (b.period == 'daily') {
                  cycleStart = today;
                  cycleEnd = today;
                } else {
                  cycleStart = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
                  if (b.endDate != null) {
                    cycleEnd = DateTime(b.endDate!.year, b.endDate!.month, b.endDate!.day);
                  }
                }

                double timePercent = 0.0;
                int remainingDays = 0;
                bool hasCycleEnd = cycleEnd != null;

                if (hasCycleEnd) {
                  final totalDays = cycleEnd.difference(cycleStart).inDays + 1;
                  final passedDays = today.difference(cycleStart).inDays;
                  
                  if (today.isBefore(cycleStart)) {
                    timePercent = 0.0;
                    remainingDays = totalDays;
                  } else if (today.isAfter(cycleEnd)) {
                    timePercent = 1.0;
                    remainingDays = 0;
                  } else {
                    timePercent = passedDays / totalDays;
                    remainingDays = cycleEnd.difference(today).inDays + (b.period == 'daily' ? 0 : 1); 
                  }
                }

                // --- GESTURE DETECTOR ĐỂ MỞ MÀN HÌNH SỬA KHI CHẠM ---
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditBudgetScreen(budget: b),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: b.categoryIconName != null 
                                    ? CategoryIcons.getColor(b.categoryIconName!).withAlpha(30) 
                                    : AppTheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                b.categoryIconName != null 
                                    ? CategoryIcons.getIcon(b.categoryIconName!) 
                                    : Icons.pie_chart_rounded,
                                color: b.categoryIconName != null 
                                    ? CategoryIcons.getColor(b.categoryIconName!) 
                                    : AppTheme.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          b.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (b.isExceeded)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.tertiary.withAlpha(20),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Vượt mức', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.tertiary)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasCycleEnd 
                                        ? "${_formatShortDate(cycleStart)} - ${_formatShortDate(cycleEnd)}" 
                                        : "${_formatShortDate(cycleStart)} - Liên tục", 
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${Formatters.currency(b.amount)} đ',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        if (hasCycleEnd) ...[
                          _buildTimelineBar(timePercent),
                          const SizedBox(height: 16),
                        ],
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hasCycleEnd 
                                  ? (remainingDays > 0 ? 'Còn $remainingDays ngày' : 'Ngày cuối')
                                  : 'Dài hạn', 
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'Còn lại ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                                children: [
                                  TextSpan(
                                    text: '${Formatters.currency(b.remainingAmount)} đ',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: b.remainingAmount < 0 ? AppTheme.tertiary : AppTheme.onSurface,
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
              },
            ),
    );
  }

  Widget _buildTimelineBar(double percent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final clampedPercent = percent.clamp(0.0, 1.0);
        
        const tooltipWidth = 64.0; 
        
        double left = (maxWidth * clampedPercent) - (tooltipWidth / 2);
        if (left < 0) left = 0;
        if (left > maxWidth - tooltipWidth) left = maxWidth - tooltipWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(height: 26, width: maxWidth), 
                Positioned(
                  left: left,
                  top: 0,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: -3,
                        child: Transform.rotate(
                          angle: 3.14159 / 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Container(
                        width: tooltipWidth,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7280),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Hôm nay',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 8, 
              width: maxWidth,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: maxWidth * clampedPercent,
                    decoration: BoxDecoration(
                      color: AppTheme.primary, 
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}