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
import 'package:nipay/features/split/split_section.dart';
import 'package:nipay/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../chat/fake_chat_service.dart';
import '../friends/friends_screen_test.dart' show FakeFriendsService;
import 'fake_shared_expense_service.dart';

User _user() => User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'me@test.local',
  createdAt: DateTime(2026).toIso8601String(),
);

/// La cena del piano creata da me: 60 € pagati da me, 20 € a testa.
SharedExpense _dinner({String createdBy = 'me', bool locked = false}) =>
    SharedExpense(
      id: 'se-1',
      createdBy: createdBy,
      paidBy: 'me',
      payerDisplayName: 'Io',
      description: 'Cena',
      totalCents: 6000,
      currency: 'EUR',
      spentOn: DateTime(2026, 10, 20),
      myShareCents: 2000,
      myShareRegistered: true,
      locked: locked,
      shares: const [
        SharedExpenseShare(
          userId: 'me',
          displayName: 'Io',
          shareCents: 2000,
          registered: true,
        ),
        SharedExpenseShare(
          userId: 'bea',
          displayName: 'Bea',
          shareCents: 2000,
          registered: false,
        ),
        SharedExpenseShare(
          userId: 'carlo',
          displayName: 'Carlo',
          shareCents: 2000,
          registered: false,
        ),
      ],
    );

class _Harness {
  _Harness({SharedExpense? expense}) {
    shared.expenses.add(expense ?? _dinner());
  }

  final shared = FakeSharedExpenseService();
  final friends = FakeFriendsService()
    ..friends.addAll(const [
      Friend(userId: 'bea', displayName: 'Bea', friendsSince: null),
      Friend(userId: 'carlo', displayName: 'Carlo', friendsSince: null),
    ]);
  late ProviderContainer container;
  late String walletId;
  late String myShareId;

  AppDatabase get db => container.read(databaseProvider);

  Future<void> pump(WidgetTester tester) async {
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
          authStateProvider.overrideWith((ref) => Stream.value(_user())),
          sharedExpenseServiceProvider.overrideWithValue(shared),
          friendsServiceProvider.overrideWithValue(friends),
          chatServiceProvider.overrideWithValue(FakeChatService()),
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
    final repo = container.read(transactionRepositoryProvider);
    await tester.runAsync(() async {
      walletId = await container
          .read(walletRepositoryProvider)
          .create(
            name: 'Conto',
            colorHex: '#0E7C86',
            initialBalanceCents: 10000,
          );
      // Come li ha creati il foglio transazione: quota + anticipo.
      myShareId = await repo.createExpense(
        walletId: walletId,
        amountCents: 2000,
        date: DateTime(2026, 10, 20),
        description: 'Cena',
        sharedExpenseId: 'se-1',
      );
      await repo.createFriendMovement(
        walletId: walletId,
        amountCents: 4000,
        date: DateTime(2026, 10, 20),
        outgoing: true,
        description: 'Cena',
        sharedExpenseId: 'se-1',
      );
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sharedExpense_se-1')));
    await tester.pumpAndSettle();
  }

  Future<List<Transaction>> live(WidgetTester tester) async =>
      (await tester.runAsync(
        () => (db.select(
          db.transactions,
        )..where((t) => t.deletedAt.isNull())).get(),
      ))!;

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

  testWidgets('only the creator can edit or delete, and only until locked', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.byKey(const Key('editSharedExpenseButton')), findsOneWidget);
    expect(find.byKey(const Key('deleteSharedExpenseButton')), findsOneWidget);
    await h.unmount(tester);

    final locked = _Harness(expense: _dinner(locked: true));
    await locked.pump(tester);
    expect(find.byKey(const Key('editSharedExpenseButton')), findsNothing);
    expect(
      find.text(
        'Someone has already registered their share, so it can no longer be '
        'changed.',
      ),
      findsOneWidget,
    );
    await locked.unmount(tester);

    final notMine = _Harness(expense: _dinner(createdBy: 'bea'));
    await notMine.pump(tester);
    expect(find.byKey(const Key('editSharedExpenseButton')), findsNothing);
    expect(find.byKey(const Key('deleteSharedExpenseButton')), findsNothing);
    await notMine.unmount(tester);
  });

  testWidgets('deleting removes it on the server and my linked movements', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.byKey(const Key('deleteSharedExpenseButton')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'It disappears for everyone, together with your movements in the '
        'wallet.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(h.shared.deleted, ['se-1']);
    expect(await h.live(tester), isEmpty);
    expect(await h.balance(tester), 10000);
    await h.unmount(tester);
  });

  testWidgets('a new total updates my share in place and redoes the advance', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.byKey(const Key('editSharedExpenseButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('editSharedAmountField')),
      '90',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('editSharedSaveButton')));
    await tester.tap(find.byKey(const Key('editSharedSaveButton')));
    await tester.pumpAndSettle();

    expect(h.shared.updated.single, {
      'id': 'se-1',
      'description': 'Cena',
      'total': 9000,
      'currency': 'EUR',
      'paidBy': 'me',
      'shares': {'me': 3000, 'bea': 3000, 'carlo': 3000},
    });
    final txs = await h.live(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'expense': 3000, 'friendOut': 6000},
    );
    // La quota è la stessa transazione: tag e scontrino restano.
    expect(txs.any((t) => t.id == h.myShareId), isTrue);
    expect(await h.balance(tester), 10000 - 9000);
    await h.unmount(tester);
  });

  testWidgets('if a friend paid instead, the movement turns into a debt', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.byKey(const Key('editSharedExpenseButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('sharePayer_bea')));
    await tester.tap(find.byKey(const ValueKey('sharePayer_bea')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('editSharedSaveButton')));
    await tester.tap(find.byKey(const Key('editSharedSaveButton')));
    await tester.pumpAndSettle();

    expect(h.shared.updated.single['paidBy'], 'bea');
    final txs = await h.live(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'expense': 2000, 'friendIn': 2000},
    );
    expect(await h.balance(tester), 10000);
    await h.unmount(tester);
  });

  testWidgets('if the server refuses, nothing changes locally', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.byKey(const Key('editSharedExpenseButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('editSharedAmountField')),
      '90',
    );
    await tester.pump();
    h.shared.failNext = SharedExpenseErrorCode.locked;
    await tester.ensureVisible(find.byKey(const Key('editSharedSaveButton')));
    await tester.tap(find.byKey(const Key('editSharedSaveButton')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Someone has already registered their share, so it can no longer be '
        'changed.',
      ),
      findsWidgets,
    );
    final txs = await h.live(tester);
    expect(
      {for (final t in txs) t.type.name: t.amountCents},
      {'expense': 2000, 'friendOut': 4000},
    );
    await h.unmount(tester);
  });
}
