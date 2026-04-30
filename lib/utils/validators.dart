import 'constants.dart';

/// Input validation helpers.
///
/// Every validator returns `null` on success or a user-facing error message
/// on failure — ready to plug directly into [TextFormField.validator].
class Validators {
  Validators._();

  // ─── Generic ───────────────────────────────────────────────────

  static String? required(String? value, [String fieldName = 'Trường này']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int max, [
    String fieldName = 'Trường này',
  ]) {
    if (value != null && value.length > max) {
      return '$fieldName không được quá $max ký tự';
    }
    return null;
  }

  // ─── Phone ──────────────────────────────────────────────────────

  static final _phoneRegex = RegExp(r'^(0|\+84)\d{9,10}$');

  static String? phoneVN(String? value) {
    final req = required(value, 'Số điện thoại');
    if (req != null) return req;

    final normalised = value!.replaceAll(RegExp(r'\s+'), '');
    if (!_phoneRegex.hasMatch(normalised)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  // ─── Password ──────────────────────────────────────────────────

  static String? password(String? value) {
    final req = required(value, 'Mật khẩu');
    if (req != null) return req;

    if (value!.length < AppConstants.minPasswordLength) {
      return 'Mật khẩu phải có ít nhất ${AppConstants.minPasswordLength} ký tự';
    }
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Mật khẩu không được quá ${AppConstants.maxPasswordLength} ký tự';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final req = required(value, 'Xác nhận mật khẩu');
    if (req != null) return req;

    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  // ─── Full Name ─────────────────────────────────────────────────

  static String? fullName(String? value) {
    final req = required(value, 'Họ tên');
    if (req != null) return req;

    if (value!.trim().length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }
    final ml = maxLength(value, AppConstants.maxNameLength, 'Họ tên');
    if (ml != null) return ml;

    return null;
  }

  // ─── Amount ────────────────────────────────────────────────────

  static String? amount(String? value) {
    final req = required(value, 'Số tiền');
    if (req != null) return req;

    // Strip thousand separators that the user might type
    final cleaned = value!.replaceAll(RegExp(r'[.\s,]'), '');
    final parsed = double.tryParse(cleaned);

    if (parsed == null) {
      return 'Số tiền không hợp lệ';
    }
    if (parsed <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }
    if (parsed > AppConstants.maxAmount) {
      return 'Số tiền quá lớn (tối đa 999 tỷ)';
    }
    return null;
  }

  /// Parse a user-typed amount string into a [double].
  /// Returns 0 if unparseable (caller should validate first).
  static double parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[.\s,đ₫]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  // ─── Account / Category Name ───────────────────────────────────

  static String? entityName(String? value, [String fieldName = 'Tên']) {
    final req = required(value, fieldName);
    if (req != null) return req;

    final ml = maxLength(value, AppConstants.maxNameLength, fieldName);
    if (ml != null) return ml;

    return null;
  }

  // ─── Note ──────────────────────────────────────────────────────

  static String? note(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    return maxLength(value, AppConstants.maxNoteLength, 'Ghi chú');
  }

  // ─── Date ──────────────────────────────────────────────────────

  static String? dateNotEmpty(DateTime? value) {
    if (value == null) {
      return 'Vui lòng chọn ngày';
    }
    return null;
  }

  // ─── Interest Rate ─────────────────────────────────────────────

  static String? interestRate(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > 100) {
      return 'Lãi suất phải từ 0% đến 100%';
    }
    return null;
  }
}
