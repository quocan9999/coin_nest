class PhoneUtils {
  PhoneUtils._();

  static final RegExp _nonDigitExceptPlus = RegExp(r'[^\d+]');
  static final RegExp _vnLocalRegex = RegExp(r'^0?\d{9}$');
  static final RegExp _vnE164Regex = RegExp(r'^\+84\d{9}$');

  /// Validates local VN input for UI field when +84 is shown outside the field.
  /// Accepted samples: 0123456789, 123456789.
  static bool isValidVnLocalInput(String value) {
    final clean = _stripSpacesAndSymbols(value);
    return _vnLocalRegex.hasMatch(clean);
  }

  /// Accept both local and full formats while app transitions between old/new UI.
  static bool isValidVnInputFlexible(String value) {
    final clean = _stripSpacesAndSymbols(value);
    if (_vnLocalRegex.hasMatch(clean)) return true;
    return _vnE164Regex.hasMatch(clean) || RegExp(r'^84\d{9}$').hasMatch(clean);
  }

  /// Canonicalises any accepted VN phone input to E.164: +84xxxxxxxxx
  static String normaliseVnPhone(String raw) {
    final clean = _stripSpacesAndSymbols(raw);

    if (clean.startsWith('+84')) {
      final local = clean.substring(3);
      if (!_vnLocalRegex.hasMatch(local)) {
        throw const FormatException('Số điện thoại không hợp lệ.');
      }
      return '+84${_localDigits(local)}';
    }

    if (clean.startsWith('84')) {
      final local = clean.substring(2);
      if (!_vnLocalRegex.hasMatch(local)) {
        throw const FormatException('Số điện thoại không hợp lệ.');
      }
      return '+84${_localDigits(local)}';
    }

    if (!_vnLocalRegex.hasMatch(clean)) {
      throw const FormatException('Số điện thoại không hợp lệ.');
    }

    return '+84${_localDigits(clean)}';
  }

  /// Converts +84xxxxxxxxx to an email key used by Firebase Email/Password.
  static String phoneToSyntheticEmail(String phoneE164) {
    final digits = phoneE164.replaceAll(RegExp(r'[^\d]'), '');
    return '$digits@phone.coinnest.app';
  }

  static String _localDigits(String value) {
    return value.startsWith('0') ? value.substring(1) : value;
  }

  static String _stripSpacesAndSymbols(String value) {
    return value.trim().replaceAll(_nonDigitExceptPlus, '');
  }
}
