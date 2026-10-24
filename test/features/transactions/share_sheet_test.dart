import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nipay/core/providers.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/services/friends_service.dart';
import 'package:nipay/data/services/shared_expense_service.dart';
import 'package:nipay/features/transactions/add_transaction_sheet.dart';
import 'package:nipay/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../chat/fake_chat_service.dart';
import '../friends/friends_screen_test.dart' show FakeFriendsService;
import '../split/fake_shared_expense_service.dart';

User _user() => User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'me@test.local',
  createdAt: DateTime(2026).toIso8601String(),
);

class _Harness {
  final shared = FakeSharedExpenseService();
  final chat = FakeChatService();
  final friends = FakeFriendsService()
    ..friends.addAll(const [
      Friend(userId: 'bea', displayName: 'Bea', friendsSince: null),
      Friend(userId: 'carlo', displayName: 'Carlo', friendsSince: null),
    ]);
  late ProviderContainer container;
  late String walletId;

  AppDatabase get db => container.read(databaseProvider);

  Future<void> pump(WidgetTester tester, {bool signedIn = true}) async {
    final view = tester.view;
    view.physicalSize = Size(
      800 * view.devicePixelRatio,
      2400 * view.devicePixelRatio,
    );
    addTearDown(view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseExecutorProvider.overrideWithValue(NativeDatabase.memory()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          authStateProvider.overrideWith(
            (ref) => Stream.value(signedIn ? _user() : null),
          ),
          friendsServiceProvider.overrideWithValue(friends),
          sharedExpenseServiceProvider.overrideWithValue(shared),
          chatServiceProvider.overrideWithValue(chat),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAddTransactionSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    container = ProviderScope.containerOf(tester.element(find.text('open')));
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
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> addFriends(WidgetTester tester, List<String> ids) async {
    await tester.ensureVisible(find.byKey(const Key('shareAddFriendsButton')));
    await tester.tap(find.byKey(const Key('shareAddFriendsButton')));
    await tester.pumpAndSettle();
    for (final id in ids) {
      await tester.tap(find.byKey(ValueKey('sharePick_$id')));
    }
    await tester.tap(find.byKey(const Key('shareFriendsConfirm')));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('txSaveButton')));
    await tester.tap(find.byKey(const Key('txSaveButton')));
    await tester.pumpAndSettle();
  }

  Future<List<Transaction>> transactions(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.transactions).get()))!;

  Future<int> balance(WidgetTester tester) async => (await tester.runAsync(
    () => container.read(transactionRepositoryProvider).balanceOf(walletId),
  ))!;

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('I pay 60 € for three: server first, then my share and the '
      'advance for the others', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.enterText(find.byKey(const Key('amountField')), '60');
    await tester.enterText(find.byKey(const Key('descriptionField')), 'Cena');
    await tester.pump();
    await h.addFriends(tester, ['bea', 'carlo']);

    expect(find.textContaining('Bea owes you'), findsOneWidget);
    expect(find.textContaining('Carlo owes you'), findsOneWidget);
    expect(find.textContaining('Your share'), findsOneWidget);

    await h.save(tester);
    expect(h.shared.created.single, {
      'description': 'Cena',
      'total': 6000,
      'currency': 'EUR',
      'paidBy': 'me',
      'shares': {'me': 2000, 'bea': 2000, 'carlo': 2000},
    });
    final txs = await h.transactions(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'expense': 2000, 'friendOut': 4000},
    );
    expect(txs.every((t) => t.sharedExpenseId == 'se-1'), isTrue);
    expect(await h.balance(tester), 10000 - 6000);
    await h.unmount(tester);
  });

  testWidgets('a friend paid: my share plus my debt, the balance does not '
      'move', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.enterText(find.byKey(const Key('amountField')), '40');
    await tester.pump();
    await h.addFriends(tester, ['bea']);
    await tester.ensureVisible(find.byKey(const ValueKey('sharePayer_bea')));
    await tester.tap(find.byKey(const ValueKey('sharePayer_bea')));
    await tester.pumpAndSettle();

    expect(find.textContaining('You owe Bea'), findsOneWidget);
    await h.save(tester);
    expect(h.shared.created.single['paidBy'], 'bea');
    final txs = await h.transactions(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'expense': 2000, 'friendIn': 2000},
    );
    expect(await h.balance(tester), 10000);
    await h.unmount(tester);
  });

  testWidgets('custom amounts that do not add up are explained, nothing is '
      'saved', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.enterText(find.byKey(const Key('amountField')), '10');
    await tester.pump();
    await h.addFriends(tester, ['bea']);
    await tester.ensureVisible(find.text('Custom amounts'));
    await tester.tap(find.text('Custom amounts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('shareAmount_me')), '6');
    await tester.enterText(find.byKey(const ValueKey('shareAmount_bea')), '3');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shareSplitBalance')), findsOneWidget);

    await h.save(tester);
    expect(find.text('The amounts must add up to the total.'), findsWidgets);
    expect(h.shared.created, isEmpty);
    expect(await h.transactions(tester), isEmpty);

    await tester.enterText(find.byKey(const ValueKey('shareAmount_bea')), '4');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shareSplitBalance')), findsNothing);
    await h.save(tester);
    expect(h.shared.created.single['shares'], {'me': 600, 'bea': 400});
    await h.unmount(tester);
  });

  testWidgets('if the server refuses, nothing is created locally', (
    tester,
  ) async {
    final h = _Harness()..shared.failNext = SharedExpenseErrorCode.notAvailable;
    await h.pump(tester);
    await tester.enterText(find.byKey(const Key('amountField')), '20');
    await tester.pump();
    await h.addFriends(tester, ['bea']);
    await h.save(tester);

    expect(find.text("This person isn't available."), findsNWidgets(2));
    expect(await h.transactions(tester), isEmpty);
    await h.unmount(tester);
  });

  testWidgets('offline the card explains why it cannot share', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.chat.setOnline(false);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Sharing needs a connection. You can still save it as a normal '
        'expense.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shareAddFriendsButton')), findsNothing);
    await h.unmount(tester);
  });

  testWidgets('no card without an account or for income', (tester) async {
    final h = _Harness();
    await h.pump(tester, signedIn: false);
    expect(find.byKey(const Key('shareWithFriendsCard')), findsNothing);
    await h.unmount(tester);

    final h2 = _Harness();
    await h2.pump(tester);
    expect(find.byKey(const Key('shareWithFriendsCard')), findsOneWidget);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shareWithFriendsCard')), findsNothing);
    await h2.unmount(tester);
  });
}
