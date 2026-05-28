import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    required String otpVerificationId,
    required String otpCode,
  }) async {
    try {
      final cleanName = SecurityUtils.sanitise(fullName);
      final normalisedPhone = PhoneUtils.normaliseVnPhone(
        SecurityUtils.sanitise(phone),
      );

      if (await _userDao.phoneExists(normalisedPhone)) {
        return AuthResult.failure('Số điện thoại đã được đăng ký');
      }

      if (otpVerificationId.trim().isEmpty || otpCode.trim().isEmpty) {
        return AuthResult.failure(
          'Vui lòng nhập mã OTP để xác thực số điện thoại',
        );
      }

      final isOtpValid = await confirmPhoneOtp(otpVerificationId, otpCode);
      if (!isOtpValid) {
        return AuthResult.failure('Mã OTP không hợp lệ hoặc đã hết hạn');
      }

      final syntheticEmail = PhoneUtils.phoneToSyntheticEmail(normalisedPhone);
      final firebaseCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: syntheticEmail,
            password: password,
          );
      final firebaseUser = firebaseCredential.user;
      if (firebaseUser == null) {
        return AuthResult.failure(
          'Không thể tạo tài khoản xác thực. Vui lòng thử lại.',
        );
      }
      await firebaseUser.updateDisplayName(cleanName);

      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(password, salt);
      final now = DateTime.now();
      final user = User(
        fullName: cleanName,
        phone: normalisedPhone,
        email: null,
        passwordHash: hash,
        passwordSalt: salt,
        firebaseUid: firebaseUser.uid,
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
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

      // Tạo Firebase user bằng Email/Password provider với email thực
      final firebaseCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );
      final firebaseUser = firebaseCredential.user;
      if (firebaseUser == null) {
        return AuthResult.failure(
          'Không thể tạo tài khoản xác thực. Vui lòng thử lại.',
        );
      }
      await firebaseUser.updateDisplayName(cleanName);

      // Lưu hash password cục bộ để hỗ trợ backward-compat khi cần
      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(password, salt);
      final now = DateTime.now();
      final user = User(
        fullName: cleanName,
        phone: null,
        email: cleanEmail,
        passwordHash: hash,
        passwordSalt: salt,
        firebaseUid: firebaseUser.uid,
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
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
      final isEmailIdentifier = _isEmail(rawIdentifier);
      final normalisedEmail = isEmailIdentifier
          ? rawIdentifier.toLowerCase()
          : null;
      final normalisedPhone = isEmailIdentifier
          ? null
          : PhoneUtils.normaliseVnPhone(rawIdentifier);
      final signInEmail =
          normalisedEmail ?? PhoneUtils.phoneToSyntheticEmail(normalisedPhone!);

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: signInEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return AuthResult.failure(
          'Không thể xác thực tài khoản. Vui lòng thử lại.',
        );
      }

      // Xác định provider dựa vào loại identifier người dùng nhập
      final loginProvider = normalisedPhone != null
          ? AppAuthProvider.phone
          : AppAuthProvider.email;
      final localUser = await _syncLocalUserAfterFirebaseLogin(
        firebaseUser: firebaseUser,
        normalisedPhone: normalisedPhone,
        normalisedEmail: normalisedEmail,
        authProvider: loginProvider,
      );
      _userStreamController.add(localUser);
      return AuthResult.success(localUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
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
    try {
      // authenticate() trả non-null hoặc throw exception khi user huỷ
      final googleUser = await GoogleSignIn.instance.authenticate();

      // v7: authentication là getter sync, chỉ chứa idToken
      final googleAuth = googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final firebaseCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseUser = firebaseCredential.user;
      if (firebaseUser == null) {
        return AuthResult.failure(
          'Không thể xác thực tài khoản Google. Vui lòng thử lại.',
        );
      }

      // Upsert SQLite local profile — dùng email từ Google, provider = google
      final localUser = await _syncLocalUserAfterFirebaseLogin(
        firebaseUser: firebaseUser,
        normalisedPhone: null,
        normalisedEmail: firebaseUser.email,
        authProvider: AppAuthProvider.google,
      );
      _userStreamController.add(localUser);
      return AuthResult.success(localUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseAuthError(e));
    } catch (e) {
      // Catch cả trường hợp user huỷ popup Google (PlatformException)
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') ||
          msg.contains('sign_in_canceled') ||
          msg.contains('sign_in_cancelled')) {
        return AuthResult.failure('Đăng nhập Google đã bị huỷ');
      }
      return AuthResult.failure(
        _mapAuthError(
          e,
          fallback: 'Đăng nhập Google thất bại. Vui lòng thử lại.',
        ),
      );
    }
  }

  @override
  Future<String> requestPhoneOtp(String phone) async {
    final normalisedPhone = PhoneUtils.normaliseVnPhone(
      SecurityUtils.sanitise(phone),
    );
    if (await _userDao.phoneExists(normalisedPhone)) {
      throw Exception('Số điện thoại đã được đăng ký');
    }

    final completer = Completer<String>();
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: normalisedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (exception) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(_mapFirebaseAuthError(exception)));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  @override
  Future<String> requestForgotPasswordOtp(String phone) async {
    final normalisedPhone = PhoneUtils.normaliseVnPhone(
      SecurityUtils.sanitise(phone),
    );
    // Không kiểm tra phoneExists — luồng quên mật khẩu cần phone đã tồn tại,
    // khác với requestPhoneOtp (register) reject phone đã đăng ký.
    final completer = Completer<String>();
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: normalisedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (exception) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(_mapFirebaseAuthError(exception)));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  @override
  Future<bool> confirmPhoneOtp(String verificationId, String code) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      final phoneCredentialResult = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final phoneUser = phoneCredentialResult.user;
      if (phoneUser == null) return false;

      try {
        await phoneUser.delete();
      } catch (_) {
        // Best effort cleanup of temporary phone-auth user used for OTP proof.
      }

      await _firebaseAuth.signOut();
      return true;
    } on firebase_auth.FirebaseAuthException {
      return false;
    }
  }

  @override
  Future<bool> confirmForgotPasswordOtp(
    String verificationId,
    String code,
  ) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      final phoneCredentialResult = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return phoneCredentialResult.user?.phoneNumber != null;
    } on firebase_auth.FirebaseAuthException {
      return false;
    }
  }

  @override
  Future<String?> checkAccountProvider(String email) async {
    final normalisedEmail = email.trim().toLowerCase();

    try {
      // Thử đăng nhập với mật khẩu giả để kiểm tra tài khoản tồn tại.
      // Firebase sẽ trả về các error code khác nhau tùy trạng thái tài khoản.
      await _firebaseAuth.signInWithEmailAndPassword(
        email: normalisedEmail,
        password: '__check_existence_only__',
      );
      // Nếu thành công (cực kỳ hiếm) → tài khoản tồn tại với provider password
      await _firebaseAuth.signOut();
      return 'password';
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        // Tài khoản tồn tại nhưng sai mật khẩu → provider password
        case 'wrong-password':
          return 'password';

        // Tài khoản không tồn tại trên Firebase
        case 'user-not-found':
          return null;

        // Firebase trả lỗi chung — tài khoản tồn tại nhưng cần phân biệt
        // provider password vs Google. Thử gửi reset email để xác nhận:
        // nếu thành công → có password, nếu lỗi → Google-only.
        case 'invalid-credential':
          try {
            await _firebaseAuth.sendPasswordResetEmail(email: normalisedEmail);
            // Nếu gửi được reset email → tài khoản có provider password
            return 'password';
          } on firebase_auth.FirebaseAuthException catch (resetError) {
            if (resetError.code == 'user-not-found') {
              return null;
            }
            // Tài khoản tồn tại nhưng không phải password → Google
            return 'google';
          }

        // Tài khoản bị vô hiệu hóa nhưng vẫn tồn tại
        case 'user-disabled':
          return 'password';

        default:
          return null;
      }
    }
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
    // Bước 1: Sign-in tạm bằng PhoneAuthCredential để Firebase tạo phiên
    // có phone_number claim trong token — Cloud Function sẽ đọc claim này.
    if (_firebaseAuth.currentUser?.phoneNumber == null) {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      await _firebaseAuth.signInWithCredential(credential);
    }

    try {
      // Bước 2: Gọi Cloud Function resetPasswordByPhone — chỉ truyền
      // newPassword, function tự lấy phone từ ctx.auth.token.phone_number.
      final callable = FirebaseFunctions.instance.httpsCallable(
        'resetPasswordByPhone',
      );
      await callable.call<dynamic>({'newPassword': newPassword});
    } finally {
      // Bước 3: Luôn xoá phiên tạm Phone Auth dù function thành công hay không
      await _firebaseAuth.signOut();
    }
  }

  @override
  Future<User?> findLocalUserById(int userId) async {
    return _userDao.findById(userId);
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    _userStreamController.add(null);
  }

  @override
  Stream<User?> userChanges() => _userStreamController.stream;

  Future<User> _syncLocalUserAfterFirebaseLogin({
    required firebase_auth.User firebaseUser,
    required String? normalisedPhone,
    required String? normalisedEmail,
    required AppAuthProvider authProvider,
  }) async {
    final now = DateTime.now();
    final existingByUid = await _userDao.findByFirebaseUid(firebaseUser.uid);
    if (existingByUid != null) {
      final updated = User(
        id: existingByUid.id,
        fullName: _pickFirstNonEmpty(
          existingByUid.fullName,
          firebaseUser.displayName,
          'Người dùng CoinNest',
        ),
        phone: existingByUid.phone ?? normalisedPhone,
        email: existingByUid.email ?? normalisedEmail,
        passwordHash: existingByUid.passwordHash,
        passwordSalt: existingByUid.passwordSalt,
        firebaseUid: existingByUid.firebaseUid,
        authProvider: existingByUid.authProvider,
        avatarPath: existingByUid.avatarPath,
        createdAt: existingByUid.createdAt,
        updatedAt: now,
      );
      await _userDao.update(updated);
      return updated;
    }

    // Dữ liệu cũ có thể đã tạo local user trước khi đồng bộ firebase_uid.
    // Fallback theo identifier giúp nâng cấp hồ sơ thay vì tạo user trùng.
    User? existingByIdentifier;
    if (normalisedPhone != null) {
      existingByIdentifier = await _userDao.findByPhone(normalisedPhone);
    }
    if (existingByIdentifier == null && normalisedEmail != null) {
      existingByIdentifier = await _userDao.findByEmail(normalisedEmail);
    }
    if (existingByIdentifier != null) {
      final migrated = User(
        id: existingByIdentifier.id,
        fullName: _pickFirstNonEmpty(
          existingByIdentifier.fullName,
          firebaseUser.displayName,
          'Người dùng CoinNest',
        ),
        phone: existingByIdentifier.phone ?? normalisedPhone,
        email: existingByIdentifier.email ?? normalisedEmail,
        passwordHash: existingByIdentifier.passwordHash,
        passwordSalt: existingByIdentifier.passwordSalt,
        firebaseUid: firebaseUser.uid,
        authProvider: existingByIdentifier.authProvider,
        avatarPath: existingByIdentifier.avatarPath,
        createdAt: existingByIdentifier.createdAt,
        updatedAt: now,
      );
      await _userDao.update(migrated);
      return migrated;
    }

    final newUser = User(
      fullName: _pickFirstNonEmpty(
        firebaseUser.displayName,
        'Người dùng CoinNest',
      ),
      phone: normalisedPhone,
      email: normalisedEmail,
      passwordHash: null,
      passwordSalt: null,
      firebaseUid: firebaseUser.uid,
      authProvider: authProvider.value,
      avatarPath: null,
      createdAt: now,
      updatedAt: now,
    );
    final userId = await _userDao.insert(newUser);
    await _dbHelper.seedDefaultCategories(userId);
    await _dbHelper.seedDefaultAccount(userId);
    return newUser.copyWith(id: userId);
  }

  bool _isEmail(String value) => value.contains('@');

  String _pickFirstNonEmpty(
    String? primary, [
    String? secondary,
    String? third,
  ]) {
    if (primary != null && primary.trim().isNotEmpty) return primary;
    if (secondary != null && secondary.trim().isNotEmpty) return secondary;
    if (third != null && third.trim().isNotEmpty) return third;
    return 'Người dùng CoinNest';
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

  String _mapFirebaseAuthError(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau.';
      case 'quota-exceeded':
        return 'Dịch vụ OTP đang quá tải. Vui lòng thử lại sau.';
      case 'invalid-verification-code':
      case 'session-expired':
      case 'invalid-verification-id':
        return 'Mã OTP không hợp lệ hoặc đã hết hạn';
      case 'email-already-in-use':
        return 'Tài khoản đã được đăng ký';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Thông tin đăng nhập không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'weak-password':
        return 'Mật khẩu chưa đủ mạnh theo yêu cầu Firebase';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
      default:
        return error.message ?? 'Xác thực thất bại. Vui lòng thử lại.';
    }
  }
}
