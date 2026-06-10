import 'dart:convert';

import 'package:coin_nest/database/backup_dao.dart';
import 'package:coin_nest/services/backup/cloud_backup_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'upload chia payload thanh nhieu chunks va download lai du lieu',
    () async {
      final store = _MemoryCloudBackupDocumentStore();
      final service = CloudBackupService(store: store);
      final snapshot = _snapshotWithNote(_largeText);

      final metadata = await service.uploadCurrent(
        uid: 'uid-1',
        snapshot: snapshot,
      );
      final download = await service.downloadCurrent('uid-1');

      expect(metadata.chunkCount, greaterThan(1));
      expect(store.chunksFor('uid-1'), hasLength(metadata.chunkCount));
      expect(download, isNotNull);
      expect(download!.payload['note'], snapshot.payload['note']);
    },
  );

  test('download fail khi cloud thieu chunk', () async {
    final store = _MemoryCloudBackupDocumentStore();
    final service = CloudBackupService(store: store);

    await service.uploadCurrent(
      uid: 'uid-1',
      snapshot: _snapshotWithNote(_largeText),
    );
    store.removeLastChunk('uid-1');

    expect(
      () => service.downloadCurrent('uid-1'),
      throwsA(isA<CloudBackupException>()),
    );
  });

  test('upload moi thay the chunks cu', () async {
    final store = _MemoryCloudBackupDocumentStore();
    final service = CloudBackupService(store: store);

    await service.uploadCurrent(
      uid: 'uid-1',
      snapshot: _snapshotWithNote(_largeText),
    );
    expect(store.chunksFor('uid-1'), hasLength(greaterThan(1)));

    await service.uploadCurrent(
      uid: 'uid-1',
      snapshot: _snapshotWithNote('short'),
    );
    final download = await service.downloadCurrent('uid-1');

    expect(store.chunksFor('uid-1'), hasLength(1));
    expect(download!.payload['note'], 'short');
  });

  test('deleteCurrent xoa metadata va chunks', () async {
    final store = _MemoryCloudBackupDocumentStore();
    final service = CloudBackupService(store: store);

    await service.uploadCurrent(
      uid: 'uid-1',
      snapshot: _snapshotWithNote('backup'),
    );
    await service.deleteCurrent('uid-1');

    expect(await service.getCurrentMetadata('uid-1'), isNull);
    expect(await service.downloadCurrent('uid-1'), isNull);
    expect(store.chunksFor('uid-1'), isEmpty);
  });
}

final _largeText = List.filled(900000, 'x').join();

BackupSnapshot _snapshotWithNote(String note) {
  final payload = <String, dynamic>{
    'formatVersion': BackupDao.formatVersion,
    'accounts': <Map<String, dynamic>>[],
    'categories': <Map<String, dynamic>>[],
    'transactions': <Map<String, dynamic>>[],
    'loans': <Map<String, dynamic>>[],
    'loan_payments': <Map<String, dynamic>>[],
    'budgets': <Map<String, dynamic>>[],
    'note': note,
  };
  final payloadJson = jsonEncode(payload);

  return BackupSnapshot(
    formatVersion: BackupDao.formatVersion,
    sourceDbVersion: 3,
    appVersion: '1.0.0',
    payload: payload,
    payloadSha256: sha256.convert(utf8.encode(payloadJson)).toString(),
    recordCounts: const {
      'accounts': 0,
      'categories': 0,
      'transactions': 0,
      'loans': 0,
      'loan_payments': 0,
      'budgets': 0,
    },
  );
}

class _MemoryCloudBackupDocumentStore implements CloudBackupDocumentStore {
  final _metadata = <String, Map<String, dynamic>>{};
  final _chunks = <String, List<CloudBackupChunk>>{};

  @override
  Future<Map<String, dynamic>?> getMetadata(String uid) async {
    return _metadata[uid];
  }

  @override
  Future<List<CloudBackupChunk>> getChunks(String uid) async {
    return List<CloudBackupChunk>.from(_chunks[uid] ?? const []);
  }

  @override
  Future<void> replaceSnapshot({
    required String uid,
    required Map<String, dynamic> metadata,
    required List<String> chunks,
  }) async {
    _metadata[uid] = Map<String, dynamic>.from(metadata);
    _chunks[uid] = [
      for (var index = 0; index < chunks.length; index++)
        CloudBackupChunk(index: index, data: chunks[index]),
    ];
  }

  @override
  Future<void> deleteSnapshot(String uid) async {
    _metadata.remove(uid);
    _chunks.remove(uid);
  }

  List<CloudBackupChunk> chunksFor(String uid) {
    return _chunks[uid] ?? const [];
  }

  void removeLastChunk(String uid) {
    _chunks[uid]?.removeLast();
  }
}
