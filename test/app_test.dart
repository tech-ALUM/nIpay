import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nipay/app.dart';
import 'package:nipay/core/money.dart';
import 'package:nipay/core/providers.dart';
import 'package:nipay/data/repositories/custom_field_repository.dart'
    show CustomFieldType;
import 'package:shared_preferences/shared_preferences.dart';

import 'data/exchange_rate_service_test.dart' show FakeExchangeRateService;

Future<Widget> _app({List<Override> extraOverrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      databaseExecutorProvider.overrideWithValue(NativeDatabase.memory()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...extraOverrides,
    ],
    child: const NipayApp(),
  );
}

/// Smonta l'albero dentro il corpo del test: lo StreamQueryStore di Drift
/// schedula un Timer(0) alla dispose, che va consumato con un pump extra.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  // Durata > 0: fa avanzare il clock fake e consuma il Timer(0) di Drift.
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _createWallet(
  WidgetTester tester, {
  String name = 'Conto',
  String balance = '1000',
}) async {
  await tester.tap(find.byKey(const Key('addWalletButton')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('walletNameField')), name);
  await tester.enterText(find.byKey(const Key('walletBalanceField')), balance);
  await tester.ensureVisible(find.byKey(const Key('walletSaveButton')));
  await tester.tap(find.byKey(const Key('walletSaveButton')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('home shows empty state, creating a wallet shows its balance', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    // Stato vuoto (EN: locale di default nei test).
    expect(
      find.text('Create your first wallet to get started.'),
      findsOneWidget,
    );

    await _createWallet(tester);

    expect(find.text('Conto'), findsOneWidget);
    expect(find.text(formatCents(100000)), findsWidgets);

    await _unmount(tester);
  });

  testWidgets('creating a wallet without a name shows an error, not a crash', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addWalletButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('walletBalanceField')), '1000');
    await tester.ensureVisible(find.byKey(const Key('walletSaveButton')));
    await tester.tap(find.byKey(const Key('walletSaveButton')));
    await tester.pumpAndSettle();

    // Il foglio resta aperto con l'errore, nessun portafoglio creato.
    expect(find.text('Enter a wallet name'), findsOneWidget);
    expect(find.byKey(const Key('walletNameField')), findsOneWidget);
    expect(
      find.text('Create your first wallet to get started.'),
      findsOneWidget,
    );

    await _unmount(tester);
  });

  testWidgets('adding an expense updates balance and recent list', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _createWallet(tester);

    // Nuova spesa dal FAB.
    await tester.tap(find.byKey(const Key('addTransactionFab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '42,50');
    await tester.enterText(
      find.byKey(const Key('descriptionField')),
      'Esselunga',
    );
    await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
    await tester.tap(find.byKey(const Key('txSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Esselunga'), findsOneWidget);
    expect(find.text(formatCents(-4250)), findsOneWidget);
    expect(find.text(formatCents(95750)), findsWidgets);

    await _unmount(tester);
  });

  testWidgets(
    'currency conversion rounding to zero is blocked, not saved silently',
    (tester) async {
      // Tasso volutamente estremo: 0,01 nella valuta di inserimento diventa
      // 0,00 nel portafoglio (1 centesimo * 0.001 = 0.001, arrotonda a 0).
      await tester.pumpWidget(
        await _app(
          extraOverrides: [
            exchangeRateServiceProvider.overrideWithValue(
              FakeExchangeRateService({('USD', 'EUR'): 0.001}),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _createWallet(tester); // EUR di default

      await tester.tap(find.byKey(const Key('addTransactionFab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('amountField')), '0,01');

      await tester.tap(find.byKey(const Key('transactionCurrencyDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD \$').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
      await tester.tap(find.byKey(const Key('txSaveButton')));
      await tester.pumpAndSettle();

      // Bloccato con errore, non salvato come transazione fantasma da 0€.
      expect(find.text('Invalid amount'), findsOneWidget);
      expect(
        find.text('Create your first wallet to get started.'),
        findsNothing,
      );
      expect(find.text('No transactions yet. Tap + to add the first one.'), findsOneWidget);

      await _unmount(tester);
    },
  );

  testWidgets(
    'changing a wallet currency via Save rescales only the initial balance',
    (tester) async {
      await tester.pumpWidget(
        await _app(
          extraOverrides: [
            exchangeRateServiceProvider.overrideWithValue(
              FakeExchangeRateService({('EUR', 'USD'): 1.1}),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _createWallet(tester); // EUR, saldo 1000,00

      // Il bottone edit sulla card apre il foglio azioni (il long-press,
      // ora, serve solo a trascinare per riordinare).
      await tester.tap(find.byKey(const Key('walletEditButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('walletActionsCurrencyDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD \$').last);
      await tester.pumpAndSettle();

      // "Salva" è l'unica conferma: rinomina + cambio valuta insieme.
      await tester.tap(find.byKey(const Key('walletActionsSaveButton')));
      await tester.pumpAndSettle();

      // Saldo riscalato al tasso 1.1: 1000,00 € → 1.100,00 $.
      expect(
        find.text(formatCents(110000, currency: 'USD', symbolOnly: true)),
        findsWidgets,
      );

      await _unmount(tester);
    },
  );

  testWidgets('creating a tag inline attaches it and the tag filter finds it', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _createWallet(tester);

    // Spesa con tag creato al volo dal sheet.
    await tester.tap(find.byKey(const Key('addTransactionFab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '10');
    await tester.enterText(
      find.byKey(const Key('descriptionField')),
      'Bolletta',
    );
    await tester.ensureVisible(find.byKey(const Key('addTagChip')));
    await tester.tap(find.byKey(const Key('addTagChip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('newTagField')), 'casa');
    await tester.tap(find.byKey(const Key('tagSaveButton')));
    await tester.pumpAndSettle();
    expect(find.text('#casa'), findsOneWidget); // chip selezionata nel sheet
    await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
    await tester.tap(find.byKey(const Key('txSaveButton')));
    await tester.pumpAndSettle();

    // Tab Transazioni: filtro per tag.
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All tags'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#casa').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Bolletta'), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets(
    'editing a transaction shows its existing tags selected, and '
    'deselecting one actually removes it',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await _createWallet(tester);

      await tester.tap(find.byKey(const Key('addTransactionFab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('amountField')), '10');
      await tester.enterText(
        find.byKey(const Key('descriptionField')),
        'Bolletta',
      );
      await tester.ensureVisible(find.byKey(const Key('addTagChip')));
      await tester.tap(find.byKey(const Key('addTagChip')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('newTagField')), 'casa');
      await tester.tap(find.byKey(const Key('tagSaveButton')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
      await tester.tap(find.byKey(const Key('txSaveButton')));
      await tester.pumpAndSettle();

      // Riapri in modifica: il tag già assegnato deve risultare selezionato,
      // non deselezionato come prima del fix.
      await tester.tap(find.text('Bolletta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editTransactionButton')));
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '#casa'),
      );
      expect(chip.selected, isTrue);

      // Deseleziona e salva: il tag deve sparire davvero, non solo dalla UI.
      await tester.tap(find.text('#casa'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
      await tester.tap(find.byKey(const Key('txSaveButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All tags'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#casa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Bolletta'), findsNothing);

      await _unmount(tester);
    },
  );

  testWidgets(
    'editing a transaction shows its existing custom field value, not blank',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await _createWallet(tester);

      // Nessuna UI per definire un campo custom in questo flusso: lo creo
      // direttamente via repository, come farebbe la schermata dedicata.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final walletId = container.read(activeWalletProvider)!.id;
      await container
          .read(customFieldRepositoryProvider)
          .define(
            walletId: walletId,
            name: 'Riferimento',
            type: CustomFieldType.text,
          );
      container.invalidate(customFieldDefsProvider);

      await tester.tap(find.byKey(const Key('addTransactionFab')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('amountField')), '10');
      await tester.enterText(
        find.byKey(const Key('descriptionField')),
        'Bolletta',
      );
      // La key del campo è per-id (non prevedibile qui): lo trovo dal suo
      // label, come farebbe un utente.
      final field = find.ancestor(
        of: find.text('Riferimento'),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, 'ABC123');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('txSaveButton')));
      await tester.pumpAndSettle();

      // Riapri in modifica: il valore già impostato deve essere precompilato.
      await tester.ensureVisible(find.text('Bolletta'));
      await tester.tap(find.text('Bolletta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editTransactionButton')));
      await tester.pumpAndSettle();

      final reopenedField = find.ancestor(
        of: find.text('Riferimento'),
        matching: find.byType(TextField),
      );
      final controller = tester.widget<TextField>(reopenedField).controller;
      expect(controller?.text, 'ABC123');

      // Svuota il campo e salva: il vecchio valore deve sparire davvero dal
      // DB, non solo restare invisibile nella UI.
      await tester.enterText(reopenedField, '');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('txSaveButton')));
      await tester.pumpAndSettle();

      final tx = (await container
              .read(recentTransactionsProvider.future))
          .single;
      final storedValues = await container
          .read(customFieldRepositoryProvider)
          .valuesOf(tx.id);
      expect(storedValues.single.value, isEmpty);

      await _unmount(tester);
    },
  );

  testWidgets('budget shows in home and warns when nearly exhausted', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _createWallet(tester);

    // Crea budget 100€ sulla categoria seed "Spesa" da Altro → Budget.
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('budgetCategoryDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🛒 Spesa').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budgetLimitField')), '100');
    await tester.tap(find.byKey(const Key('budgetSaveButton')));
    await tester.pumpAndSettle();
    // Il manager mostra subito la barra appena creato.
    expect(
      find.text('🛒 Spesa'),
      findsOneWidget,
      reason: 'budget non creato nel manager',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // La home mostra la barra del budget.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('🛒 Spesa'), findsOneWidget);

    // Spesa da 90€ nella categoria → avviso 90%.
    await tester.tap(find.byKey(const Key('addTransactionFab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '90');
    await tester.ensureVisible(find.text('🛒 Spesa').last);
    await tester.tap(find.text('🛒 Spesa').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
    await tester.tap(find.byKey(const Key('txSaveButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('90%'), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets('stats dashboard: adding a cashflow card shows KPIs', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _createWallet(tester);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(
      find.text('Compose your dashboard: add your first card.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('addCardButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash flow'));
    await tester.pumpAndSettle();

    expect(find.text('Net'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets('wallets are separate spaces: switching changes transactions', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    // Spazio A con una spesa.
    await _createWallet(tester, name: 'Personale', balance: '500');
    await tester.tap(find.byKey(const Key('addTransactionFab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '20');
    await tester.enterText(find.byKey(const Key('descriptionField')), 'Caffè');
    await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
    await tester.tap(find.byKey(const Key('txSaveButton')));
    await tester.pumpAndSettle();
    expect(find.text('Caffè'), findsOneWidget);

    // Spazio B: appena creato diventa attivo, vuoto e col suo saldo.
    await _createWallet(tester, name: 'ALUM', balance: '2000');
    expect(find.text('Caffè'), findsNothing);
    expect(find.text(formatCents(200000)), findsWidgets);

    // Tap sulla card di A: torna lo spazio A con la sua spesa.
    await tester.tap(find.text('Personale'));
    await tester.pumpAndSettle();
    expect(find.text('Caffè'), findsOneWidget);
    expect(find.text(formatCents(48000)), findsWidgets); // 500 − 20

    await _unmount(tester);
  });

  testWidgets('expense report: flagged expense shows in pending and screen', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _createWallet(tester);

    // Spesa flaggata nota spese.
    await tester.tap(find.byKey(const Key('addTransactionFab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '55');
    await tester.enterText(
      find.byKey(const Key('descriptionField')),
      'Hotel trasferta',
    );
    await tester.ensureVisible(find.byKey(const Key('expenseReportSwitch')));
    await tester.tap(find.byKey(const Key('expenseReportSwitch')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
    await tester.tap(find.byKey(const Key('txSaveButton')));
    await tester.pumpAndSettle();

    // Card in home col totale da rimborsare.
    expect(find.byKey(const Key('expenseReportCard')), findsOneWidget);
    expect(find.text(formatCents(5500)), findsWidgets);

    // Schermata nota spese: la spesa è nel periodo corrente.
    await tester.tap(find.byKey(const Key('expenseReportCard')));
    await tester.pumpAndSettle();
    expect(find.text('Hotel trasferta'), findsOneWidget);
    expect(find.text('Flagged expenses: 1'), findsOneWidget);

    await _unmount(tester);
  });
}
