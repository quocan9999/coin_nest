import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_icons.dart';
import 'add_edit_category_screen.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CategoryProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Quản lý hạng mục'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditCategoryScreen())),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Chi tiêu'), Tab(text: 'Thu nhập')],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.onSurfaceVariant,
            indicatorColor: AppTheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, catProv.expenseCategories),
            _buildList(context, catProv.incomeCategories),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List categories) {
    if (categories.isEmpty) {
      return Center(child: Text('Chưa có hạng mục nào', style: TextStyle(color: AppTheme.onSurfaceVariant)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: CategoryIcons.getColor(cat.iconName).withAlpha(30), borderRadius: BorderRadius.circular(10)),
              child: Icon(CategoryIcons.getIcon(cat.iconName), color: CategoryIcons.getColor(cat.iconName), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(cat.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500))),
            if (!cat.isDefault)
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditCategoryScreen(category: cat))),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.tertiary),
                  onPressed: () async {
                    final userId = context.read<AuthProvider>().currentUserId;
                    await context.read<CategoryProvider>().deleteCategory(cat.id, userId);
                  },
                ),
              ]),
          ]),
        );
      },
    );
  }
}
