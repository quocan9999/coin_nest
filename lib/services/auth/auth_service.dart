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
/// Phase 1 keeps backward-compatible local flows while exposing future
/// Firebase-ready APIs for OTP, Google sign-in, and email auth.
abstract class AuthService {
  Future<AuthResult> registerWithPhone({
    required String fullName,
    required String phone,
    required String password,
    String? otpVerificationId,
    String? otpCode,
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

  Future<bool> confirmPhoneOtp(String verificationId, String code);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> resetPasswordByPhone({
    required String verificationId,
    required String otpCode,
    required String newPassword,
  });

  /// Transitional helper for current local "phone + new password" screen.
  Future<AuthResult> resetPasswordWithPhoneLocal({
    required String phone,
    required String newPassword,
  });

  Future<User?> findLocalUserById(int userId);

  Future<void> logout();

  Stream<User?> userChanges();
}
