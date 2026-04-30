import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../database/user_dao.dart';
import '../models/user.dart';
import '../utils/security_utils.dart';

/// Manages authentication state: login, register, logout, session persistence.
class AuthProvider extends ChangeNotifier {
  final _userDao = UserDao();
  final _dbHelper = DatabaseHelper.instance;

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
      _currentUser = await _userDao.findById(userId);
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

  Future<bool> register({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Sanitise inputs
      final cleanName = SecurityUtils.sanitise(fullName);
      final cleanPhone = _normalisePhone(SecurityUtils.sanitise(phone));

      // Check uniqueness
      if (await _userDao.phoneExists(cleanPhone)) {
        _errorMessage = 'Số điện thoại đã được đăng ký';
        return false;
      }

      // Hash password
      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(password, salt);

      final now = DateTime.now();
      final user = User(
        fullName: cleanName,
        phone: cleanPhone,
        passwordHash: hash,
        passwordSalt: salt,
        createdAt: now,
        updatedAt: now,
      );

      final userId = await _userDao.insert(user);

      // Seed default data
      await _dbHelper.seedDefaultCategories(userId);
      await _dbHelper.seedDefaultAccount(userId);

      // Auto-login
      _currentUser = user.copyWith(id: userId);
      await _persistSession(userId);

      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(
        e,
        fallback: 'Đăng ký thất bại. Vui lòng thử lại.',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Login ─────────────────────────────────────────────────────

  Future<bool> login({required String phone, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final cleanPhone = _normalisePhone(SecurityUtils.sanitise(phone));

      final user = await _userDao.findByPhone(cleanPhone);
      if (user == null) {
        _errorMessage = 'Số điện thoại hoặc mật khẩu không đúng';
        return false;
      }

      final valid = SecurityUtils.verifyPassword(
        password,
        user.passwordHash,
        user.passwordSalt,
      );
      if (!valid) {
        _errorMessage = 'Số điện thoại hoặc mật khẩu không đúng';
        return false;
      }

      _currentUser = user;
      await _persistSession(user.id!);
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(
        e,
        fallback: 'Đăng nhập thất bại. Vui lòng thử lại.',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Logout ────────────────────────────────────────────────────

  Future<void> logout() async {
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

    try {
      final cleanPhone = _normalisePhone(SecurityUtils.sanitise(phone));
      final user = await _userDao.findByPhone(cleanPhone);

      if (user == null) {
        _errorMessage = 'Không tìm thấy tài khoản với số điện thoại này';
        return false;
      }

      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(newPassword, salt);
      await _userDao.updatePassword(user.id!, hash, salt);

      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e, fallback: 'Đặt lại mật khẩu thất bại.');
      return false;
    } finally {
      _setLoading(false);
    }
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

  // Chuẩn hóa về một format trước khi validate/so sánh giúp tránh sai lệch đăng nhập và trùng tài khoản.
  String _normalisePhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\s+'), '');
    if (digitsOnly.startsWith('+84')) {
      return '0${digitsOnly.substring(3)}';
    }
    return digitsOnly;
  }

  // Hàm này gom các lỗi thường gặp thành message nghiệp vụ để UX nhất quán giữa các luồng auth.
  // Nếu không nhận diện được lỗi, giữ fallback để luôn có thông điệp ổn định cho người dùng.
  String _mapAuthError(Object error, {required String fallback}) {
    final message = error.toString().toLowerCase();

    if (message.contains('unique constraint failed') &&
        message.contains('users.phone')) {
      return 'Số điện thoại đã được đăng ký';
    }

    if (message.contains('database is locked')) {
      return 'Thao tác chưa thể hoàn tất lúc này. Vui lòng thử lại sau ít phút.';
    }

    return fallback;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
