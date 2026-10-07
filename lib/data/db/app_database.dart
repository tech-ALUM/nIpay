import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    Tags,
    TransactionTags,
    CustomFieldDefs,
    CustomFieldValues,
    Budgets,
    RecurringRules,
    Attachments,
    DashboardCards,
    CostCenters,
    ExpenseReports,
    ExpenseReportEntries,
    SyncStates,
    SyncCursors,
    SyncOutbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 7;

  /// Tabelle sincronizzate con Supabase (nome SQL → espressione SQL della
  /// chiave della riga, con `{r}` al posto di NEW/alias). Le chiavi
  /// composte usano `|` come separatore: gli UUID non lo contengono.
  static const syncedTableKeys = <String, String>{
    'wallets': '{r}.id',
    'categories': '{r}.id',
    'tags': '{r}.id',
    'custom_field_defs': '{r}.id',
    'cost_centers': '{r}.id',
    'budgets': '{r}.id',
    'recurring_rules': '{r}.id',
    'dashboard_cards': '{r}.id',
    'transactions': '{r}.id',
    'expense_reports': '{r}.id',
    'transaction_tags': "{r}.transaction_id || '|' || {r}.tag_id",
    'custom_field_values': "{r}.transaction_id || '|' || {r}.field_id",
    'expense_report_entries': '{r}.transaction_id',
  };

  /// Trigger che mettono in [SyncOutbox] ogni riga inserita o modificata
  /// (SECURITY_AUDIT NIP-03): la sync invia esattamente le righe "sporche",
  /// non più quelle con `updatedAt` > watermark locale (che reinviava le
  /// righe appena scaricate e sovrascriveva modifiche più recenti).
  /// DELETE + INSERT: il nuovo `seq` AUTOINCREMENT è sempre maggiore, e non
  /// dipende dalla clausola di conflitto dell'istruzione che ha scatenato
  /// il trigger (un `INSERT OR IGNORE` esterno non può "congelare" la voce).
  Future<void> _createSyncTriggers() async {
    for (final MapEntry(key: table, value: keyExpr)
        in syncedTableKeys.entries) {
      final key = keyExpr.replaceAll('{r}', 'NEW');
      for (final (suffix, event) in [('ins', 'INSERT'), ('upd', 'UPDATE')]) {
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS sync_outbox_${table}_$suffix
          AFTER $event ON $table
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = '$table' AND row_key = $key;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('$table', $key);
          END
        ''');
      }
    }
  }

  /// v7: mette in coda le righe modificate dopo l'ultimo push (stessa
  /// regola del motore precedente, `updatedAt > lastPushedAt`), o tutte se
  /// il device non ha mai sincronizzato (first-sync da locale).
  Future<void> _backfillOutbox() async {
    final states = await select(syncStates).get();
    final cutoff = states.isEmpty
        ? null
        : states
              .map((s) => s.lastPushedAt)
              .reduce((a, b) => a.isBefore(b) ? a : b);
    for (final MapEntry(key: table, value: keyExpr)
        in syncedTableKeys.entries) {
      final key = keyExpr.replaceAll('{r}', table);
      final timeColumn = table == 'transaction_tags'
          ? 'created_at'
          : 'updated_at';
      await customStatement(
        'INSERT INTO sync_outbox (sync_table, row_key) '
        "SELECT '$table', $key FROM $table"
        '${cutoff == null ? '' : ' WHERE $timeColumn > ?'}',
        [if (cutoff != null) typeMapping.mapToSqlVariable(cutoff)],
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createSyncTriggers();
    },
    onUpgrade: (m, from, to) async {
      if (from < 6) {
        // v6: motore di sync (M-ACC6). Nessun backfill: chi aggiorna da
        // una versione precedente è per definizione senza account attivo
        // ancora sincronizzato (la sync è opt-in), quindi la tabella parte
        // vuota e la prima sync la popolerà al primo login.
        await m.createTable(syncStates);
      }
      if (from < 5) {
        // v5: multi-valuta. Default 'EUR' per i portafogli esistenti; le
        // nuove colonne su transactions restano NULL (= nessuna conversione,
        // comportamento identico a prima).
        await m.addColumn(wallets, wallets.currency);
        await m.addColumn(transactions, transactions.entryCurrency);
        await m.addColumn(transactions, transactions.entryAmountCents);
        await m.addColumn(transactions, transactions.amountCentsTo);
      }
      if (from < 4) {
        // v4: ordine portafogli (drag-to-reorder in home). Backfill in
        // base a createdAt, così l'ordine esistente non cambia.
        await m.addColumn(wallets, wallets.position);
        await customStatement('''
          UPDATE wallets SET position = (
            SELECT COUNT(*) FROM wallets w2 WHERE w2.created_at < wallets.created_at
          )
        ''');
      }
      if (from < 3) {
        // v3: nota spese.
        await m.createTable(costCenters);
        await m.createTable(expenseReports);
        await m.createTable(expenseReportEntries);
        await m.addColumn(customFieldDefs, customFieldDefs.expenseReportOnly);
      }
      if (from < 2) {
        // v2: taxonomy per-portafoglio. Le righe esistenti (globali)
        // vengono assegnate al portafoglio più vecchio.
        await m.addColumn(categories, categories.walletId);
        await m.addColumn(tags, tags.walletId);
        await m.addColumn(customFieldDefs, customFieldDefs.walletId);
        await m.addColumn(budgets, budgets.walletId);
        await m.addColumn(dashboardCards, dashboardCards.walletId);
        const backfill = "(SELECT id FROM wallets ORDER BY created_at LIMIT 1)";
        for (final table in [
          'categories',
          'tags',
          'custom_field_defs',
          'budgets',
          'dashboard_cards',
        ]) {
          await customStatement(
            'UPDATE $table SET wallet_id = $backfill WHERE wallet_id IS NULL',
          );
        }
      }
      if (from < 7) {
        // v7: sync robusta (SECURITY_AUDIT NIP-01..04, NIP-15). In fondo,
        // dopo i passi precedenti: createTable dei passi vecchi usa già lo
        // schema corrente, da qui i controlli su `from` per le colonne.
        if (from >= 6) {
          await m.addColumn(syncStates, syncStates.userEmail);
          await m.addColumn(syncStates, syncStates.lastSuccessAt);
          await m.addColumn(syncStates, syncStates.lastError);
          await m.addColumn(syncStates, syncStates.pendingIssues);
        }
        if (from >= 3) {
          await m.addColumn(
            expenseReportEntries,
            expenseReportEntries.deletedAt,
          );
        }
        // Colonna NOT NULL senza default SQL: si ricrea la tabella, con
        // updatedAt inizializzato a createdAt.
        await m.alterTable(
          TableMigration(
            transactionTags,
            newColumns: [transactionTags.updatedAt, transactionTags.deletedAt],
            columnTransformer: {
              transactionTags.updatedAt: transactionTags.createdAt,
            },
          ),
        );
        // Via il vincolo UNIQUE(category_id) globale (anche sui budget
        // cancellati): resta un indice unico solo sui budget vivi.
        await m.alterTable(TableMigration(budgets));
        await m.create(budgetsLiveCategory);
        await m.createTable(syncCursors);
        await m.createTable(syncOutbox);
        await _backfillOutbox();
        await _createSyncTriggers();
      }
    },
  );
}
