import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/backup_dao.dart';
import '../models/user.dart';
import '../services/backup/cloud_backup_service.dart';

class BackupProvider extends ChangeNotifier {
  BackupProvider({
    BackupDao? backupDao,
    CloudBackupService? cloudBackupService,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _backupDao = backupDao ?? BackupDao(),
       _cloudBackupService = cloudBackupService ?? CloudBackupService(),
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  final BackupDao _backupDao;
  final CloudBackupService _cloudBackupService;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  CloudBackupMetadata? _metadata;
  bool _isLoading = false;
  String? _errorMessage;

  CloudBackupMetadata? get metadata => _metadata;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMetadata(User? currentUser) async {
    final uid = _validatedUid(currentUser);
    if (uid == null) return;

    _setLoading(true);
    try {
      _metadata = await _cloudBackupService.getCurrentMetadata(uid);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _messageFromError(e, fallback: _networkErrorMessage);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> backupNow(User? currentUser) async {
    final uid = _validatedUid(currentUser);
    final userId = currentUser?.id;
    if (uid == null || userId == null) return false;

    _setLoading(true);
    try {
      final snapshot = await _backupDao.createSnapshot(userId);
      _metadata = await _cloudBackupService.uploadCurrent(
        uid: uid,
        snapshot: snapshot,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _messageFromError(e, fallback: _networkErrorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restoreCurrent(User? currentUser) async {
    final uid = _validatedUid(currentUser);
    final userId = currentUser?.id;
    if (uid == null || userId == null) return false;

    _setLoading(true);
    try {
      final download = await _cloudBackupService.downloadCurrent(uid);
      if (download == null) {
        throw const BackupProviderException(
          BackupProviderError.noBackup,
          'Chưa có bản sao lưu trên cloud.',
        );
      }

      await _backupDao.restoreSnapshot(
        userId: userId,
        payload: download.payload,
        expectedSha256: download.metadata.payloadSha256,
      );
      _metadata = download.metadata;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _messageFromError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCurrentBackup(User? currentUser) async {
    final uid = _validatedUid(currentUser);
    if (uid == null) return false;

    _setLoading(true);
    try {
      await _cloudBackupService.deleteCurrent(uid);
      _metadata = null;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _messageFromError(e, fallback: _networkErrorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String? _validatedUid(User? currentUser) {
    final firebaseUid = _firebaseAuth.currentUser?.uid;
    if (currentUser == null || currentUser.id == null) {
      _errorMessage = 'Bạn cần đăng nhập để sao lưu dữ liệu.';
      notifyListeners();
      return null;
    }
    if (firebaseUid == null || firebaseUid != currentUser.firebaseUid) {
      _errorMessage = 'Tài khoản Firebase không khớp với người dùng hiện tại.';
      notifyListeners();
      return null;
    }
    return firebaseUid;
  }

  String _messageFromError(Object error, {String? fallback}) {
    if (error is BackupProviderException) return error.message;
    if (error is CloudBackupException) {
      switch (error.error) {
        case CloudBackupError.incompleteSnapshot:
          return 'Bản sao lưu trên cloud chưa đầy đủ. Vui lòng sao lưu lại.';
      }
    }
    if (error is BackupDataException) {
      switch (error.error) {
        case BackupDataError.checksum:
          return 'Bản sao lưu không hợp lệ.';
        case BackupDataError.unsupportedFormat:
        case BackupDataError.missingTable:
        case BackupDataError.invalidReference:
          return 'Khôi phục thất bại. Dữ liệu trên thiết bị đã được giữ nguyên.';
      }
    }
    if (error is FirebaseException) {
      return fallback ?? _networkErrorMessage;
    }
    if (error is DatabaseException) return fallback ?? _restoreErrorMessage;
    if (error is FormatException) {
      return 'Bản sao lưu không hợp lệ.';
    }
    return fallback ?? _restoreErrorMessage;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

const _networkErrorMessage =
    'Không thể kết nối Firestore. Vui lòng kiểm tra mạng và thử lại.';
const _restoreErrorMessage =
    'Khôi phục thất bại. Dữ liệu trên thiết bị đã được giữ nguyên.';

enum BackupProviderError { noBackup }

class BackupProviderException implements Exception {
  const BackupProviderException(this.error, this.message);

  final BackupProviderError error;
  final String message;

  @override
  String toString() => message;
}
