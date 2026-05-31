import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../database/backup_dao.dart';

class CloudBackupMetadata {
  CloudBackupMetadata({
    required this.ownerUid,
    required this.createdAt,
    required this.formatVersion,
    required this.sourceDbVersion,
    required this.appVersion,
    required this.payloadSha256,
    required this.chunkCount,
    required this.recordCounts,
  });

  final String ownerUid;
  final DateTime createdAt;
  final int formatVersion;
  final int sourceDbVersion;
  final String appVersion;
  final String payloadSha256;
  final int chunkCount;
  final Map<String, int> recordCounts;

  factory CloudBackupMetadata.fromMap(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    return CloudBackupMetadata(
      ownerUid: map['ownerUid'] as String,
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.parse(createdAtValue as String),
      formatVersion: map['formatVersion'] as int,
      sourceDbVersion: map['sourceDbVersion'] as int,
      appVersion: map['appVersion'] as String,
      payloadSha256: map['payloadSha256'] as String,
      chunkCount: map['chunkCount'] as int,
      recordCounts: Map<String, int>.from(map['recordCounts'] as Map),
    );
  }
}

class CloudBackupDownload {
  CloudBackupDownload({required this.metadata, required this.payload});

  final CloudBackupMetadata metadata;
  final Map<String, dynamic> payload;
}

class CloudBackupService {
  CloudBackupService({
    FirebaseFirestore? firestore,
    CloudBackupDocumentStore? store,
  }) : _store =
           store ?? FirestoreCloudBackupDocumentStore(firestore: firestore);

  static const int _chunkSize = 400000;

  final CloudBackupDocumentStore _store;

  Future<CloudBackupMetadata?> getCurrentMetadata(String uid) async {
    final data = await _store.getMetadata(uid);
    if (data == null) return null;
    return CloudBackupMetadata.fromMap(data);
  }

  Future<CloudBackupMetadata> uploadCurrent({
    required String uid,
    required BackupSnapshot snapshot,
  }) async {
    final chunks = _chunk(snapshot.payloadJson);
    final createdAt = DateTime.now().toUtc();

    await _store.replaceSnapshot(
      uid: uid,
      metadata: {
        'formatVersion': snapshot.formatVersion,
        'sourceDbVersion': snapshot.sourceDbVersion,
        'appVersion': snapshot.appVersion,
        'ownerUid': uid,
        'createdAt': Timestamp.fromDate(createdAt),
        'payloadSha256': snapshot.payloadSha256,
        'chunkCount': chunks.length,
        'recordCounts': snapshot.recordCounts,
      },
      chunks: chunks,
    );
    return CloudBackupMetadata(
      ownerUid: uid,
      createdAt: createdAt,
      formatVersion: snapshot.formatVersion,
      sourceDbVersion: snapshot.sourceDbVersion,
      appVersion: snapshot.appVersion,
      payloadSha256: snapshot.payloadSha256,
      chunkCount: chunks.length,
      recordCounts: snapshot.recordCounts,
    );
  }

  Future<CloudBackupDownload?> downloadCurrent(String uid) async {
    final data = await _store.getMetadata(uid);
    if (data == null) return null;

    final metadata = CloudBackupMetadata.fromMap(data);
    final chunks = await _store.getChunks(uid);
    if (chunks.length != metadata.chunkCount) {
      throw const CloudBackupException(
        CloudBackupError.incompleteSnapshot,
        'Bản sao lưu trên cloud chưa đầy đủ',
      );
    }

    final payloadJson = chunks.map((chunk) => chunk.data).join();
    return CloudBackupDownload(
      metadata: metadata,
      payload: jsonDecode(payloadJson) as Map<String, dynamic>,
    );
  }

  Future<void> deleteCurrent(String uid) {
    return _store.deleteSnapshot(uid);
  }

  List<String> _chunk(String value) {
    if (value.isEmpty) return [''];

    final chunks = <String>[];
    for (var start = 0; start < value.length; start += _chunkSize) {
      final end = start + _chunkSize > value.length
          ? value.length
          : start + _chunkSize;
      chunks.add(value.substring(start, end));
    }
    return chunks;
  }
}

enum CloudBackupError { incompleteSnapshot }

class CloudBackupException implements Exception {
  const CloudBackupException(this.error, this.message);

  final CloudBackupError error;
  final String message;

  @override
  String toString() => message;
}

class CloudBackupChunk {
  const CloudBackupChunk({required this.index, required this.data});

  final int index;
  final String data;
}

abstract class CloudBackupDocumentStore {
  Future<Map<String, dynamic>?> getMetadata(String uid);

  Future<List<CloudBackupChunk>> getChunks(String uid);

  Future<void> replaceSnapshot({
    required String uid,
    required Map<String, dynamic> metadata,
    required List<String> chunks,
  });

  Future<void> deleteSnapshot(String uid);
}

class FirestoreCloudBackupDocumentStore implements CloudBackupDocumentStore {
  FirestoreCloudBackupDocumentStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> getMetadata(String uid) async {
    final doc = await _snapshotDoc(uid).get();
    return doc.data();
  }

  @override
  Future<List<CloudBackupChunk>> getChunks(String uid) async {
    final chunksQuery = await _snapshotDoc(
      uid,
    ).collection('chunks').orderBy('index').get();

    return chunksQuery.docs
        .map(
          (doc) => CloudBackupChunk(
            index: doc.data()['index'] as int,
            data: doc.data()['data'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<void> replaceSnapshot({
    required String uid,
    required Map<String, dynamic> metadata,
    required List<String> chunks,
  }) async {
    final snapshotDoc = _snapshotDoc(uid);
    final chunksCollection = snapshotDoc.collection('chunks');

    await _deleteExistingChunks(chunksCollection);

    final batch = _firestore.batch();
    batch.set(snapshotDoc, metadata);

    for (var index = 0; index < chunks.length; index++) {
      batch.set(chunksCollection.doc(index.toString().padLeft(6, '0')), {
        'index': index,
        'data': chunks[index],
      });
    }

    await batch.commit();
  }

  @override
  Future<void> deleteSnapshot(String uid) async {
    final snapshotDoc = _snapshotDoc(uid);
    await _deleteExistingChunks(snapshotDoc.collection('chunks'));
    await snapshotDoc.delete();
  }

  DocumentReference<Map<String, dynamic>> _snapshotDoc(String uid) {
    return _firestore
        .collection('user_backups')
        .doc(uid)
        .collection('snapshots')
        .doc('current');
  }

  Future<void> _deleteExistingChunks(
    CollectionReference<Map<String, dynamic>> chunksCollection,
  ) async {
    var query = await chunksCollection.limit(500).get();
    while (query.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      query = await chunksCollection.limit(500).get();
    }
  }
}
