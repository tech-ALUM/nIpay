import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

abstract interface class TagRepository {
  Future<String> create(String name);
  Future<List<Tag>> getAll();
  Future<void> tagTransaction(String transactionId, String tagId);
  Future<void> untagTransaction(String transactionId, String tagId);
  Future<List<Tag>> tagsOf(String transactionId);
  Future<void> softDelete(String id);
}

class DriftTagRepository implements TagRepository {
  DriftTagRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> create(String name) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.tags).insert(
        TagsCompanion.insert(id: id, name: name, createdAt: now, updatedAt: now));
    return id;
  }

  @override
  Future<List<Tag>> getAll() =>
      (_db.select(_db.tags)..where((t) => t.deletedAt.isNull())).get();

  @override
  Future<void> tagTransaction(String transactionId, String tagId) =>
      _db.into(_db.transactionTags).insert(
            TransactionTagsCompanion.insert(
              transactionId: transactionId,
              tagId: tagId,
              createdAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrIgnore,
          );

  @override
  Future<void> untagTransaction(String transactionId, String tagId) =>
      (_db.delete(_db.transactionTags)
            ..where((t) =>
                t.transactionId.equals(transactionId) & t.tagId.equals(tagId)))
          .go();

  @override
  Future<List<Tag>> tagsOf(String transactionId) {
    final query = _db.select(_db.tags).join([
      innerJoin(
          _db.transactionTags, _db.transactionTags.tagId.equalsExp(_db.tags.id)),
    ])
      ..where(_db.transactionTags.transactionId.equals(transactionId) &
          _db.tags.deletedAt.isNull());
    return query.map((row) => row.readTable(_db.tags)).get();
  }

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(
        TagsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
