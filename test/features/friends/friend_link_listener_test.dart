import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/providers.dart';
import 'package:nipay/data/services/profile_service.dart';
import 'package:nipay/features/friends/add_friend_screen.dart';
import 'package:nipay/features/friends/friend_link_listener.dart';
import 'package:nipay/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'friends_screen_test.dart'
    show FakeFriendsService, ResolvingProfileService;

User _user() => User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'me@test.local',
  createdAt: DateTime(2026).toIso8601String(),
);

ResolvingProfileService _profileWithBea() => ResolvingProfileService()
  ..displayName = 'Io'
  ..codes['BBBBBBBBBB'] = const FriendCodeMatch(
    userId: 'bea',
    displayName: 'Bea',
  );

late SharedPreferences _prefs;

Widget _app({
  required Widget home,
  required bool signedIn,
  ResolvingProfileService? profile,
  FakeFriendsService? friends,
  Stream<Uri>? links,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(
      (ref) => Stream.value(signedIn ? _user() : null),
    ),
    profileServiceProvider.overrideWithValue(profile ?? _profileWithBea()),
    friendsServiceProvider.overrideWithValue(friends ?? FakeFriendsService()),
    incomingLinksProvider.overrideWithValue(links ?? const Stream.empty()),
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
    home: home,
  ),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Add friend opened with a code goes straight to the '
      'confirmation', (tester) async {
    final profile = _profileWithBea();
    await tester.pumpWidget(
      _app(
        home: const AddFriendScreen(
          showCamera: false,
          initialCode: 'BBBBBBBBBB',
        ),
        signedIn: true,
        profile: profile,
      ),
    );
    await tester.pumpAndSettle();

    expect(profile.resolved, ['BBBBBBBBBB']);
    expect(find.text('Send a friend request to Bea?'), findsOneWidget);
  });

  group('FriendLinkListener', () {
    Widget shell({required VoidCallback onNeedsSignIn}) => FriendLinkListener(
      onNeedsSignIn: onNeedsSignIn,
      child: const Scaffold(body: Text('shell')),
    );

    testWidgets('signed in: a friend link opens Add friend with the code', (
      tester,
    ) async {
      final links = StreamController<Uri>();
      addTearDown(links.close);
      await tester.pumpWidget(
        _app(
          home: shell(onNeedsSignIn: () {}),
          signedIn: true,
          links: links.stream,
        ),
      );
      await tester.pumpAndSettle();

      links.add(Uri.parse('com.alum.nipay://friend/BBBBBBBBBB'));
      await tester.pumpAndSettle();

      expect(find.byType(AddFriendScreen), findsOneWidget);
      expect(find.text('Send a friend request to Bea?'), findsOneWidget);
    });

    testWidgets('the same link delivered twice opens Add friend once', (
      tester,
    ) async {
      final links = StreamController<Uri>();
      addTearDown(links.close);
      await tester.pumpWidget(
        _app(
          home: shell(onNeedsSignIn: () {}),
          signedIn: true,
          links: links.stream,
        ),
      );
      await tester.pumpAndSettle();

      final link = Uri.parse('com.alum.nipay://friend/BBBBBBBBBB');
      links
        ..add(link)
        ..add(link);
      await tester.pumpAndSettle();

      expect(find.byType(AddFriendScreen), findsOneWidget);
    });

    testWidgets('signed out: leads to the Friends tab instead of opening '
        'Add friend', (tester) async {
      final links = StreamController<Uri>();
      addTearDown(links.close);
      var asked = 0;
      await tester.pumpWidget(
        _app(
          home: shell(onNeedsSignIn: () => asked++),
          signedIn: false,
          links: links.stream,
        ),
      );
      await tester.pumpAndSettle();

      links.add(Uri.parse('com.alum.nipay://friend/BBBBBBBBBB'));
      await tester.pumpAndSettle();

      expect(asked, 1);
      expect(find.byType(AddFriendScreen), findsNothing);
      expect(
        find.text('Sign in to add friends, chat and split expenses.'),
        findsOneWidget,
      );
    });

    testWidgets('other links (password recovery, foreign) are ignored', (
      tester,
    ) async {
      final links = StreamController<Uri>();
      addTearDown(links.close);
      var asked = 0;
      await tester.pumpWidget(
        _app(
          home: shell(onNeedsSignIn: () => asked++),
          signedIn: true,
          links: links.stream,
        ),
      );
      await tester.pumpAndSettle();

      links
        ..add(Uri.parse('com.alum.nipay://auth-callback?code=abc'))
        ..add(Uri.parse('https://example.com/friend/BBBBBBBBBB'));
      await tester.pumpAndSettle();

      expect(find.byType(AddFriendScreen), findsNothing);
      expect(asked, 0);
    });
  });
}
