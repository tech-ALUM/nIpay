import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/providers.dart';
import 'package:nipay/data/services/friends_service.dart';
import 'package:nipay/data/services/profile_service.dart';
import 'package:nipay/features/friends/add_friend_screen.dart';
import 'package:nipay/features/friends/friends_screen.dart';
import 'package:nipay/features/friends/my_qr_screen.dart';
import 'package:nipay/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../account/account_screen_test.dart' show FakeProfileService;
import '../chat/fake_chat_service.dart';

/// Doppio di [FriendsService]: stato in memoria, chiamate registrate.
class FakeFriendsService implements FriendsService {
  final friends = <Friend>[];
  final requests = <FriendRequest>[];
  final blocked = <BlockedUser>[];
  final calls = <String>[];
  SendRequestResult sendResult = SendRequestResult.pending;
  FriendsErrorCode? failNext;

  /// Le letture falliscono (es. migration non ancora sull'hosted).
  bool failReads = false;

  void _maybeFail() {
    final code = failNext;
    if (code == null) return;
    failNext = null;
    throw FriendsException(code);
  }

  @override
  Future<List<Friend>> listFriends() async {
    calls.add('listFriends');
    if (failReads) throw const FriendsException(FriendsErrorCode.unknown);
    return List.of(friends);
  }

  @override
  Future<List<FriendRequest>> listRequests() async {
    calls.add('listRequests');
    if (failReads) throw const FriendsException(FriendsErrorCode.unknown);
    return List.of(requests);
  }

  @override
  Future<List<BlockedUser>> listBlocked() async {
    calls.add('listBlocked');
    if (failReads) throw const FriendsException(FriendsErrorCode.unknown);
    return List.of(blocked);
  }

  @override
  Future<SendRequestResult> sendRequest(String userId) async {
    calls.add('send:$userId');
    _maybeFail();
    return sendResult;
  }

  @override
  Future<void> respond(String requestId, {required bool accept}) async {
    calls.add('respond:$requestId:$accept');
    _maybeFail();
    final r = requests.firstWhere((r) => r.id == requestId);
    requests.remove(r);
    if (accept) {
      friends.add(
        Friend(
          userId: r.userId,
          displayName: r.displayName,
          friendsSince: null,
        ),
      );
    }
  }

  @override
  Future<void> cancel(String requestId) async {
    calls.add('cancel:$requestId');
    requests.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<void> removeFriend(String userId) async {
    calls.add('remove:$userId');
    friends.removeWhere((f) => f.userId == userId);
  }

  @override
  Future<void> block(String userId) async {
    calls.add('block:$userId');
    final name = [
      ...friends.where((f) => f.userId == userId).map((f) => f.displayName),
      ...requests.where((r) => r.userId == userId).map((r) => r.displayName),
    ].firstOrNull;
    friends.removeWhere((f) => f.userId == userId);
    requests.removeWhere((r) => r.userId == userId);
    blocked.add(BlockedUser(userId: userId, displayName: name));
  }

  @override
  Future<void> unblock(String userId) async {
    calls.add('unblock:$userId');
    blocked.removeWhere((b) => b.userId == userId);
  }
}

/// Profilo con risoluzione dei codici configurabile.
/// Profilo che non si riesce a caricare.
class FailingProfileService extends FakeProfileService {
  @override
  Future<MyProfile?> getMyProfile() async =>
      throw const ProfileException(ProfileErrorCode.network);
}

class ResolvingProfileService extends FakeProfileService {
  final codes = <String, FriendCodeMatch>{};
  final resolved = <String>[];

  @override
  Future<FriendCodeMatch?> resolveFriendCode(String code) async {
    resolved.add(code);
    return codes[code];
  }
}

User _user() => User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'me@test.local',
  createdAt: DateTime(2026).toIso8601String(),
);

FriendRequest _incoming(String id, String userId, String name) => FriendRequest(
  id: id,
  direction: FriendRequestDirection.incoming,
  userId: userId,
  displayName: name,
  status: FriendRequestStatus.pending,
  createdAt: DateTime(2026, 10, 22),
);

late SharedPreferences _prefs;

Widget _wrap(
  Widget child, {
  required FakeFriendsService friends,
  FakeProfileService? profile,
  FakeChatService? chat,
  bool signedIn = true,
  bool pushed = false,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(
      (ref) => Stream.value(signedIn ? _user() : null),
    ),
    friendsServiceProvider.overrideWithValue(friends),
    chatServiceProvider.overrideWithValue(chat ?? FakeChatService()),
    profileServiceProvider.overrideWithValue(
      profile ?? (FakeProfileService()..displayName = 'Io'),
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
    // pushed: la schermata si apre sopra una pagina, come nell'app (Aggiungi
    // amico si chiude dopo l'invio e il messaggio compare sotto).
    home: pushed
        ? Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => child)),
                child: const Text('open'),
              ),
            ),
          )
        : Scaffold(body: child),
  ),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.physicalSize = Size(
      800 * view.devicePixelRatio,
      1600 * view.devicePixelRatio,
    );
    addTearDown(view.resetPhysicalSize);
  });

  testWidgets('without an account: sign-in invite and no server calls', (
    tester,
  ) async {
    final friends = FakeFriendsService();
    await tester.pumpWidget(
      _wrap(const FriendsScreen(), friends: friends, signedIn: false),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Sign in to add friends, chat and split expenses.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('friendsSignInButton')), findsOneWidget);
    expect(friends.calls, isEmpty);
  });

  testWidgets('first open without a name asks "What\'s your name?"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const FriendsScreen(),
        friends: FakeFriendsService(),
        profile: FakeProfileService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.byKey(const Key('displayNameField')), findsOneWidget);
  });

  testWidgets('"What\'s your name?" waits until the Friends tab is the '
      'visible one', (tester) async {
    Widget screen({required bool active}) => _wrap(
      FriendsScreen(active: active),
      friends: FakeFriendsService(),
      profile: FakeProfileService(),
    );
    await tester.pumpWidget(screen(active: false));
    await tester.pumpAndSettle();
    expect(
      find.text("What's your name?"),
      findsNothing,
      reason: 'tab non selezionata',
    );

    await tester.pumpWidget(screen(active: true));
    await tester.pumpAndSettle();
    expect(find.text("What's your name?"), findsOneWidget);
  });

  testWidgets('"What\'s your name?" does not cover another screen opened on '
      'top', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(body: Text('sopra')),
                  ),
                ),
                child: const Text('apri sopra'),
              ),
              const Expanded(child: FriendsScreen()),
            ],
          ),
        ),
        friends: FakeFriendsService(),
        profile: FakeProfileService(),
      ),
    );
    // Si apre un'altra schermata prima che il profilo arrivi.
    await tester.tap(find.text('apri sopra'));
    await tester.pumpAndSettle();
    expect(find.text('sopra'), findsOneWidget);
    expect(find.text("What's your name?"), findsNothing);

    // Tornando alla tab, la domanda arriva.
    Navigator.of(tester.element(find.text('sopra'))).pop();
    await tester.pumpAndSettle();
    expect(find.text("What's your name?"), findsOneWidget);
  });

  testWidgets('accepting an incoming request makes them a friend', (
    tester,
  ) async {
    final friends = FakeFriendsService()
      ..requests.add(_incoming('r1', 'bea', 'Bea'));
    await tester.pumpWidget(_wrap(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    expect(find.text('Wants to be your friend'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('accept_r1')));
    await tester.pumpAndSettle();

    expect(friends.calls, contains('respond:r1:true'));
    expect(find.text('Wants to be your friend'), findsNothing);
    expect(find.byKey(const ValueKey('friend_bea')), findsOneWidget);
  });

  testWidgets('declining an incoming request does not add a friend', (
    tester,
  ) async {
    final friends = FakeFriendsService()
      ..requests.add(_incoming('r1', 'bea', 'Bea'));
    await tester.pumpWidget(_wrap(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('decline_r1')));
    await tester.pumpAndSettle();

    expect(friends.calls, contains('respond:r1:false'));
    expect(find.byKey(const ValueKey('friend_bea')), findsNothing);
    expect(
      find.text(
        'No friends yet. Let a friend scan your QR code, or scan theirs.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an outgoing request shows its state and can be canceled', (
    tester,
  ) async {
    final friends = FakeFriendsService()
      ..requests.add(
        FriendRequest(
          id: 'r2',
          direction: FriendRequestDirection.outgoing,
          userId: 'carlo',
          displayName: 'Carlo',
          status: FriendRequestStatus.pending,
          createdAt: DateTime(2026, 10, 22),
        ),
      );
    await tester.pumpWidget(_wrap(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for a reply'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel_r2')));
    await tester.pumpAndSettle();

    expect(friends.calls, contains('cancel:r2'));
    expect(find.text('Waiting for a reply'), findsNothing);
  });

  testWidgets('blocking a friend asks for confirmation, then moves them to '
      'Blocked; unblocking removes them', (tester) async {
    final friends = FakeFriendsService()
      ..friends.add(
        const Friend(userId: 'bea', displayName: 'Bea', friendsSince: null),
      );
    await tester.pumpWidget(_wrap(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('friendMenu_bea')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block').last);
    await tester.pumpAndSettle();
    expect(friends.calls, isNot(contains('block:bea')), reason: 'conferma');

    await tester.tap(find.byKey(const Key('friendsConfirmButton')));
    await tester.pumpAndSettle();
    expect(friends.calls, contains('block:bea'));
    expect(find.text('Blocked'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unblock_bea')));
    await tester.pumpAndSettle();
    expect(friends.calls, contains('unblock:bea'));
    expect(find.text('Blocked'), findsNothing);
  });

  testWidgets('removing a friend asks for confirmation', (tester) async {
    final friends = FakeFriendsService()
      ..friends.add(
        const Friend(userId: 'bea', displayName: 'Bea', friendsSince: null),
      );
    await tester.pumpWidget(_wrap(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('friendMenu_bea')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove friend').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Bea will no longer be among your friends. You can add each other '
        'again later.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('friendsConfirmButton')));
    await tester.pumpAndSettle();

    expect(friends.calls, contains('remove:bea'));
    expect(find.byKey(const ValueKey('friend_bea')), findsNothing);
  });

  testWidgets('if the server fails, the tab explains and offers Retry '
      'instead of crashing', (tester) async {
    final friends = FakeFriendsService()..failReads = true;
    await tester.pumpWidget(_wrap(const FriendsScreen(), friends: friends));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        "Couldn't load your friends. Check your connection and try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    friends.failReads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No friends yet. Let a friend scan your QR code, or scan theirs.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('My QR code explains when the profile cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const MyQrScreen(),
        friends: FakeFriendsService(),
        profile: FailingProfileService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        "Couldn't load your profile. Check your connection and try again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('My QR code without a name offers to add it, then shows it', (
    tester,
  ) async {
    final profile = FakeProfileService(); // nessun nome
    await tester.pumpWidget(
      _wrap(
        const MyQrScreen(),
        friends: FakeFriendsService(),
        profile: profile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unnamed user'), findsOneWidget);
    await tester.tap(find.byKey(const Key('myQrAddNameButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('displayNameField')), 'Sergio');
    await tester.tap(find.byKey(const Key('displayNameSaveButton')));
    await tester.pumpAndSettle();

    expect(profile.savedNames, ['Sergio']);
    expect(find.text('Sergio'), findsOneWidget);
    expect(find.text('Unnamed user'), findsNothing);
    expect(find.byKey(const Key('myQrAddNameButton')), findsNothing);
  });

  testWidgets('My QR code with a name does not offer to add one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const MyQrScreen(), friends: FakeFriendsService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Io'), findsOneWidget);
    expect(find.byKey(const Key('myQrAddNameButton')), findsNothing);
  });

  group('add friend by code', () {
    testWidgets('an invalid code is refused inline, without calling the '
        'server', (tester) async {
      final profile = ResolvingProfileService()..displayName = 'Io';
      await tester.pumpWidget(
        _wrap(
          const AddFriendScreen(showCamera: false),
          friends: FakeFriendsService(),
          profile: profile,
        ),
      );
      await tester.enterText(
        find.byKey(const Key('manualFriendCodeField')),
        'ciao',
      );
      await tester.tap(find.byKey(const Key('findFriendButton')));
      await tester.pumpAndSettle();

      expect(find.text("This isn't a valid friend code."), findsOneWidget);
      expect(profile.resolved, isEmpty);
    });

    testWidgets('a code that leads to no one says so', (tester) async {
      final profile = ResolvingProfileService()..displayName = 'Io';
      await tester.pumpWidget(
        _wrap(
          const AddFriendScreen(showCamera: false),
          friends: FakeFriendsService(),
          profile: profile,
        ),
      );
      await tester.enterText(
        find.byKey(const Key('manualFriendCodeField')),
        'zzzzz-zzzzz',
      );
      await tester.tap(find.byKey(const Key('findFriendButton')));
      await tester.pumpAndSettle();

      expect(profile.resolved, ['ZZZZZZZZZZ']);
      expect(find.text('No one found with this code.'), findsOneWidget);
    });

    testWidgets('a valid code shows who it is, asks to confirm and sends the '
        'request', (tester) async {
      final profile = ResolvingProfileService()
        ..displayName = 'Io'
        ..codes['BBBBBBBBBB'] = const FriendCodeMatch(
          userId: 'bea',
          displayName: 'Bea',
        );
      final friends = FakeFriendsService();
      await tester.pumpWidget(
        _wrap(
          const AddFriendScreen(showCamera: false),
          friends: friends,
          profile: profile,
          pushed: true,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('manualFriendCodeField')),
        'bbbbb-bbbbb',
      );
      await tester.tap(find.byKey(const Key('findFriendButton')));
      await tester.pumpAndSettle();

      expect(find.text('Send a friend request to Bea?'), findsOneWidget);
      expect(friends.calls, isNot(contains('send:bea')), reason: 'conferma');
      await tester.tap(find.byKey(const Key('sendFriendRequestButton')));
      await tester.pumpAndSettle();

      expect(friends.calls, contains('send:bea'));
      expect(find.text('Request sent to Bea'), findsOneWidget);
    });

    testWidgets('a server refusal is shown translated', (tester) async {
      final profile = ResolvingProfileService()
        ..displayName = 'Io'
        ..codes['BBBBBBBBBB'] = const FriendCodeMatch(
          userId: 'bea',
          displayName: 'Bea',
        );
      final friends = FakeFriendsService()
        ..failNext = FriendsErrorCode.cooldown;
      await tester.pumpWidget(
        _wrap(
          const AddFriendScreen(showCamera: false),
          friends: friends,
          profile: profile,
          pushed: true,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('manualFriendCodeField')),
        'BBBBBBBBBB',
      );
      await tester.tap(find.byKey(const Key('findFriendButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sendFriendRequestButton')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This person declined your request recently. Try again in a few '
          'days.',
        ),
        findsOneWidget,
      );
    });
  });
}
