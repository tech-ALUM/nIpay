import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nipay/core/providers.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/services/shared_expense_service.dart';
import 'package:nipay/features/split/split_section.dart';
import 'package:nipay/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../data/exchange_rate_service_test.dart'
    show FakeExchangeRateService;
import 'fake_shared_expense_service.dart';

User _user() => User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'me@test.local',
  createdAt: DateTime(2026).toIso8601String(),
);

SharedExpense _dinner({
  String paidBy = 'bea',
  String currency = 'EUR',
  bool registered = false,
}) => SharedExpense(
  id: 'se-1',
  createdBy: paidBy,
  paidBy: paidBy,
  payerDisplayName: paidBy == 'me' ? 'Io' : 'Bea',
  description: 'Cena',
  totalCents: 6000,
  currency: currency,
  spentOn: DateTime(2026, 10, 20),
  myShareCents: 2000,
  myShareRegistered: registered,
  locked: false,
  shares: const [
    SharedExpenseShare(
      userId: 'me',
      displayName: 'Io',
      shareCents: 2000,
      registered: false,
    ),
    SharedExpenseShare(
      userId: 'bea',
      displayName: 'Bea',
      shareCents: 2000,
      registered: true,
    ),
    SharedExpenseShare(
      userId: 'carlo',
      displayName: 'Carlo',
      shareCents: 2000,
      registered: false,
    ),
  ],
);

Settlement _settlement({
  required SettlementDirection direction,
  required SettlementStatus status,
  bool registered = false,
}) => Settlement(
  id: 'st-1',
  direction: direction,
  userId: 'bea',
  displayName: 'Bea',
  amountCents: 1500,
  currency: 'EUR',
  status: status,
  createdAt: DateTime(2026, 10, 22),
  myRegistered: registered,
);

class _Harness {
  final shared = FakeSharedExpenseService();
  late ProviderContainer container;
  late String walletId;

  AppDatabase get db => container.read(databaseProvider);

  Future<void> pump(WidgetTester tester) async {
    final view = tester.view;
    view.physicalSize = Size(
      800 * view.devicePixelRatio,
      2000 * view.devicePixelRatio,
    );
    addTearDown(view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseExecutorProvider.overrideWithValue(NativeDatabase.memory()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          authStateProvider.overrideWith((ref) => Stream.value(_user())),
          sharedExpenseServiceProvider.overrideWithValue(shared),
          exchangeRateServiceProvider.overrideWithValue(
            FakeExchangeRateService({('USD', 'EUR'): 0.5}),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: SplitSection()),
          ),
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(SplitSection)),
    );
    walletId = (await tester.runAsync(
      () => container
          .read(walletRepositoryProvider)
          .create(
            name: 'Conto',
            colorHex: '#0E7C86',
            initialBalanceCents: 10000,
          ),
    ))!;
    await tester.pumpAndSettle();
  }

  Future<List<Transaction>> live(WidgetTester tester) async =>
      (await tester.runAsync(
        () => (db.select(
          db.transactions,
        )..where((t) => t.deletedAt.isNull())).get(),
      ))!;

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('nothing shared: the section is hidden', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.text('Shared expenses'), findsNothing);
    await h.unmount(tester);
  });

  testWidgets('balances say who owes whom; only debts can be settled', (
    tester,
  ) async {
    final h = _Harness();
    h.shared.balanceRows.addAll(const [
      FriendBalance(
        userId: 'bea',
        displayName: 'Bea',
        currency: 'EUR',
        balanceCents: -1500,
        isFriend: true,
      ),
      FriendBalance(
        userId: 'carlo',
        displayName: 'Carlo',
        currency: 'USD',
        balanceCents: 2000,
        isFriend: false,
      ),
      FriendBalance(
        userId: null,
        displayName: null,
        currency: 'EUR',
        balanceCents: -300,
        isFriend: false,
      ),
    ]);
    await h.pump(tester);

    expect(find.textContaining('You owe'), findsNWidgets(2));
    expect(find.textContaining('Owes you'), findsOneWidget);
    expect(find.text('Deleted user'), findsOneWidget);
    expect(find.byKey(const ValueKey('settle_bea_EUR')), findsOneWidget);
    expect(find.byKey(const ValueKey('settle_carlo_USD')), findsNothing);
    expect(find.byKey(const ValueKey('settle_null_EUR')), findsNothing);
    await h.unmount(tester);
  });

  testWidgets('registering my share creates the share and the debt, then '
      'tells the server', (tester) async {
    final h = _Harness();
    h.shared.expenses.add(_dinner());
    await h.pump(tester);

    await tester.tap(find.byKey(const ValueKey('registerShare_se-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registerConfirmButton')));
    await tester.pumpAndSettle();

    final txs = await h.live(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'expense': 2000, 'friendIn': 2000},
    );
    expect(txs.every((t) => t.sharedExpenseId == 'se-1'), isTrue);
    expect(h.shared.calls, contains('registerMyShare:se-1'));
    expect(find.text('Added to your wallet.'), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('if the server refuses the registration, the movements go away', (
    tester,
  ) async {
    final h = _Harness();
    h.shared.expenses.add(_dinner());
    await h.pump(tester);
    h.shared.failNext = SharedExpenseErrorCode.notFound;

    await tester.tap(find.byKey(const ValueKey('registerShare_se-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registerConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.text('This no longer exists.'), findsOneWidget);
    expect(await h.live(tester), isEmpty);
    await h.unmount(tester);
  });

  testWidgets('a share in another currency is converted for the wallet', (
    tester,
  ) async {
    final h = _Harness();
    h.shared.expenses.add(_dinner(paidBy: 'me', currency: 'USD'));
    await h.pump(tester);

    await tester.tap(find.byKey(const ValueKey('registerShare_se-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('registerConvertedPreview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('registerConfirmButton')));
    await tester.pumpAndSettle();

    final txs = await h.live(tester);
    // 60 USD → 30 €: quota 10 €, anticipo per gli altri 20 €.
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'expense': 1000, 'friendOut': 2000},
    );
    expect(txs.every((t) => t.entryCurrency == 'USD'), isTrue);
    await h.unmount(tester);
  });

  testWidgets('settling proposes the whole debt and refuses more', (
    tester,
  ) async {
    final h = _Harness();
    h.shared.balanceRows.add(
      const FriendBalance(
        userId: 'bea',
        displayName: 'Bea',
        currency: 'EUR',
        balanceCents: -1500,
        isFriend: true,
      ),
    );
    await h.pump(tester);

    await tester.tap(find.byKey(const ValueKey('settle_bea_EUR')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('settleAmountField')),
    );
    expect(field.controller!.text, '15,00');

    await tester.enterText(find.byKey(const Key('settleAmountField')), '20');
    await tester.tap(find.byKey(const Key('settleSendButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('At most'), findsOneWidget);
    expect(h.shared.calls, isEmpty);

    await tester.enterText(find.byKey(const Key('settleAmountField')), '10');
    await tester.tap(find.byKey(const Key('settleSendButton')));
    await tester.pumpAndSettle();
    expect(h.shared.calls, ['recordSettlement:bea:1000:EUR']);
    expect(find.text('Recorded. It counts once Bea confirms.'), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('a received pay-back is confirmed and then added to a wallet', (
    tester,
  ) async {
    final h = _Harness();
    h.shared.settlementRows.add(
      _settlement(
        direction: SettlementDirection.incoming,
        status: SettlementStatus.pending,
      ),
    );
    await h.pump(tester);

    await tester.tap(find.byKey(const ValueKey('settlementReceived_st-1')));
    await tester.pumpAndSettle();
    expect(h.shared.calls, contains('respondSettlement:st-1:true'));
    await tester.tap(find.byKey(const Key('registerConfirmButton')));
    await tester.pumpAndSettle();

    final txs = await h.live(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'friendIn': 1500},
    );
    expect(h.shared.calls, contains('registerMySettlement:st-1'));
    await h.unmount(tester);
  });

  testWidgets('"not received" asks first, then declines', (tester) async {
    final h = _Harness();
    h.shared.settlementRows.add(
      _settlement(
        direction: SettlementDirection.incoming,
        status: SettlementStatus.pending,
      ),
    );
    await h.pump(tester);

    await tester.tap(find.byKey(const ValueKey('settlementNotReceived_st-1')));
    await tester.pumpAndSettle();
    expect(h.shared.calls, isEmpty);
    await tester.tap(find.byKey(const Key('settlementDeclineConfirm')));
    await tester.pumpAndSettle();
    expect(h.shared.calls, ['respondSettlement:st-1:false']);
    expect(await h.live(tester), isEmpty);
    await h.unmount(tester);
  });

  testWidgets('my pending pay-back can be cancelled; once confirmed I add it '
      'to a wallet', (tester) async {
    final h = _Harness();
    h.shared.settlementRows.add(
      _settlement(
        direction: SettlementDirection.outgoing,
        status: SettlementStatus.pending,
      ),
    );
    await h.pump(tester);
    expect(find.textContaining('Waiting for Bea'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('settlementCancel_st-1')));
    await tester.pumpAndSettle();
    expect(h.shared.calls, ['cancelSettlement:st-1']);
    await h.unmount(tester);

    final h2 = _Harness();
    h2.shared.settlementRows.add(
      _settlement(
        direction: SettlementDirection.outgoing,
        status: SettlementStatus.confirmed,
      ),
    );
    await h2.pump(tester);
    await tester.tap(find.byKey(const ValueKey('registerSettlement_st-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('registerConfirmButton')));
    await tester.pumpAndSettle();
    final txs = await h2.live(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'friendOut': 1500},
    );
    expect(h2.shared.calls, contains('registerMySettlement:st-1'));
    await h2.unmount(tester);
  });

  testWidgets('a shared expense opens with its shares', (tester) async {
    final h = _Harness();
    h.shared.expenses.add(_dinner(registered: true));
    await h.pump(tester);

    await tester.tap(find.byKey(const ValueKey('sharedExpense_se-1')));
    await tester.pumpAndSettle();
    expect(find.text('Carlo'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    await h.unmount(tester);
  });
}
