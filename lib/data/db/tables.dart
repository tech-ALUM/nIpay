import 'dart:convert';

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

enum CustomFieldType { text, number, choice, date }

/// JsonTypeConverter2: nel JSON di export la lista resta la stringa SQL,
/// così il round-trip export→import non dipende dal ValueSerializer.
class StringListConverter extends TypeConverter<List<String>, String>
    with JsonTypeConverter2<List<String>, String, String> {
  const StringListConverter();

  @override
  List<String> fromJson(String json) => fromSql(json);

  @override
  String toJson(List<String> value) => toSql(value);

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

class Tags extends Table with SyncColumns {
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  TextColumn get name => text()();
}

/// Join N:M transazione↔tag. PK composta, niente riga duplicata.
class TransactionTags extends Table {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

class CustomFieldDefs extends Table with SyncColumns {
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  TextColumn get name => text()();
  TextColumn get type => textEnum<CustomFieldType>()();

  /// Se true il campo compare solo quando la spesa è flaggata "nota spese".
  BoolColumn get expenseReportOnly =>
      boolean().withDefault(const Constant(false))();

  /// Solo per type=choice: opzioni ammesse (JSON).
  TextColumn get options =>
      text().map(const StringListConverter()).nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Un valore per (transazione, campo): setValue sovrascrive.
class CustomFieldValues extends Table {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get fieldId => text().references(CustomFieldDefs, #id)();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {transactionId, fieldId};
}

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

  /// Valuta scelta dall'utente in inserimento, se diversa da quella del
  /// portafoglio; null = nessuna conversione, [amountCents] è come digitato.
  TextColumn get entryCurrency => text().nullable()();

  /// Importo come digitato in [entryCurrency], prima della conversione.
  IntColumn get entryAmountCents => integer().nullable()();

  /// Solo trasferimenti cross-valuta: importo accreditato a [walletToId]
  /// nella SUA valuta, quando diversa da quella di [walletId]. Se null, il
  /// credito usa [amountCents] invariato (stessa valuta su entrambi i lati).
  IntColumn get amountCentsTo => integer().nullable()();
}

/// A cosa si applica una categoria.
enum CategoryKind { expense, income, both }

class Categories extends Table with SyncColumns {
  /// Spazio di appartenenza: ogni portafoglio ha la sua taxonomy.
  /// Nullable solo per la migrazione v1→v2; il codice lo valorizza sempre.
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get colorHex => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

/// Tetto di spesa mensile per categoria (un budget per categoria).
class Budgets extends Table with SyncColumns {
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get limitCents => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {categoryId},
  ];
}

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// Template di transazione che si ripete; [nextRunAt] è la prossima occorrenza
/// da generare (catch-up all'apertura dell'app).
class RecurringRules extends Table with SyncColumns {
  TextColumn get walletId => text().references(Wallets, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get amountCents => integer()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get frequency => textEnum<RecurrenceFrequency>()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get nextRunAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
}

/// File (es. foto scontrino) salvato nella dir dell'app, path relativo.
class Attachments extends Table with SyncColumns {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get relativePath => text()();
  TextColumn get mimeType => text()();
}

/// Card della dashboard statistiche: tipo, posizione e config (JSON).
class DashboardCards extends Table with SyncColumns {
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  TextColumn get type => text()();
  IntColumn get position => integer()();
  TextColumn get configJson => text().withDefault(const Constant('{}'))();
}

/// Centro di costo per la nota spese (per portafoglio).
class CostCenters extends Table with SyncColumns {
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  TextColumn get name => text()();
}

enum ExpenseReportStatus { draft, sent, reimbursed }

/// Nota spese persistita: periodo + ciclo di vita bozza→inviata→rimborsata.
class ExpenseReports extends Table with SyncColumns {
  TextColumn get walletId => text().nullable().references(Wallets, #id)();
  TextColumn get name => text()();
  DateTimeColumn get dateFrom => dateTime()();
  DateTimeColumn get dateTo => dateTime()();
  TextColumn get status => textEnum<ExpenseReportStatus>()();

  /// Entrata di rimborso collegata (quando rimborsata).
  TextColumn get reimburseTxId =>
      text().nullable().references(Transactions, #id)();
}

/// Dati nota-spese di una transazione: la presenza della riga = spesa
/// flaggata "nota spese". PK = transactionId (una riga per spesa).
@DataClassName('ExpenseReportEntry')
class ExpenseReportEntries extends Table {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get costCenterId =>
      text().nullable().references(CostCenters, #id)();
  BoolColumn get reimbursable => boolean().withDefault(const Constant(true))();
  BoolColumn get eInvoice => boolean().withDefault(const Constant(false))();
  TextColumn get reportId =>
      text().nullable().references(ExpenseReports, #id)();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {transactionId};
}

class Wallets extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get colorHex => text()();
  TextColumn get icon => text().withDefault(const Constant('wallet'))();

  /// Importi sempre in centesimi (int).
  IntColumn get initialBalanceCents =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Ordine di visualizzazione in home (drag-to-reorder).
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Codice ISO 4217 (es. "EUR", "USD"), fisso alla creazione. Ogni importo
  /// del portafoglio (saldo, transazioni) è in questa valuta.
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
}

/// Stato della sync (M-ACC6): una riga per utente loggato su questo device
/// (in pratica sempre una sola, dato che l'app supporta un solo account
/// attivo alla volta). Non c'è bisogno di una tabella di tombstone
/// separata: `deletedAt`, già presente su ogni tabella, si propaga come
/// una riga normale.
///
/// Due watermark separati invece di uno solo, per evitare bug di
/// clock-skew: [lastPushedAt] è nel dominio dell'orologio LOCALE (i dati
/// locali hanno `updatedAt` scritto dal client, quindi confrontarlo con
/// un watermark scritto dallo stesso client è sempre coerente);
/// [lastPulledAt] è nel dominio dell'orologio SERVER (i dati remoti hanno
/// `updated_at` assegnato da un trigger Postgres, M-ACC1 — il watermark va
/// aggiornato al massimo valore server osservato, mai al clock locale).
class SyncStates extends Table {
  TextColumn get userId => text()();
  DateTimeColumn get lastPushedAt => dateTime()();
  DateTimeColumn get lastPulledAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
