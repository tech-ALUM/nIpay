import 'package:drift/drift.dart';

/// Colonne comuni a tutte le tabelle: id UUID + timestamp sync-ready.
/// Nessuna cancellazione fisica: si usa sempre [deletedAt] (soft-delete).
mixin SyncColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

enum TransactionType { expense, income, transfer }

class Transactions extends Table with SyncColumns {
  TextColumn get type => textEnum<TransactionType>()();

  /// Sempre positivo, in centesimi; il segno lo dà [type].
  IntColumn get amountCents => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get walletId => text().references(Wallets, #id)();

  /// Solo per i trasferimenti: portafoglio di destinazione.
  TextColumn get walletToId => text().nullable().references(Wallets, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();
}

/// A cosa si applica una categoria.
enum CategoryKind { expense, income, both }

class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get colorHex => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Wallets extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get colorHex => text()();
  TextColumn get icon => text().withDefault(const Constant('wallet'))();

  /// Importi sempre in centesimi (int).
  IntColumn get initialBalanceCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
