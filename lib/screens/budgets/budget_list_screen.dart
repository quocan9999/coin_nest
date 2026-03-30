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
    final userId = context.read<AuthProvider>().currentUserId;
    context.read<BudgetProvider>().loadBudgets(userId);
  }

  @override
  Widget build(BuildContext context) {
    final budgetProv = context.watch<BudgetProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Hạn mức chi'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBudgetScreen()))),
        ],
      ),
      body: budgetProv.budgets.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pie_chart_outline_rounded, size: 56, color: AppTheme.outlineVariant),
              const SizedBox(height: 12),
              Text('Chưa có hạn mức nào', style: TextStyle(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBudgetScreen())),
                  child: const Text('Thêm hạn mức')),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: budgetProv.budgets.length,
              itemBuilder: (_, i) {
                final b = budgetProv.budgets[i];
                final pct = b.usagePercent.clamp(0.0, 100.0);
                final barColor = b.isExceeded ? AppTheme.tertiary : AppTheme.primary;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (b.categoryIconName != null)
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: CategoryIcons.getColor(b.categoryIconName!).withAlpha(30), borderRadius: BorderRadius.circular(10)),
                          child: Icon(CategoryIcons.getIcon(b.categoryIconName!), color: CategoryIcons.getColor(b.categoryIconName!), size: 18),
                        ),
                      if (b.categoryIconName != null) const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        if (b.categoryName != null) Text(b.categoryName!, style: Theme.of(context).textTheme.bodySmall),
                      ])),
                      if (b.isExceeded)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.tertiary.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Vượt mức', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.tertiary)),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${Formatters.currency(b.spentAmount ?? 0)} / ${Formatters.currency(b.amount)}', style: Theme.of(context).textTheme.bodySmall),
                      Text(Formatters.percent(pct), style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: barColor)),
                    ]),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (pct / 100).clamp(0, 1),
                      backgroundColor: AppTheme.outlineVariant.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation(barColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
