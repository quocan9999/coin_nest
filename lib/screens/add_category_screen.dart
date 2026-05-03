// lib/screens/add_category_screen.dart

import 'package:flutter/material.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() =>
      _AddCategoryScreenState();
}

class _AddCategoryScreenState
    extends State<AddCategoryScreen> {
  int selectedType = 0; // 0: Chi tiêu, 1: Thu nhập
  int selectedIcon = 0;

  final TextEditingController nameController =
      TextEditingController();

  final List<IconData> icons = [
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.directions_car,
    Icons.home,
    Icons.sports,
    Icons.store,
    Icons.medical_services,
    Icons.school,
    Icons.flight,
    Icons.fastfood,
    Icons.delete,
    Icons.attach_money,
  ];

  final List<Color> colors = [
    Color(0xFF0A7EA4),
    Color(0xFFBFD4EA),
    Color(0xFFEAD9B8),
    Color(0xFFF2E7B8),
    Color(0xFFD8C6E3),
    Color(0xFFF4C6CF),
    Color(0xFFC6E3DF),
    Color(0xFFDCE8C6),
    Color(0xFFC6DFE3),
    Color(0xFFF4D6CF),
    Color(0xFFE0E0E0),
    Color(0xFFD6DBF4),
  ];

  void submit() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập tên hạng mục"),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      "name": name,
      "type": selectedType,
      "icon": selectedIcon,
    });
  }

  Widget typeButton(String text, int index) {
    final isSelected = selectedType == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedType = index;
          });
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0A7EA4)
                : const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget iconItem(int index) {
    final isSelected = selectedIcon == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIcon = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors[index],
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF0A7EA4),
                  width: 2,
                )
              : null,
        ),
        child: Icon(
          icons[index],
          color: isSelected
              ? Colors.white
              : Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thêm hạng mục",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            const Text(
              "LOẠI",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                typeButton("Chi tiêu", 0),
                const SizedBox(width: 10),
                typeButton("Thu nhập", 1),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "TÊN HẠNG MỤC",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "VD: Ăn uống",
                filled: true,
                fillColor: const Color(0xFFEFEFEF),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "HẠNG MỤC CHA (TÙY CHỌN)",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Không có (Hạng mục gốc)"),
                  Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "BIỂU TƯỢNG",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey),
                ),
                Text(
                  "Xem thêm",
                  style: TextStyle(
                      color: Color(0xFF0A7EA4)),
                )
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                itemCount: icons.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) =>
                    iconItem(index),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF0A7EA4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onPressed: submit,
                child: const Text(
                  "Thêm hạng mục",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}