import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'constants.dart';

/// Cryptographic helpers for password hashing and secure random generation.
///
/// Uses SHA-256 + per-user random salt.  This is acceptable for a local-only
/// SQLite app.  When a backend is later introduced, migrate to bcrypt / Argon2.
class SecurityUtils {
  SecurityUtils._();

  static final _secureRandom = Random.secure();

  // ─── Salt ──────────────────────────────────────────────────────

  /// Generate a cryptographically secure random salt encoded as Base-64.
  static String generateSalt([int length = AppConstants.saltLength]) {
    final bytes = List<int>.generate(length, (_) => _secureRandom.nextInt(256));
    return base64Url.encode(bytes);
  }

  // ─── Password Hashing ─────────────────────────────────────────

  /// Hash [password] with the given [salt] using SHA-256.
  ///
  /// Format: `SHA256(salt + password)` stored as hex.
  static String hashPassword(String password, String salt) {
    final input = utf8.encode('$salt$password');
    final digest = sha256.convert(input);
    return digest.toString();
  }

  /// Verify that [password] matches [storedHash] given [salt].
  static bool verifyPassword(
      String password, String storedHash, String salt) {
    final computedHash = hashPassword(password, salt);
    // Constant-time comparison to prevent timing attacks.
    return _constantTimeEquals(computedHash, storedHash);
  }

  /// Constant-time string comparison to mitigate timing side-channels.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // ─── Session Token ─────────────────────────────────────────────

  /// Generate a random session token (Base‑64, 32 bytes).
  static String generateSessionToken() {
    return generateSalt(32);
  }

  // ─── Input Sanitisation ────────────────────────────────────────

  /// Strip control characters and trim whitespace.
  ///
  /// This does **not** replace parameterised queries — it adds a defence-in-
  /// depth layer before data reaches the DB layer.
  static String sanitise(String input) {
    // Remove control characters (U+0000–U+001F, U+007F) except \n and \t
    return input
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
  }

  /// Sanitise and enforce a maximum length.
  static String sanitiseWithLimit(String input, int maxLength) {
    final clean = sanitise(input);
    if (clean.length > maxLength) {
      return clean.substring(0, maxLength);
    }
    return clean;
  }
}
