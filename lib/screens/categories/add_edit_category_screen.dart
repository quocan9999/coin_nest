import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../utils/category_icons.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddEditCategoryScreen({
    super.key,
    this.category,
  });

  @override
  State<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState
    extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _type = 'expense';
  String _selectedIcon = 'food';
  int? _selectedParentId;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = widget.category!.name;
      _type = widget.category!.type;
      _selectedIcon = widget.category!.iconName;
      _selectedParentId = widget.category!.parentId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId =
        context.read<AuthProvider>().currentUserId;

    final prov =
        context.read<CategoryProvider>();

    bool success;

    if (_isEditing) {
      success = await prov.updateCategory(
        widget.category!.copyWith(
          name: _nameController.text.trim(),
          iconName: _selectedIcon,
          parentId: _selectedParentId,
        ),
      );
    } else {
      success = await prov.addCategory(
        userId: userId,
        name: _nameController.text.trim(),
        type: _type,
        iconName: _selectedIcon,
        parentId: _selectedParentId,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconKeys = _type == 'expense'
        ? CategoryIcons.expenseIconKeys
        : CategoryIcons.incomeIconKeys;

    final catProv =
        context.watch<CategoryProvider>();

    final allCats = _type == 'expense'
        ? catProv.expenseCategories
        : catProv.incomeCategories;

    final parentCandidates = allCats
        .where(
          (c) =>
              c.parentId == null &&
              c.id != widget.category?.id,
        )
        .toList();

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor:
            theme.scaffoldBackgroundColor,

        title: Text(
          _isEditing
              ? 'Sửa hạng mục'
              : 'Thêm hạng mục',
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              if (!_isEditing) ...[
                Text(
                  'LOẠI',

                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing: 0.8,

                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    _typeChip(
                        context,
                        'Chi tiêu',
                        'expense'),

                    const SizedBox(width: 8),

                    _typeChip(
                        context,
                        'Thu nhập',
                        'income'),
                  ],
                ),

                const SizedBox(height: 20),
              ],

              Text(
                'TÊN HẠNG MỤC',

                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 0.8,

                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,

                validator: (v) =>
                    Validators.entityName(
                  v,
                  'Tên hạng mục',
                ),

                decoration:
                    const InputDecoration(
                  hintText: 'VD: Ăn uống',
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'HẠNG MỤC CHA (TÙY CHỌN)',

                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 0.8,

                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 8),

              InputDecorator(
                decoration:
                    const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),

                child:
                    DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedParentId,

                    hint: const Text(
                      'Không có (Hạng mục gốc)',
                    ),

                    dropdownColor:
                        theme.cardColor,

                    isExpanded: true,

                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,

                        child: Text(
                          'Không có (Hạng mục gốc)',
                        ),
                      ),

                      ...parentCandidates.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],

                    onChanged: (val) =>
                        setState(() {
                      _selectedParentId = val;
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'BIỂU TƯỢNG',

                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 0.8,

                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 8),

              InkWell(
                borderRadius:
                    BorderRadius.circular(12),

                onTap: () async {
                  final selected =
                      await showModalBottomSheet<
                          String>(
                    context: context,

                    backgroundColor:
                        theme.cardColor,

                    shape:
                        const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),

                    builder: (_) {
                      return Padding(
                        padding:
                            const EdgeInsets.all(
                                20),

                        child: GridView.builder(
                          shrinkWrap: true,

                          itemCount:
                              iconKeys.length,

                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),

                          itemBuilder:
                              (context, index) {
                            final key =
                                iconKeys[index];

                            final sel =
                                _selectedIcon ==
                                    key;

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(
                                  context,
                                  key,
                                );
                              },

                              child: Container(
                                decoration:
                                    BoxDecoration(
                                  color: sel
                                      ? AppTheme
                                          .primary
                                      : CategoryIcons
                                          .getColor(
                                              key)
                                          .withAlpha(
                                              30),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              12),

                                  border: sel
                                      ? null
                                      : Border.all(
                                          color: theme
                                              .colorScheme
                                              .outlineVariant
                                              .withAlpha(
                                                  51),
                                        ),
                                ),

                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,

                                  children: [
                                    Icon(
                                      CategoryIcons
                                          .getIcon(
                                              key),

                                      color: sel
                                          ? Colors
                                              .white
                                          : CategoryIcons
                                              .getColor(
                                                  key),

                                      size: 22,
                                    ),

                                    const SizedBox(
                                        height: 4),

                                    Text(
                                      _getVietnameseName(
                                          key),

                                      style:
                                          TextStyle(
                                        fontSize: 11,

                                        color: sel
                                            ? Colors
                                                .white
                                            : theme
                                                .colorScheme
                                                .onSurface,
                                      ),

                                      textAlign:
                                          TextAlign
                                              .center,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );

                  if (selected != null) {
                    setState(() {
                      _selectedIcon =
                          selected;
                    });
                  }
                },

                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),

                  decoration: BoxDecoration(
                    color: theme.cardColor,

                    borderRadius:
                        BorderRadius.circular(
                            12),

                    border: Border.all(
                      color: theme
                          .colorScheme
                          .outlineVariant
                          .withAlpha(40),
                    ),
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,

                        decoration: BoxDecoration(
                          color: CategoryIcons
                              .getColor(
                                  _selectedIcon)
                              .withAlpha(30),

                          borderRadius:
                              BorderRadius
                                  .circular(10),
                        ),

                        child: Icon(
                          CategoryIcons.getIcon(
                              _selectedIcon),

                          color: CategoryIcons
                              .getColor(
                                  _selectedIcon),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          _getVietnameseName(
                              _selectedIcon),

                          style: TextStyle(
                            fontSize: 15,

                            color: theme
                                .colorScheme
                                .onSurface,
                          ),
                        ),
                      ),

                      Icon(
                        Icons
                            .keyboard_arrow_down,

                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: _save,

                  child: Text(
                    _isEditing
                        ? 'Cập nhật'
                        : 'Thêm hạng mục',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    final sel = _type == value;

    return GestureDetector(
      onTap: () => setState(() {
        _type = value;

        _selectedIcon =
            value == 'expense'
                ? 'food'
                : 'salary';

        _selectedParentId = null;
      }),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: sel
              ? AppTheme.primary
              : theme.cardColor,

          borderRadius:
              BorderRadius.circular(
            AppTheme.radiusFull,
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: sel
                ? Colors.white
                : theme
                    .colorScheme
                    .onSurface,

            fontWeight: sel
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  String _getVietnameseName(String key) {
    switch (key) {
      case 'food':
        return 'Ăn uống';

      case 'transport':
        return 'Di chuyển';

      case 'housing':
        return 'Nhà ở';

      case 'utilities':
        return 'Tiện ích';

      case 'shopping':
        return 'Mua sắm';

      case 'health':
        return 'Sức khỏe';

      case 'education':
        return 'Giáo dục';

      case 'entertainment':
        return 'Giải trí';

      case 'clothing':
        return 'Quần áo';

      case 'personal':
        return 'Cá nhân';

      case 'gift':
        return 'Quà tặng';

      case 'telecom':
        return 'Điện thoại';

      case 'travel':
        return 'Du lịch';

      case 'repair':
        return 'Sửa chữa';

      case 'other_expense':
        return 'Khác';

      case 'salary':
        return 'Lương';

      case 'bonus':
        return 'Thưởng';

      case 'investment':
        return 'Đầu tư';

      case 'business':
        return 'Kinh doanh';

      case 'side_income':
        return 'Thu phụ';

      case 'interest':
        return 'Lãi suất';

      case 'received_gift':
        return 'Quà nhận';

      case 'freelance':
        return 'Freelance';

      case 'rental':
        return 'Cho thuê';

      case 'refund':
        return 'Hoàn tiền';

      case 'other_income':
        return 'Thu khác';

      default:
        return key;
    }
  }
}