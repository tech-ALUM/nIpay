import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

abstract interface class AttachmentRepository {
  Future<String> add({
    required String transactionId,
    required String relativePath,
    required String mimeType,
  });
  Future<List<Attachment>> listOf(String transactionId);
  Future<void> softDelete(String id);
}

class DriftAttachmentRepository implements AttachmentRepository {
  DriftAttachmentRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> add({
    required String transactionId,
    required String relativePath,
    required String mimeType,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.attachments).insert(AttachmentsCompanion.insert(
          id: id,
          transactionId: transactionId,
          relativePath: relativePath,
          mimeType: mimeType,
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  @override
  Future<List<Attachment>> listOf(String transactionId) =>
      (_db.select(_db.attachments)
            ..where((t) =>
                t.deletedAt.isNull() & t.transactionId.equals(transactionId)))
          .get();

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.attachments)..where((t) => t.id.equals(id))).write(
        AttachmentsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
