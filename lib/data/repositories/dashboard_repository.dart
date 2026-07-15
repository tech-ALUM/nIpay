import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

abstract interface class DashboardRepository {
  /// Aggiunge una card in coda alla dashboard.
  Future<String> addCard({required String type, String configJson});
  Future<List<DashboardCard>> getCards();
  Stream<List<DashboardCard>> watchCards();

  /// Sposta la card a [newIndex] ricompattando le posizioni.
  Future<void> moveCard(String id, int newIndex);
  Future<void> updateConfig(String id, String configJson);
  Future<void> removeCard(String id);
}

class DriftDashboardRepository implements DashboardRepository {
  DriftDashboardRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  SimpleSelectStatement<$DashboardCardsTable, DashboardCard> get _alive =>
      _db.select(_db.dashboardCards)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.position)]);

  @override
  Future<String> addCard({required String type, String configJson = '{}'}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final count = (await _alive.get()).length;
    await _db.into(_db.dashboardCards).insert(DashboardCardsCompanion.insert(
          id: id,
          type: type,
          position: count,
          configJson: Value(configJson),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  @override
  Future<List<DashboardCard>> getCards() => _alive.get();

  @override
  Stream<List<DashboardCard>> watchCards() => _alive.watch();

  @override
  Future<void> moveCard(String id, int newIndex) async {
    final cards = await _alive.get();
    final moving = cards.firstWhere((c) => c.id == id);
    final reordered = [...cards]..remove(moving);
    reordered.insert(newIndex.clamp(0, reordered.length), moving);

    final now = DateTime.now();
    await _db.batch((b) {
      for (final (i, card) in reordered.indexed) {
        if (card.position != i) {
          b.update(
            _db.dashboardCards,
            DashboardCardsCompanion(position: Value(i), updatedAt: Value(now)),
            where: ($DashboardCardsTable t) => t.id.equals(card.id),
          );
        }
      }
    });
  }

  @override
  Future<void> updateConfig(String id, String configJson) =>
      (_db.update(_db.dashboardCards)..where((t) => t.id.equals(id))).write(
        DashboardCardsCompanion(
          configJson: Value(configJson),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> removeCard(String id) =>
      (_db.update(_db.dashboardCards)..where((t) => t.id.equals(id))).write(
        DashboardCardsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
