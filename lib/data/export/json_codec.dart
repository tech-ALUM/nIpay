import '../db/app_database.dart';

/// Versione dello schema di export: da incrementare a ogni cambiamento
/// incompatibile del formato.
const kExportSchemaVersion = 1;

/// Serializza l'intero DB in una mappa JSON-encodable (formato canonico).
Future<Map<String, dynamic>> exportToJson(AppDatabase db) async => {
  'schemaVersion': kExportSchemaVersion,
  'app': 'nipay',
  'wallets': [for (final r in await db.select(db.wallets).get()) r.toJson()],
  'categories': [
    for (final r in await db.select(db.categories).get()) r.toJson(),
  ],
  'transactions': [
    for (final r in await db.select(db.transactions).get()) r.toJson(),
  ],
  'tags': [for (final r in await db.select(db.tags).get()) r.toJson()],
  'transactionTags': [
    for (final r in await db.select(db.transactionTags).get()) r.toJson(),
  ],
  'customFieldDefs': [
    for (final r in await db.select(db.customFieldDefs).get()) r.toJson(),
  ],
  'customFieldValues': [
    for (final r in await db.select(db.customFieldValues).get()) r.toJson(),
  ],
  'budgets': [for (final r in await db.select(db.budgets).get()) r.toJson()],
  'recurringRules': [
    for (final r in await db.select(db.recurringRules).get()) r.toJson(),
  ],
  'attachments': [
    for (final r in await db.select(db.attachments).get()) r.toJson(),
  ],
  'dashboardCards': [
    for (final r in await db.select(db.dashboardCards).get()) r.toJson(),
  ],
};

/// Restore completo: azzera il DB e reinserisce tutto dal JSON.
/// Lancia [FormatException] se il file non è un export nIpay compatibile.
Future<void> importFromJson(AppDatabase db, Map<String, dynamic> json) async {
  if (json['app'] != 'nipay' || json['schemaVersion'] != kExportSchemaVersion) {
    throw const FormatException('File di backup nIpay non valido');
  }

  List<Map<String, dynamic>> rows(String key) =>
      ((json[key] ?? const []) as List).cast<Map<String, dynamic>>();

  await db.transaction(() async {
    // Svuota in ordine figli → genitori (vincoli FK).
    await db.delete(db.dashboardCards).go();
    await db.delete(db.attachments).go();
    await db.delete(db.recurringRules).go();
    await db.delete(db.budgets).go();
    await db.delete(db.customFieldValues).go();
    await db.delete(db.customFieldDefs).go();
    await db.delete(db.transactionTags).go();
    await db.delete(db.tags).go();
    await db.delete(db.transactions).go();
    await db.delete(db.categories).go();
    await db.delete(db.wallets).go();

    await db.batch((b) {
      b.insertAll(db.wallets, rows('wallets').map(Wallet.fromJson));
      b.insertAll(db.categories, rows('categories').map(Category.fromJson));
      b.insertAll(
        db.transactions,
        rows('transactions').map(Transaction.fromJson),
      );
      b.insertAll(db.tags, rows('tags').map(Tag.fromJson));
      b.insertAll(
        db.transactionTags,
        rows('transactionTags').map(TransactionTag.fromJson),
      );
      b.insertAll(
        db.customFieldDefs,
        rows('customFieldDefs').map(CustomFieldDef.fromJson),
      );
      b.insertAll(
        db.customFieldValues,
        rows('customFieldValues').map(CustomFieldValue.fromJson),
      );
      b.insertAll(db.budgets, rows('budgets').map(Budget.fromJson));
      b.insertAll(
        db.recurringRules,
        rows('recurringRules').map(RecurringRule.fromJson),
      );
      b.insertAll(db.attachments, rows('attachments').map(Attachment.fromJson));
      b.insertAll(
        db.dashboardCards,
        rows('dashboardCards').map(DashboardCard.fromJson),
      );
    });
  });
}
