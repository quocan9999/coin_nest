/// Represents a spending / income category (hạng mục).
///
/// Categories can be hierarchical via [parentId].
class Category {
  final int? id;
  final int userId;
  final String name;
  final String type; // 'income' or 'expense'
  final String iconName;
  final String? color;
  final int? parentId;
  final int sortOrder;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.iconName,
    this.color,
    this.parentId,
    this.sortOrder = 0,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      iconName: map['icon_name'] as String,
      color: map['color'] as String?,
      parentId: map['parent_id'] as int?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isDefault: (map['is_default'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'icon_name': iconName,
      'color': color,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    int? userId,
    String? name,
    String? type,
    String? iconName,
    String? color,
    int? parentId,
    int? sortOrder,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';
}
