// lib/screens/category_management_screen.dart

import 'package:flutter/material.dart';
import 'add_category_screen.dart'; // 🔥 thêm dòng này

class Category {
  String name;
  IconData icon;
  Color color;
  bool isIncome;
  bool isLocked;

  Category({
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
    this.isLocked = false,
  });
}

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> {
  int tabIndex = 0;

  List<Category> categories = [
    Category(
      name: "Xăng",
      icon: Icons.local_gas_station,
      color: Colors.red.shade100,
      isIncome: false,
    ),
    Category(
      name: "Ăn uống",
      icon: Icons.restaurant,
      color: Colors.red.shade100,
      isIncome: false,
    ),
    Category(
      name: "Cho mượn",
      icon: Icons.volunteer_activism,
      color: Colors.purple.shade100,
      isIncome: false,
      isLocked: true,
    ),
    Category(
      name: "Trả nợ",
      icon: Icons.handshake,
      color: Colors.orange.shade100,
      isIncome: false,
      isLocked: true,
    ),
  ];

  List<Category> get filtered => categories
      .where((c) => c.isIncome == (tabIndex == 1))
      .toList();

  // 🔥 SỬA CHÍNH Ở ĐÂY
  void addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCategoryScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        categories.add(
          Category(
            name: result["name"],
            icon: Icons.category, // có thể nâng cấp sau
            color: Colors.blue.shade100,
            isIncome: result["type"] == 1,
          ),
        );
      });
    }
  }

  void editCategory(Category cat) {}

  void deleteCategory(Category cat) {
    setState(() {
      categories.remove(cat);
    });
  }

  Widget buildItem(Category c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, color: Colors.black87),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              c.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (c.isLocked)
            const Icon(Icons.lock, color: Colors.grey)
          else ...[
            IconButton(
              icon: const Icon(Icons.delete,
                  size: 20, color: Colors.red),
              onPressed: () => deleteCategory(c),
            ),
          ]
        ],
      ),
    );
  }

  Widget buildTab(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            tabIndex = index;
          });
        },
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tabIndex == index
                    ? const Color(0xFF0A7EA4)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2,
              color: tabIndex == index
                  ? const Color(0xFF0A7EA4)
                  : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Quản lý hạng mục",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: addCategory, // 🔥 FIX
                  ),
                ],
              ),
            ),

            Row(
              children: [
                buildTab("Chi tiêu", 0),
                buildTab("Thu nhập", 1),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children:
                      filtered.map(buildItem).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}