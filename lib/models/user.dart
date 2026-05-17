/// Represents a registered user of the app.
class User {
  final int? id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? passwordHash;
  final String? passwordSalt;
  final String firebaseUid;
  final String authProvider;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.passwordHash,
    this.passwordSalt,
    required this.firebaseUid,
    required this.authProvider,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deserialise from a SQLite row.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      passwordHash: map['password_hash'] as String?,
      passwordSalt: map['password_salt'] as String?,
      firebaseUid: map['firebase_uid'] as String,
      authProvider: map['auth_provider'] as String,
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
      'email': email,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'firebase_uid': firebaseUid,
      'auth_provider': authProvider,
      'avatar_path': avatarPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    String? firebaseUid,
    String? authProvider,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      authProvider: authProvider ?? this.authProvider,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, phone: $phone, email: $email, authProvider: $authProvider)';
  }
}
