import '../../models/user.dart';

enum AuthIdentifier { phone, email }

enum AppAuthProvider { phone, email, google }

extension AppAuthProviderValue on AppAuthProvider {
  String get value => switch (this) {
    AppAuthProvider.phone => 'phone',
    AppAuthProvider.email => 'email',
    AppAuthProvider.google => 'google',
  };
}

class AuthResult {
  final User? user;
  final String? errorMessage;

  const AuthResult._({this.user, this.errorMessage});

  bool get isSuccess => user != null && errorMessage == null;

  factory AuthResult.success(User user) => AuthResult._(user: user);

  factory AuthResult.failure(String message) =>
      AuthResult._(errorMessage: message);
}

/// Abstraction layer to decouple UI/provider from auth implementation.
///
/// Cung cấp contract chung cho mọi flow Firebase Auth: đăng ký,
/// đăng nhập, quên mật khẩu (email + phone + Google), và OTP.
abstract class AuthService {
  Future<AuthResult> registerWithPhone({
    required String fullName,
    required String phone,
    required String password,
    required String otpVerificationId,
    required String otpCode,
  });

  Future<AuthResult> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AuthResult> loginWithIdentifier({
    required String identifier,
    required String password,
  });

  Future<AuthResult> loginWithGoogle();

  Future<String> requestPhoneOtp(String phone);

  /// Gửi OTP cho luồng quên mật khẩu — KHÔNG check phoneExists
  /// (khác requestPhoneOtp dùng cho register — reject phone đã tồn tại).
  Future<String> requestForgotPasswordOtp(String phone);

  Future<bool> confirmPhoneOtp(String verificationId, String code);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> resetPasswordByPhone({
    required String verificationId,
    required String otpCode,
    required String newPassword,
  });


  Future<User?> findLocalUserById(int userId);

  Future<void> logout();

  Stream<User?> userChanges();
}
