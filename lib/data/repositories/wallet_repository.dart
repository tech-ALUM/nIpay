import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart' show TransactionType;

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

  /// Cambia il colore della card del portafoglio (`#RRGGBB`).
  Future<void> recolor(String id, String colorHex);

  /// Sposta il portafoglio a [newIndex] ricompattando le posizioni.
  Future<void> move(String id, int newIndex);
  Future<void> softDelete(String id);

  /// Cambia la valuta del portafoglio convertendo con [rate] (valuta
  /// attuale → [newCurrency]) tutto ciò che è espresso nella sua valuta:
  /// saldo iniziale, spese ed entrate, trasferimenti in uscita (addebito) e
  /// in entrata (accredito), budget e regole ricorrenti. Il saldo resta lo
  /// stesso valore, nella nuova valuta; gli altri portafogli non cambiano.
  /// Righe eliminate escluse. Tutto in un'unica transazione del DB. Il tasso
  /// va calcolato dalla UI (repository resta senza rete).
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
  Future<void> recolor(String id, String colorHex) =>
      (_db.update(_db.wallets)..where((t) => t.id.equals(id))).write(
        WalletsCompanion(
          colorHex: Value(colorHex),
          updatedAt: Value(DateTime.now()),
        ),
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
    int convert(int cents) => (cents * rate).round();
    final currencyOf = {
      for (final w in await _db.select(_db.wallets).get()) w.id: w.currency,
    };
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(_db.wallets)..where((t) => t.id.equals(id))).write(
        WalletsCompanion(
          currency: Value(newCurrency),
          initialBalanceCents: Value(convert(wallet.initialBalanceCents)),
          updatedAt: Value(now),
        ),
      );

      final txs =
          await (_db.select(_db.transactions)..where(
                (t) =>
                    t.deletedAt.isNull() &
                    (t.walletId.equals(id) | t.walletToId.equals(id)),
              ))
              .get();
      for (final tx in txs) {
        final update = tx.walletId == id
            ? _convertDebit(tx, newCurrency, currencyOf, convert)
            : _convertCredit(tx, newCurrency, currencyOf, convert);
        await (_db.update(_db.transactions)..where((t) => t.id.equals(tx.id)))
            .write(update.copyWith(updatedAt: Value(now)));
      }

      for (final budget in await (_db.select(
        _db.budgets,
      )..where((t) => t.deletedAt.isNull() & t.walletId.equals(id))).get()) {
        await (_db.update(
          _db.budgets,
        )..where((t) => t.id.equals(budget.id))).write(
          BudgetsCompanion(
            limitCents: Value(convert(budget.limitCents)),
            updatedAt: Value(now),
          ),
        );
      }

      for (final rule in await (_db.select(
        _db.recurringRules,
      )..where((t) => t.deletedAt.isNull() & t.walletId.equals(id))).get()) {
        await (_db.update(
          _db.recurringRules,
        )..where((t) => t.id.equals(rule.id))).write(
          RecurringRulesCompanion(
            amountCents: Value(convert(rule.amountCents)),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Movimento che parte dal portafoglio convertito: spesa, entrata o
  /// addebito di un trasferimento (tutti nella sua valuta).
  TransactionsCompanion _convertDebit(
    Transaction tx,
    String newCurrency,
    Map<String, String> currencyOf,
    int Function(int) convert,
  ) {
    // Inserito in origine proprio nella nuova valuta: si torna all'importo
    // digitato, senza arrotondamenti, e non serve più ricordarne la valuta.
    final typedInNewCurrency =
        tx.entryCurrency == newCurrency && tx.entryAmountCents != null;
    final entry = typedInNewCurrency
        ? const TransactionsCompanion(
            entryCurrency: Value(null),
            entryAmountCents: Value(null),
          )
        : const TransactionsCompanion();
    final debit = typedInNewCurrency
        ? tx.entryAmountCents!
        : convert(tx.amountCents);

    if (tx.type != TransactionType.transfer || tx.walletToId == null) {
      return entry.copyWith(amountCents: Value(debit));
    }
    // Trasferimento in uscita: l'accredito del destinatario non deve
    // cambiare. Se il destinatario ha già la nuova valuta, addebito e
    // accredito tornano a coincidere (l'accredito esplicito non serve più).
    final credit = tx.amountCentsTo ?? tx.amountCents;
    if (currencyOf[tx.walletToId] == newCurrency) {
      return entry.copyWith(
        amountCents: Value(credit),
        amountCentsTo: const Value(null),
      );
    }
    return entry.copyWith(
      amountCents: Value(debit),
      amountCentsTo: Value(credit),
    );
  }

  /// Trasferimento in arrivo sul portafoglio convertito: cambia solo
  /// l'accredito, l'addebito resta nella valuta di chi l'ha inviato.
  TransactionsCompanion _convertCredit(
    Transaction tx,
    String newCurrency,
    Map<String, String> currencyOf,
    int Function(int) convert,
  ) {
    if (currencyOf[tx.walletId] == newCurrency) {
      return const TransactionsCompanion(amountCentsTo: Value(null));
    }
    final credit = tx.amountCentsTo ?? tx.amountCents;
    return TransactionsCompanion(amountCentsTo: Value(convert(credit)));
  }
}
