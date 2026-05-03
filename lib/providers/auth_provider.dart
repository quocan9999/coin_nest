import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/user_dao.dart';
import '../models/user.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/firebase_auth_service.dart';
import '../utils/security_utils.dart';

/// Manages authentication state: login, register, logout, session persistence.
class AuthProvider extends ChangeNotifier {
  final UserDao _userDao;
  final AuthService _authService;

  AuthProvider({UserDao? userDao, AuthService? authService})
    : _userDao = userDao ?? UserDao(),
      _authService = authService ?? FirebaseAuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirstLaunch = true;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFirstLaunch => _isFirstLaunch;
  int get currentUserId => _currentUser?.id ?? 0;

  // ─── Initialisation ────────────────────────────────────────────

  /// Called once at app start — restores session from shared prefs.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    final userId = prefs.getInt('logged_in_user_id');
    if (userId != null) {
      _currentUser = await _authService.findLocalUserById(userId);
    }
    notifyListeners();
  }

  /// Mark onboarding as completed.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    _isFirstLaunch = false;
    notifyListeners();
  }

  // ─── Register ──────────────────────────────────────────────────

  Future<String?> requestPhoneRegistrationOtp({required String phone}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final verificationId = await _authService.requestPhoneOtp(phone);
      _setLoading(false);
      return verificationId;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> confirmPhoneRegistration({
    required String fullName,
    required String phone,
    required String password,
    required String otpVerificationId,
    required String otpCode,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _authService.registerWithPhone(
      fullName: fullName,
      phone: phone,
      password: password,
      otpVerificationId: otpVerificationId,
      otpCode: otpCode,
    );

    if (result.isSuccess && result.user?.id != null) {
      _currentUser = result.user;
      await _persistSession(result.user!.id!);
      _setLoading(false);
      return true;
    }

    _errorMessage =
        result.errorMessage ?? 'Đăng ký thất bại. Vui lòng thử lại.';
    _setLoading(false);
    return false;
  }

  // ─── Login ─────────────────────────────────────────────────────

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _authService.loginWithIdentifier(
      identifier: identifier,
      password: password,
    );

    if (result.isSuccess && result.user?.id != null) {
      _currentUser = result.user;
      await _persistSession(result.user!.id!);
      _setLoading(false);
      return true;
    }

    _errorMessage =
        result.errorMessage ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
    _setLoading(false);
    return false;
  }

  // ─── Logout ────────────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    notifyListeners();
  }

  // ─── Password Reset (local-only placeholder) ──────────────────

  Future<bool> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final result = await _authService.resetPasswordWithPhoneLocal(
      phone: phone,
      newPassword: newPassword,
    );
    if (result.isSuccess) {
      _setLoading(false);
      return true;
    }

    _errorMessage = result.errorMessage ?? 'Đặt lại mật khẩu thất bại.';
    _setLoading(false);
    return false;
  }

  // ─── Update Profile ────────────────────────────────────────────

  Future<bool> updateProfile({String? fullName, String? avatarPath}) async {
    if (_currentUser == null) return false;

    try {
      final updated = _currentUser!.copyWith(
        fullName: fullName != null
            ? SecurityUtils.sanitise(fullName)
            : _currentUser!.fullName,
        avatarPath: avatarPath ?? _currentUser!.avatarPath,
        updatedAt: DateTime.now(),
      );

      await _userDao.update(updated);
      _currentUser = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Future<void> _persistSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('logged_in_user_id', userId);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
