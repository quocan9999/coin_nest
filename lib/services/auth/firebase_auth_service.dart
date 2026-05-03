import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../database/database_helper.dart';
import '../../database/user_dao.dart';
import '../../models/user.dart';
import '../../utils/phone_utils.dart';
import '../../utils/security_utils.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final UserDao _userDao;
  final DatabaseHelper _dbHelper;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final StreamController<User?> _userStreamController =
      StreamController<User?>.broadcast();

  FirebaseAuthService({
    UserDao? userDao,
    DatabaseHelper? dbHelper,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _userDao = userDao ?? UserDao(),
       _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Future<AuthResult> registerWithPhone({
    required String fullName,
    required String phone,
    required String password,
    String? otpVerificationId,
    String? otpCode,
  }) async {
    try {
      final cleanName = SecurityUtils.sanitise(fullName);
      final normalisedPhone = PhoneUtils.normaliseVnPhone(
        SecurityUtils.sanitise(phone),
      );

      if (await _userDao.phoneExists(normalisedPhone)) {
        return AuthResult.failure('Số điện thoại đã được đăng ký');
      }

      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(password, salt);
      final now = DateTime.now();
      final user = User(
        fullName: cleanName,
        phone: normalisedPhone,
        email: null,
        passwordHash: hash,
        passwordSalt: salt,
        firebaseUid: _buildLocalFirebaseUid(AppAuthProvider.phone),
        authProvider: AppAuthProvider.phone.value,
        createdAt: now,
        updatedAt: now,
      );

      final userId = await _userDao.insert(user);
      await _dbHelper.seedDefaultCategories(userId);
      await _dbHelper.seedDefaultAccount(userId);

      final inserted = user.copyWith(id: userId);
      _userStreamController.add(inserted);
      return AuthResult.success(inserted);
    } on FormatException {
      return AuthResult.failure('Số điện thoại không hợp lệ');
    } catch (e) {
      return AuthResult.failure(
        _mapAuthError(e, fallback: 'Đăng ký thất bại. Vui lòng thử lại.'),
      );
    }
  }

  @override
  Future<AuthResult> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final cleanName = SecurityUtils.sanitise(fullName);
      final cleanEmail = SecurityUtils.sanitise(email).trim().toLowerCase();
      if (await _userDao.emailExists(cleanEmail)) {
        return AuthResult.failure('Email đã được đăng ký');
      }

      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(password, salt);
      final now = DateTime.now();
      final user = User(
        fullName: cleanName,
        phone: null,
        email: cleanEmail,
        passwordHash: hash,
        passwordSalt: salt,
        firebaseUid: _buildLocalFirebaseUid(AppAuthProvider.email),
        authProvider: AppAuthProvider.email.value,
        createdAt: now,
        updatedAt: now,
      );

      final userId = await _userDao.insert(user);
      await _dbHelper.seedDefaultCategories(userId);
      await _dbHelper.seedDefaultAccount(userId);

      final inserted = user.copyWith(id: userId);
      _userStreamController.add(inserted);
      return AuthResult.success(inserted);
    } catch (e) {
      return AuthResult.failure(
        _mapAuthError(e, fallback: 'Đăng ký thất bại. Vui lòng thử lại.'),
      );
    }
  }

  @override
  Future<AuthResult> loginWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      final rawIdentifier = SecurityUtils.sanitise(identifier).trim();
      final user = _isEmail(rawIdentifier)
          ? await _userDao.findByEmail(rawIdentifier.toLowerCase())
          : await _userDao.findByPhone(
              PhoneUtils.normaliseVnPhone(rawIdentifier),
            );

      if (user == null) {
        return AuthResult.failure('Thông tin đăng nhập không đúng');
      }
      if (user.passwordHash == null || user.passwordSalt == null) {
        return AuthResult.failure('Tài khoản này không dùng mật khẩu');
      }

      final valid = SecurityUtils.verifyPassword(
        password,
        user.passwordHash!,
        user.passwordSalt!,
      );
      if (!valid) {
        return AuthResult.failure('Thông tin đăng nhập không đúng');
      }

      _userStreamController.add(user);
      return AuthResult.success(user);
    } on FormatException {
      return AuthResult.failure('Số điện thoại không hợp lệ');
    } catch (e) {
      return AuthResult.failure(
        _mapAuthError(e, fallback: 'Đăng nhập thất bại. Vui lòng thử lại.'),
      );
    }
  }

  @override
  Future<AuthResult> loginWithGoogle() async {
    return AuthResult.failure('Đăng nhập Google sẽ được triển khai ở Phase 5');
  }

  @override
  Future<String> requestPhoneOtp(String phone) async {
    throw UnimplementedError('OTP flow được triển khai ở Phase 3.');
  }

  @override
  Future<bool> confirmPhoneOtp(String verificationId, String code) async {
    throw UnimplementedError('OTP flow được triển khai ở Phase 3.');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  @override
  Future<void> resetPasswordByPhone({
    required String verificationId,
    required String otpCode,
    required String newPassword,
  }) async {
    throw UnimplementedError(
      'Cloud Function reset password theo số điện thoại sẽ được triển khai ở Phase 6.',
    );
  }

  @override
  Future<AuthResult> resetPasswordWithPhoneLocal({
    required String phone,
    required String newPassword,
  }) async {
    try {
      final normalisedPhone = PhoneUtils.normaliseVnPhone(
        SecurityUtils.sanitise(phone),
      );
      final user = await _userDao.findByPhone(normalisedPhone);
      if (user == null) {
        return AuthResult.failure(
          'Không tìm thấy tài khoản với số điện thoại này',
        );
      }

      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(newPassword, salt);
      await _userDao.updatePassword(user.id!, hash, salt);

      return AuthResult.success(
        user.copyWith(
          passwordHash: hash,
          passwordSalt: salt,
          updatedAt: DateTime.now(),
        ),
      );
    } on FormatException {
      return AuthResult.failure('Số điện thoại không hợp lệ');
    } catch (e) {
      return AuthResult.failure(
        _mapAuthError(e, fallback: 'Đặt lại mật khẩu thất bại.'),
      );
    }
  }

  @override
  Future<User?> findLocalUserById(int userId) async {
    return _userDao.findById(userId);
  }

  @override
  Future<void> logout() async {
    _userStreamController.add(null);
  }

  @override
  Stream<User?> userChanges() => _userStreamController.stream;

  /// Shared helper for future "phone + password via synthetic email" flow.
  String phoneToSyntheticEmail(String phoneE164) {
    return PhoneUtils.phoneToSyntheticEmail(phoneE164);
  }

  bool _isEmail(String value) => value.contains('@');

  String _buildLocalFirebaseUid(AppAuthProvider provider) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'local_${provider.value}_$timestamp';
  }

  String _mapAuthError(Object error, {required String fallback}) {
    final message = error.toString().toLowerCase();

    if (message.contains('unique constraint failed') &&
        message.contains('users.phone')) {
      return 'Số điện thoại đã được đăng ký';
    }
    if (message.contains('unique constraint failed') &&
        message.contains('users.email')) {
      return 'Email đã được đăng ký';
    }
    if (message.contains('database is locked')) {
      return 'Thao tác chưa thể hoàn tất lúc này. Vui lòng thử lại sau ít phút.';
    }

    return fallback;
  }
}
