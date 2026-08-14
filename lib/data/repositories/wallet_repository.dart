import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// Contratto usato dalla UI: nessun riferimento a Drift fuori da qui.
abstract interface class WalletRepository {
  Future<String> create({
    required String name,
    required String colorHex,
    int initialBalanceCents,
    String currency,
  });
  Future<List<Wallet>> getAll();
  Stream<List<Wallet>> watchAll();
  Future<void> rename(String id, String name);

  /// Sposta il portafoglio a [newIndex] ricompattando le posizioni.
  Future<void> move(String id, int newIndex);
  Future<void> softDelete(String id);

  /// Cambia la valuta del portafoglio: converte con [rate] (valuta attuale →
  /// [newCurrency]) solo il saldo iniziale. Le transazioni storiche, i
  /// budget e le regole ricorrenti NON vengono toccati — restano nei loro
  /// importi originali, ora semplicemente letti nella nuova valuta. Il
  /// tasso va calcolato dalla UI (repository resta senza rete).
  Future<void> changeCurrency(String id, String newCurrency, double rate);
}

class DriftWalletRepository implements WalletRepository {
  DriftWalletRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  SimpleSelectStatement<$WalletsTable, Wallet> _alive() =>
      _db.select(_db.wallets)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.position)]);

  @override
  Future<String> create({
    required String name,
    required String colorHex,
    int initialBalanceCents = 0,
    String currency = 'EUR',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final count = (await _alive().get()).length;
    await _db
        .into(_db.wallets)
        .insert(
          WalletsCompanion.insert(
            id: id,
            name: name,
            colorHex: colorHex,
            initialBalanceCents: Value(initialBalanceCents),
            position: Value(count),
            currency: Value(currency),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<List<Wallet>> getAll() => _alive().get();

  @override
  Stream<List<Wallet>> watchAll() => _alive().watch();

  @override
  Future<void> rename(String id, String name) =>
      (_db.update(_db.wallets)..where((t) => t.id.equals(id))).write(
        WalletsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  @override
  Future<void> move(String id, int newIndex) async {
    final wallets = await _alive().get();
    final moving = wallets.firstWhere((w) => w.id == id);
    final reordered = [...wallets]..remove(moving);
    reordered.insert(newIndex.clamp(0, reordered.length), moving);

    final now = DateTime.now();
    await _db.batch((b) {
      for (final (i, wallet) in reordered.indexed) {
        if (wallet.position != i) {
          b.update(
            _db.wallets,
            WalletsCompanion(position: Value(i), updatedAt: Value(now)),
            where: ($WalletsTable t) => t.id.equals(wallet.id),
          );
        }
      }
    });
  }

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.wallets)..where((t) => t.id.equals(id))).write(
        WalletsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> changeCurrency(
    String id,
    String newCurrency,
    double rate,
  ) async {
    final wallet = await (_db.select(
      _db.wallets,
    )..where((t) => t.id.equals(id))).getSingle();
    if (wallet.currency == newCurrency) return;
    await (_db.update(_db.wallets)..where((t) => t.id.equals(id))).write(
      WalletsCompanion(
        currency: Value(newCurrency),
        initialBalanceCents: Value(
          (wallet.initialBalanceCents * rate).round(),
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
