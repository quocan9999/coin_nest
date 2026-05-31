import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

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
      _errorMessage = _messageFromError(e);
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
      _errorMessage = _messageFromError(e);
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
        throw StateError('Chua co ban sao luu tren cloud');
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

  String? _validatedUid(User? currentUser) {
    final firebaseUid = _firebaseAuth.currentUser?.uid;
    if (currentUser == null || currentUser.id == null) {
      _errorMessage = 'Ban can dang nhap de sao luu du lieu';
      notifyListeners();
      return null;
    }
    if (firebaseUid == null || firebaseUid != currentUser.firebaseUid) {
      _errorMessage = 'Tai khoan Firebase khong khop voi nguoi dung hien tai';
      notifyListeners();
      return null;
    }
    return firebaseUid;
  }

  String _messageFromError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
