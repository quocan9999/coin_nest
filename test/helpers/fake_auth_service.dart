import 'package:coin_nest/models/user.dart';
import 'package:coin_nest/services/auth/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService(this.user);

  final User user;
  bool isLoggedOut = false;

  @override
  Future<AuthResult> registerWithPhone({
    required String fullName,
    required String phone,
    required String password,
    required String otpVerificationId,
    required String otpCode,
  }) async {
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> loginWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> loginWithGoogle() async {
    return AuthResult.success(user);
  }

  @override
  Future<String> requestPhoneOtp(String phone) async {
    return 'test-verification-id';
  }

  @override
  Future<String> requestForgotPasswordOtp(String phone) async {
    return 'test-forgot-password-verification-id';
  }

  @override
  Future<bool> confirmPhoneOtp(String verificationId, String code) async {
    return true;
  }

  @override
  Future<String?> checkAccountProvider(String email) async {
    return 'password';
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> resetPasswordByPhone({
    required String verificationId,
    required String otpCode,
    required String newPassword,
  }) async {}

  @override
  Future<User?> findLocalUserById(int userId) async {
    return user.id == userId ? user : null;
  }

  @override
  Future<void> logout() async {
    isLoggedOut = true;
  }

  @override
  Stream<User?> userChanges() {
    return Stream<User?>.value(user);
  }
}
