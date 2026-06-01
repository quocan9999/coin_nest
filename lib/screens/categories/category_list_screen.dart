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

    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,

      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,

          title: const Text('Quản lý hạng mục'),

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

                MaterialPageRoute(
                  builder: (_) => const AddEditCategoryScreen(),
                ),
              ),
            ),
          ],

          bottom: TabBar(
            tabs: const [
              Tab(text: 'Chi tiêu'),
              Tab(text: 'Thu nhập'),
            ],

            labelColor: AppTheme.primary,

            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,

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
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Chưa có hạng mục nào',

          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final parents = categories.where((c) => c.parentId == null).toList();

    final groupedList = [];

    for (var p in parents) {
      groupedList.add(p);

      groupedList.addAll(categories.where((c) => c.parentId == p.id));
    }

    final orphaned = categories
        .where(
          (c) => c.parentId != null && !parents.any((p) => p.id == c.parentId),
        )
        .toList();

    groupedList.addAll(orphaned);

    return ListView.builder(
      padding: const EdgeInsets.all(20),

      itemCount: groupedList.length,

      itemBuilder: (_, i) {
        final cat = groupedList[i];

        final isChild = cat.parentId != null;

        return Container(
          margin: EdgeInsets.only(bottom: 8, left: isChild ? 32 : 0),

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: theme.cardColor,

            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),

          child: Row(
            children: [
              if (isChild)
                Padding(
                  padding: const EdgeInsets.only(right: 8),

                  child: Icon(
                    Icons.subdirectory_arrow_right_rounded,

                    color: theme.colorScheme.outlineVariant,

                    size: 20,
                  ),
                ),

              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: CategoryIcons.getColor(cat.iconName).withAlpha(30),

                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(
                  CategoryIcons.getIcon(cat.iconName),

                  color: CategoryIcons.getColor(cat.iconName),

                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  cat.name,

                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,

                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),

              if (cat.isDefault)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),

                  child: Icon(
                    Icons.lock_outline_rounded,

                    size: 16,

                    color: theme.colorScheme.outlineVariant,
                  ),
                ),

              if (!cat.isDefault)
                Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,

                        size: 18,

                        color: theme.colorScheme.onSurface,
                      ),

                      onPressed: () => Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => AddEditCategoryScreen(category: cat),
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,

                        size: 18,

                        color: AppTheme.tertiary,
                      ),

                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,

                          builder: (ctx) => AlertDialog(
                            backgroundColor: theme.cardColor,

                            title: const Text('Xác nhận xóa'),

                            content: Text(
                              'Bạn có chắc chắn muốn xóa hạng mục "${cat.name}"?',
                            ),

                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),

                                child: const Text('Hủy'),
                              ),

                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),

                                child: const Text(
                                  'Xóa',

                                  style: TextStyle(color: AppTheme.tertiary),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          if (!context.mounted) {
                            return;
                          }

                          final userId = context
                              .read<AuthProvider>()
                              .currentUserId;

                          await context.read<CategoryProvider>().deleteCategory(
                            cat.id,
                            userId,
                          );
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
