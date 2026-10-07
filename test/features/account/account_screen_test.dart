import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/providers.dart';
import 'package:nipay/data/services/auth_service.dart';
import 'package:nipay/data/services/local_data_service.dart';
import 'package:nipay/data/services/sync_service.dart';
import 'package:nipay/features/account/account_screen.dart';
import 'package:nipay/l10n/app_localizations.dart';
// `AuthException` nascosto: nipay/data/services/auth_service.dart ne
// definisce uno proprio con un messaggio già pronto per la UI, altrimenti
// ambiguo con quello di gotrue re-esportato qui.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

/// Doppio in-memory di [AuthService]: nessuna chiamata di rete, nessuna
/// dipendenza da Supabase.initialize() nei test.
class FakeAuthService implements AuthService {
  User? _currentUser;
  final _controller = StreamController<User?>.broadcast();
  final recoveryController = StreamController<void>.broadcast();
  String? lastResetEmail;
  bool throwOnNextCall = false;
  bool signedOutEverywhere = false;

  /// Password "vera" dell'account, per simulare la riautenticazione.
  static const accountPassword = 'password123';

  static User _fakeUser(String email) => User(
    id: 'fake-id',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: email,
    createdAt: DateTime.now().toIso8601String(),
  );

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Stream<void> get passwordRecoveryRequests => recoveryController.stream;

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) => _signIn(email);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _signIn(email);

  Future<void> _signIn(String email) async {
    if (throwOnNextCall) {
      throw const AuthException(AuthErrorCode.invalidCredentials);
    }
    _currentUser = _fakeUser(email);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> signOutEverywhere() async {
    signedOutEverywhere = true;
    await signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (throwOnNextCall) throw const AuthException(AuthErrorCode.rateLimited);
    lastResetEmail = email;
  }

  String? lastRecoveredPassword;

  @override
  Future<void> completePasswordRecovery(String newPassword) async {
    lastRecoveredPassword = newPassword;
  }

  String? lastChangedPassword;

  void _checkPassword(String password) {
    if (password != accountPassword) {
      throw const AuthException(AuthErrorCode.wrongCurrentPassword);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (throwOnNextCall) throw const AuthException(AuthErrorCode.unknown);
    _checkPassword(currentPassword);
    lastChangedPassword = newPassword;
  }

  DateTime? deletionRequestedAt;

  @override
  Future<DateTime?> getAccountDeletionRequestedAt() async =>
      deletionRequestedAt;

  @override
  Future<void> requestAccountDeletion({required String currentPassword}) async {
    if (throwOnNextCall) throw const AuthException(AuthErrorCode.unknown);
    _checkPassword(currentPassword);
    deletionRequestedAt = DateTime.now();
  }

  @override
  Future<void> cancelAccountDeletion() async {
    deletionRequestedAt = null;
  }
}

/// Doppio di [SyncService]: [foreignData] simula un device che contiene i
/// dati di un altro account.
class FakeSyncService implements SyncService {
  bool foreignData = false;
  bool failNextSync = false;
  int syncCalls = 0;
  int exclusiveCalls = 0;
  SyncStatus? syncStatus;
  LocalDataOwner? owner;

  @override
  Future<void> syncNow() async {
    syncCalls++;
    if (foreignData) throw const LocalDataOwnedByAnotherUserException();
    if (failNextSync) {
      failNextSync = false;
      throw Exception('rete non disponibile');
    }
  }

  @override
  Future<bool> hasLocalDataOfAnotherUser() async => foreignData;

  @override
  Future<LocalDataOwner?> localDataOwner() async => owner;

  @override
  Future<SyncStatus?> status() async => syncStatus;

  @override
  Future<T> exclusive<T>(Future<T> Function() action) {
    exclusiveCalls++;
    return action();
  }
}

class FakeLocalDataService implements LocalDataService {
  FakeLocalDataService(this._sync);

  final FakeSyncService _sync;
  bool wiped = false;

  @override
  Future<void> wipe() async {
    wiped = true;
    _sync.foreignData = false; // i dati dell'altro account non ci sono più
  }
}

late SharedPreferences _prefs;

Widget _wrap(
  Widget child, {
  required FakeAuthService fakeAuth,
  FakeSyncService? fakeSync,
  FakeLocalDataService? fakeLocalData,
}) {
  final sync = fakeSync ?? FakeSyncService();
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
      syncServiceProvider.overrideWithValue(sync),
      localDataServiceProvider.overrideWithValue(
        fakeLocalData ?? FakeLocalDataService(sync),
      ),
      sharedPreferencesProvider.overrideWithValue(_prefs),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Nessuno Scaffold di comodo qui: AccountScreen deve fornire il
      // proprio, altrimenti un push reale da Navigator (senza Scaffold)
      // va in crash — bug reale scoperto solo testando su simulatore,
      // non da questo test finché avvolgeva lui stesso in uno Scaffold.
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'activeWalletId': 'w1'});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('form validation rejects invalid email and short password', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('signing in shows the signed-in view with the email', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as test@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('toggling to sign-up mode changes the submit button label', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Sign up'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
  });

  testWidgets('an auth error is shown and does not sign the user in', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService()..throwOnNextCall = true;
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Messaggio generico tradotto, mai il testo grezzo del server, e
    // identico per "email non confermata" (niente enumerazione).
    expect(
      find.text('Invalid email or password, or email not confirmed yet.'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('sign-up requires a strong password (12+ chars, letters and '
      'digits)', (tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'new@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pump();
    expect(fakeAuth.currentUser, isNull);

    await tester.enterText(
      find.byType(TextFormField).last,
      'lunga-password-2026',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();
    expect(fakeAuth.currentUser, isNotNull);
  });

  testWidgets('a second reset email within a minute is not requested', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await tester.enterText(find.byType(TextFormField).first, 'a@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(fakeAuth.lastResetEmail, 'a@example.com');
    // Lascia scadere lo SnackBar di conferma (altrimenti il prossimo resta
    // in coda dietro di lui).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    fakeAuth.lastResetEmail = null;
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(fakeAuth.lastResetEmail, isNull);
    expect(
      find.text('Wait a minute before requesting another email.'),
      findsOneWidget,
    );
  });

  testWidgets('signing out returns to the auth form', (tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  Future<void> fillChangePassword(
    WidgetTester tester, {
    required String current,
    required String next,
    String? confirm,
  }) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Change password'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('currentPasswordField')),
      current,
    );
    await tester.enterText(find.byKey(const Key('newPasswordField')), next);
    await tester.enterText(
      find.byKey(const Key('confirmPasswordField')),
      confirm ?? next,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('changing password with the current password calls the '
      'service and signs out other devices', (tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await signIn(tester);

    await fillChangePassword(
      tester,
      current: FakeAuthService.accountPassword,
      next: 'nuova-password-2026',
    );

    expect(fakeAuth.lastChangedPassword, 'nuova-password-2026');
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('Password changed. Other devices have been signed out.'),
      findsOneWidget,
    );
  });

  testWidgets('changing password with a wrong current password is refused '
      '(a session alone is not enough)', (tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await signIn(tester);

    await fillChangePassword(
      tester,
      current: 'non-la-so',
      next: 'nuova-password-2026',
    );

    expect(fakeAuth.lastChangedPassword, isNull);
    expect(find.text('The current password is not correct.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('changing password to a weak one is refused locally', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await signIn(tester);

    await fillChangePassword(
      tester,
      current: FakeAuthService.accountPassword,
      next: 'corta1',
    );

    expect(fakeAuth.lastChangedPassword, isNull);
    expect(
      find.text('Use at least 12 characters, with letters and numbers.'),
      findsOneWidget,
    );
  });

  testWidgets('changing password with mismatched confirmation shows an '
      'error and does not call the service', (tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await signIn(tester);

    await fillChangePassword(
      tester,
      current: FakeAuthService.accountPassword,
      next: 'nuova-password-2026',
      confirm: 'diversa-password-2026',
    );

    expect(find.text("Passwords don't match"), findsOneWidget);
    expect(fakeAuth.lastChangedPassword, isNull);
  });

  Future<void> requestDeletion(WidgetTester tester, String password) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deleteAccountPassword')),
      password,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
  }

  testWidgets('requesting account deletion without the right password is '
      'refused', (tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await signIn(tester);

    await requestDeletion(tester, 'sbagliata');

    expect(fakeAuth.deletionRequestedAt, isNull);
    expect(find.text('The current password is not correct.'), findsOneWidget);
  });

  testWidgets('requesting account deletion shows the pending banner', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await signIn(tester);

    await requestDeletion(tester, FakeAuthService.accountPassword);

    expect(fakeAuth.deletionRequestedAt, isNotNull);
    expect(
      find.text('Account deletion requested. You have 30 days to cancel.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Cancel deletion'),
      findsOneWidget,
    );
  });

  testWidgets('canceling a pending deletion removes the banner', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(_wrap(const AccountScreen(), fakeAuth: fakeAuth));
    await signIn(tester);
    await requestDeletion(tester, FakeAuthService.accountPassword);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel deletion'));
    await tester.pumpAndSettle();

    expect(fakeAuth.deletionRequestedAt, isNull);
    expect(
      find.widgetWithText(OutlinedButton, 'Cancel deletion'),
      findsNothing,
    );
  });

  testWidgets('"sign out of all devices" closes every session', (tester) async {
    final fakeAuth = FakeAuthService();
    final fakeSync = FakeSyncService();
    await tester.pumpWidget(
      _wrap(const AccountScreen(), fakeAuth: fakeAuth, fakeSync: fakeSync),
    );
    await signIn(tester);

    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Sign out of all devices'),
    );
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Sign out of all devices'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Sign out of all devices'),
    );
    await tester.pumpAndSettle();

    expect(fakeAuth.signedOutEverywhere, isTrue);
    expect(fakeAuth.currentUser, isNull);
    expect(fakeSync.exclusiveCalls, 1, reason: 'mai in mezzo a una sync');
  });

  testWidgets('the account screen shows the outcome of the last sync', (
    tester,
  ) async {
    final fakeAuth = FakeAuthService();
    final fakeSync = FakeSyncService()
      ..syncStatus = SyncStatus(
        lastSuccessAt: DateTime(2026, 10, 5, 9, 30),
        lastError: 'failed',
        pendingIssues: 2,
      );
    await tester.pumpWidget(
      _wrap(const AccountScreen(), fakeAuth: fakeAuth, fakeSync: fakeSync),
    );
    await signIn(tester);

    expect(find.text('Last sync: 05/10/2026 09:30'), findsOneWidget);
    expect(
      find.text('The last sync failed: it will be retried automatically.'),
      findsOneWidget,
    );
    expect(
      find.text("2 items couldn't be synced and will be retried."),
      findsOneWidget,
    );
  });

  group('dati locali e cambio utente', () {
    Future<void> openSignOutDialog(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();
    }

    Future<void> confirmSignOut(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
    }

    testWidgets('signing out without the option keeps local data', (
      tester,
    ) async {
      final fakeAuth = FakeAuthService();
      final fakeSync = FakeSyncService();
      final fakeLocal = FakeLocalDataService(fakeSync);
      await tester.pumpWidget(
        _wrap(
          const AccountScreen(),
          fakeAuth: fakeAuth,
          fakeSync: fakeSync,
          fakeLocalData: fakeLocal,
        ),
      );
      await signIn(tester);

      await openSignOutDialog(tester);
      await confirmSignOut(tester);

      expect(fakeAuth.currentUser, isNull);
      expect(fakeLocal.wiped, isFalse);
      expect(_prefs.getString('activeWalletId'), 'w1');
    });

    testWidgets('signing out with "remove data" syncs first, then signs out '
        'and wipes the device', (tester) async {
      final fakeAuth = FakeAuthService();
      final fakeSync = FakeSyncService();
      final fakeLocal = FakeLocalDataService(fakeSync);
      await tester.pumpWidget(
        _wrap(
          const AccountScreen(),
          fakeAuth: fakeAuth,
          fakeSync: fakeSync,
          fakeLocalData: fakeLocal,
        ),
      );
      await signIn(tester);

      await openSignOutDialog(tester);
      await tester.tap(find.byKey(const Key('removeLocalDataCheckbox')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Receipt photos are not synced'),
        findsOneWidget,
      );
      await confirmSignOut(tester);

      expect(fakeSync.syncCalls, 1);
      expect(
        fakeSync.exclusiveCalls,
        1,
        reason: 'sync, logout e wipe sotto lock',
      );
      expect(fakeAuth.currentUser, isNull);
      expect(fakeLocal.wiped, isTrue);
      expect(_prefs.getString('activeWalletId'), isNull);
      expect(find.text('Data removed from this device'), findsOneWidget);
    });

    testWidgets('if the final sync fails nothing is removed and the user '
        'stays signed in', (tester) async {
      final fakeAuth = FakeAuthService();
      final fakeSync = FakeSyncService();
      final fakeLocal = FakeLocalDataService(fakeSync);
      await tester.pumpWidget(
        _wrap(
          const AccountScreen(),
          fakeAuth: fakeAuth,
          fakeSync: fakeSync,
          fakeLocalData: fakeLocal,
        ),
      );
      await signIn(tester);
      fakeSync.failNextSync = true;

      await openSignOutDialog(tester);
      await tester.tap(find.byKey(const Key('removeLocalDataCheckbox')));
      await tester.pumpAndSettle();
      await confirmSignOut(tester);

      expect(fakeLocal.wiped, isFalse);
      expect(fakeAuth.currentUser, isNotNull);
      expect(
        find.textContaining("Couldn't sync before removing"),
        findsOneWidget,
      );
    });

    testWidgets('data of another account blocks sync with a banner; removing '
        'it wipes the device and syncs this account', (tester) async {
      final fakeAuth = FakeAuthService();
      final fakeSync = FakeSyncService()..foreignData = true;
      final fakeLocal = FakeLocalDataService(fakeSync);
      await tester.pumpWidget(
        _wrap(
          const AccountScreen(),
          fakeAuth: fakeAuth,
          fakeSync: fakeSync,
          fakeLocalData: fakeLocal,
        ),
      );
      await signIn(tester);

      expect(find.byKey(const Key('foreignLocalDataBanner')), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Remove data and sync'),
      );
      await tester.pumpAndSettle();
      // Dialog di conferma: il pulsante distruttivo è l'ultimo.
      await tester.tap(
        find.widgetWithText(FilledButton, 'Remove data and sync').last,
      );
      await tester.pumpAndSettle();

      expect(fakeLocal.wiped, isTrue);
      expect(fakeSync.syncCalls, 1);
      expect(find.byKey(const Key('foreignLocalDataBanner')), findsNothing);
      expect(find.text('Sync complete'), findsOneWidget);
    });

    testWidgets('canceling the confirmation removes nothing', (tester) async {
      final fakeAuth = FakeAuthService();
      final fakeSync = FakeSyncService()..foreignData = true;
      final fakeLocal = FakeLocalDataService(fakeSync);
      await tester.pumpWidget(
        _wrap(
          const AccountScreen(),
          fakeAuth: fakeAuth,
          fakeSync: fakeSync,
          fakeLocalData: fakeLocal,
        ),
      );
      await signIn(tester);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Remove data and sync'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(fakeLocal.wiped, isFalse);
      expect(find.byKey(const Key('foreignLocalDataBanner')), findsOneWidget);
    });

    testWidgets('"Sync now" with data of another account explains why it is '
        'blocked', (tester) async {
      final fakeAuth = FakeAuthService();
      final fakeSync = FakeSyncService()..foreignData = true;
      await tester.pumpWidget(
        _wrap(const AccountScreen(), fakeAuth: fakeAuth, fakeSync: fakeSync),
      );
      await signIn(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sync now'));
      await tester.pumpAndSettle();

      expect(
        find.text('Sync paused: this device holds data from another account.'),
        findsOneWidget,
      );
    });
  });
}
