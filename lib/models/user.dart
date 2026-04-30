/// Represents a registered user of the app.
class User {
  final int? id;
  final String fullName;
  final String phone;
  final String passwordHash;
  final String passwordSalt;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.fullName,
    required this.phone,
    required this.passwordHash,
    required this.passwordSalt,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deserialise from a SQLite row.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String,
      passwordHash: map['password_hash'] as String,
      passwordSalt: map['password_salt'] as String,
      avatarPath: map['avatar_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Serialise to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'phone': phone,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'avatar_path': avatarPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? passwordHash,
    String? passwordSalt,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'User(id: $id, fullName: $fullName, phone: $phone)';
}
