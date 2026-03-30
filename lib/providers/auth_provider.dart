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
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Sanitise inputs
      final cleanName = SecurityUtils.sanitise(fullName);
      final cleanEmail = SecurityUtils.sanitise(email).toLowerCase();

      // Check uniqueness
      if (await _userDao.emailExists(cleanEmail)) {
        _errorMessage = 'Email đã được đăng ký';
        return false;
      }

      // Hash password
      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(password, salt);

      final now = DateTime.now();
      final user = User(
        fullName: cleanName,
        email: cleanEmail,
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
      _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Login ─────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final cleanEmail = SecurityUtils.sanitise(email).toLowerCase();

      final user = await _userDao.findByEmail(cleanEmail);
      if (user == null) {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
        return false;
      }

      final valid =
          SecurityUtils.verifyPassword(password, user.passwordHash, user.passwordSalt);
      if (!valid) {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
        return false;
      }

      _currentUser = user;
      await _persistSession(user.id!);
      return true;
    } catch (e) {
      _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
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
    required String email,
    required String newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final cleanEmail = SecurityUtils.sanitise(email).toLowerCase();
      final user = await _userDao.findByEmail(cleanEmail);

      if (user == null) {
        _errorMessage = 'Không tìm thấy tài khoản với email này';
        return false;
      }

      final salt = SecurityUtils.generateSalt();
      final hash = SecurityUtils.hashPassword(newPassword, salt);
      await _userDao.updatePassword(user.id!, hash, salt);

      return true;
    } catch (e) {
      _errorMessage = 'Đặt lại mật khẩu thất bại';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
