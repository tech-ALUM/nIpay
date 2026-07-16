import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// Versione dello schema di export: da incrementare a ogni cambiamento
/// incompatibile del formato. v2: taxonomy per-portafoglio (walletId).
const kExportSchemaVersion = 2;

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

/// Export di un singolo portafoglio: il suo spazio completo (categorie, tag,
/// campi, budget, ricorrenze, dashboard) + le sue transazioni, inclusi i
/// trasferimenti in arrivo da altri portafogli.
Future<Map<String, dynamic>> exportWalletToJson(
  AppDatabase db,
  String walletId,
) async {
  final wallet = await (db.select(
    db.wallets,
  )..where((t) => t.id.equals(walletId))).getSingle();
  final txs =
      await (db.select(db.transactions)..where(
            (t) => t.walletId.equals(walletId) | t.walletToId.equals(walletId),
          ))
          .get();
  final txIds = txs.map((t) => t.id).toSet();

  final categories = await (db.select(
    db.categories,
  )..where((t) => t.walletId.equals(walletId))).get();
  final tags = await (db.select(
    db.tags,
  )..where((t) => t.walletId.equals(walletId))).get();
  final txTags = [
    for (final r in await db.select(db.transactionTags).get())
      if (txIds.contains(r.transactionId)) r,
  ];
  final defs = await (db.select(
    db.customFieldDefs,
  )..where((t) => t.walletId.equals(walletId))).get();
  final values = [
    for (final r in await db.select(db.customFieldValues).get())
      if (txIds.contains(r.transactionId)) r,
  ];
  final budgets = await (db.select(
    db.budgets,
  )..where((t) => t.walletId.equals(walletId))).get();
  final rules = await (db.select(
    db.recurringRules,
  )..where((t) => t.walletId.equals(walletId))).get();
  final attachments = [
    for (final r in await db.select(db.attachments).get())
      if (txIds.contains(r.transactionId)) r,
  ];
  final cards = await (db.select(
    db.dashboardCards,
  )..where((t) => t.walletId.equals(walletId))).get();

  return {
    'schemaVersion': kExportSchemaVersion,
    'app': 'nipay',
    'kind': 'wallet',
    'wallets': [wallet.toJson()],
    'categories': [for (final r in categories) r.toJson()],
    'transactions': [for (final r in txs) r.toJson()],
    'tags': [for (final r in tags) r.toJson()],
    'transactionTags': [for (final r in txTags) r.toJson()],
    'customFieldDefs': [for (final r in defs) r.toJson()],
    'customFieldValues': [for (final r in values) r.toJson()],
    'budgets': [for (final r in budgets) r.toJson()],
    'recurringRules': [for (final r in rules) r.toJson()],
    'attachments': [for (final r in attachments) r.toJson()],
    'dashboardCards': [for (final r in cards) r.toJson()],
  };
}

/// Import ADDITIVO di un portafoglio: rigenera tutti gli ID (così lo stesso
/// file si può importare più volte senza collisioni) e non tocca il resto.
/// Ritorna l'id del nuovo portafoglio.
Future<String> importWalletFromJson(
  AppDatabase db,
  Map<String, dynamic> json,
) async {
  if (json['app'] != 'nipay' ||
      json['schemaVersion'] != kExportSchemaVersion ||
      json['kind'] != 'wallet') {
    throw const FormatException('File portafoglio nIpay non valido');
  }

  const uuid = Uuid();
  final remap = <String, String>{};
  String fresh(String old) => remap.putIfAbsent(old, uuid.v4);

  List<Map<String, dynamic>> rows(String key) => [
    for (final r in (json[key] ?? const []) as List)
      Map<String, dynamic>.from(r as Map),
  ];

  // Pre-registra gli id di tutte le entità esportate, così i riferimenti
  // a entità FUORI dall'export (es. walletToId di un transfer) restano intatti.
  for (final key in [
    'wallets',
    'categories',
    'transactions',
    'tags',
    'customFieldDefs',
    'budgets',
    'recurringRules',
    'attachments',
    'dashboardCards',
  ]) {
    for (final r in rows(key)) {
      fresh(r['id'] as String);
    }
  }

  Map<String, dynamic> rewrite(Map<String, dynamic> r, List<String> refs) {
    for (final k in refs) {
      final v = r[k] as String?;
      if (v != null) r[k] = remap[v] ?? v;
    }
    return r;
  }

  final walletRow = rewrite(rows('wallets').single, ['id']);
  final newWalletId = walletRow['id'] as String;

  await db.transaction(() async {
    await db.batch((b) {
      b.insertAll(db.wallets, [Wallet.fromJson(walletRow)]);
      b.insertAll(db.categories, [
        for (final r in rows('categories'))
          Category.fromJson(rewrite(r, ['id', 'walletId', 'parentId'])),
      ]);
      b.insertAll(db.transactions, [
        for (final r in rows('transactions'))
          Transaction.fromJson(
            rewrite(r, ['id', 'walletId', 'walletToId', 'categoryId']),
          ),
      ]);
      b.insertAll(db.tags, [
        for (final r in rows('tags'))
          Tag.fromJson(rewrite(r, ['id', 'walletId'])),
      ]);
      b.insertAll(db.transactionTags, [
        for (final r in rows('transactionTags'))
          TransactionTag.fromJson(rewrite(r, ['transactionId', 'tagId'])),
      ]);
      b.insertAll(db.customFieldDefs, [
        for (final r in rows('customFieldDefs'))
          CustomFieldDef.fromJson(rewrite(r, ['id', 'walletId'])),
      ]);
      b.insertAll(db.customFieldValues, [
        for (final r in rows('customFieldValues'))
          CustomFieldValue.fromJson(rewrite(r, ['transactionId', 'fieldId'])),
      ]);
      b.insertAll(db.budgets, [
        for (final r in rows('budgets'))
          Budget.fromJson(rewrite(r, ['id', 'walletId', 'categoryId'])),
      ]);
      b.insertAll(db.recurringRules, [
        for (final r in rows('recurringRules'))
          RecurringRule.fromJson(rewrite(r, ['id', 'walletId', 'categoryId'])),
      ]);
      b.insertAll(db.attachments, [
        for (final r in rows('attachments'))
          Attachment.fromJson(rewrite(r, ['id', 'transactionId'])),
      ]);
      b.insertAll(db.dashboardCards, [
        for (final r in rows('dashboardCards'))
          DashboardCard.fromJson(rewrite(r, ['id', 'walletId'])),
      ]);
    });
  });

  return newWalletId;
}

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
