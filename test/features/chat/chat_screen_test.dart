import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/providers.dart';
import 'package:nipay/data/services/chat_service.dart';
import 'package:nipay/data/services/friends_service.dart';
import 'package:nipay/features/chat/chat_screen.dart';
import 'package:nipay/features/chat/group_screens.dart';
import 'package:nipay/features/friends/friends_screen.dart';
import 'package:nipay/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../account/account_screen_test.dart' show FakeProfileService;
import '../friends/friends_screen_test.dart' show FakeFriendsService;
import 'fake_chat_service.dart';

User _user() => User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  email: 'me@test.local',
  createdAt: DateTime(2026).toIso8601String(),
);

late SharedPreferences _prefs;

ConversationMember _member(
  String id,
  String name, {
  MemberRole role = MemberRole.member,
}) => ConversationMember(
  userId: id,
  displayName: name,
  role: role,
  joinedAt: DateTime.utc(2026, 10, 23, 8),
);

/// La schermata si apre sopra una pagina, come nell'app.
Widget _wrap(
  Widget child, {
  required FakeChatService chat,
  FakeFriendsService? friends,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(_user())),
    chatServiceProvider.overrideWithValue(chat),
    friendsServiceProvider.overrideWithValue(friends ?? FakeFriendsService()),
    profileServiceProvider.overrideWithValue(
      FakeProfileService()..displayName = 'Io',
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
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => child)),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Chat 1:1 con Bea, con [count] messaggi suoi già in storia.
FakeChatService _directChat({int count = 2, bool canSend = true}) {
  final chat = FakeChatService()
    ..conversations.add(fakeConversation(id: 'c1', canSend: canSend))
    ..members['c1'] = [_member('me', 'Io'), _member('bea', 'Bea')];
  for (var i = 1; i <= count; i++) {
    chat.incoming('c1', 'msg $i');
  }
  return chat;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('opening a chat shows the history and marks it read', (
    tester,
  ) async {
    final chat = _directChat();
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);

    expect(find.text('Bea'), findsOneWidget);
    expect(find.text('msg 1'), findsOneWidget);
    expect(find.text('msg 2'), findsOneWidget);
    // La lista è al contrario: il più recente sta in basso.
    expect(
      tester.getTopLeft(find.text('msg 2')).dy,
      greaterThan(tester.getTopLeft(find.text('msg 1')).dy),
    );
    expect(chat.calls, contains('markRead:c1'));
  });

  testWidgets('a sent message appears once, even when the real-time echo '
      'arrives', (tester) async {
    final chat = _directChat();
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);

    await tester.enterText(find.byKey(const Key('chatInput')), '  ciao Bea  ');
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();
    expect(chat.calls, contains('send:c1:ciao Bea'));
    expect(find.text('ciao Bea'), findsOneWidget);

    // Lo stesso messaggio torna dal canale in tempo reale.
    chat.emit(MessageChanged(chat.messages['c1']!.first));
    await tester.pumpAndSettle();
    expect(find.text('ciao Bea'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('chatInput')));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('real-time messages appear, deletions replace the text', (
    tester,
  ) async {
    final chat = _directChat(count: 1);
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);
    chat.calls.clear();

    final live = chat.incoming('c1', 'appena arrivato');
    chat.emit(MessageChanged(live));
    // Eventi di altre chat: ignorati.
    chat.emit(MessageChanged(chat.incoming('other', 'altrove')));
    await tester.pumpAndSettle();
    expect(find.text('appena arrivato'), findsOneWidget);
    expect(find.text('altrove'), findsNothing);
    expect(chat.calls, contains('markRead:c1'));

    chat.emit(
      MessageChanged(
        ChatMessage(
          id: live.id,
          conversationId: 'c1',
          senderId: 'bea',
          senderDisplayName: null,
          body: null,
          createdAt: live.createdAt,
          deleted: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('appena arrivato'), findsNothing);
    expect(find.text('Message deleted'), findsOneWidget);
    expect(find.text('msg 1'), findsOneWidget);
  });

  testWidgets('a read-only chat explains why and cannot send', (tester) async {
    final chat = _directChat(canSend: false);
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);

    expect(find.text('You can no longer write in this chat.'), findsOneWidget);
    final send = tester.widget<IconButton>(
      find.byKey(const Key('chatSendButton')),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('offline: the input is off with an explanation', (tester) async {
    final chat = _directChat();
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);

    chat.setOnline(false);
    await tester.pumpAndSettle();
    expect(
      find.text("You're offline. You can write again when you're back online."),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('chatSendButton')))
          .onPressed,
      isNull,
    );

    chat.setOnline(true);
    await tester.pumpAndSettle();
    expect(
      find.text("You're offline. You can write again when you're back online."),
      findsNothing,
    );
  });

  testWidgets('earlier messages load at the top without duplicates', (
    tester,
  ) async {
    final chat = _directChat(count: 51);
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);

    // Lista al contrario: i più vecchi stanno in alto, si trascina in giù.
    await tester.dragUntilVisible(
      find.byKey(const Key('loadEarlierButton')),
      find.byKey(const Key('chatMessages')),
      const Offset(0, 300),
    );
    await tester.tap(find.byKey(const Key('loadEarlierButton')));
    await tester.pumpAndSettle();

    expect(chat.calls.last, startsWith('list:c1:m'));
    expect(find.byKey(const Key('loadEarlierButton')), findsNothing);
    expect(find.text('msg 1'), findsOneWidget);
  });

  testWidgets('reporting a message needs a reason, then sends it', (
    tester,
  ) async {
    final chat = _directChat(count: 1);
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);

    await tester.longPress(find.text('msg 1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deleteMessageAction')), findsNothing);
    await tester.tap(find.byKey(const Key('reportMessageAction')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reportSendButton')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a reason.'), findsOneWidget);
    expect(chat.calls.where((c) => c.startsWith('report')), isEmpty);

    await tester.tap(find.byKey(const ValueKey('reportReason_spam')));
    await tester.enterText(
      find.byKey(const Key('reportDetailsField')),
      ' pubblicità ',
    );
    await tester.tap(find.byKey(const Key('reportSendButton')));
    await tester.pumpAndSettle();

    expect(chat.calls, contains('reportMessage:m0:spam:pubblicità'));
    expect(find.text('Report sent. Thank you.'), findsOneWidget);
  });

  testWidgets('reporting can also block the person', (tester) async {
    final chat = _directChat(count: 1);
    final friends = FakeFriendsService();
    await tester.pumpWidget(
      _wrap(
        const ChatScreen(conversationId: 'c1'),
        chat: chat,
        friends: friends,
      ),
    );
    await _open(tester);

    await tester.tap(find.byKey(const Key('reportPeerButton')));
    await tester.pumpAndSettle();
    expect(find.text('Report Bea'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reportReason_harassment')));
    await tester.tap(find.byKey(const Key('reportAlsoBlock')));
    await tester.tap(find.byKey(const Key('reportSendButton')));
    await tester.pumpAndSettle();

    expect(chat.calls, contains('reportUser:bea:harassment:null'));
    expect(friends.calls, contains('block:bea'));
  });

  testWidgets('own messages can be deleted after confirmation', (tester) async {
    final chat = _directChat(count: 0);
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'c1'), chat: chat),
    );
    await _open(tester);
    await tester.enterText(find.byKey(const Key('chatInput')), 'mio');
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('mio'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reportMessageAction')), findsNothing);
    await tester.tap(find.byKey(const Key('deleteMessageAction')));
    await tester.pumpAndSettle();
    expect(
      find.text('Everyone in the chat will see “Message deleted”.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(chat.calls.last, startsWith('delete:m'));
  });

  testWidgets('in a group the sender name is shown on others\' messages', (
    tester,
  ) async {
    final chat = FakeChatService()
      ..conversations.add(
        fakeConversation(
          id: 'g1',
          kind: ConversationKind.group,
          title: 'Viaggio',
          memberCount: 3,
        ),
      )
      ..members['g1'] = [
        _member('me', 'Io', role: MemberRole.admin),
        _member('bea', 'Bea'),
        _member('carlo', 'Carlo'),
      ];
    chat.incoming('g1', 'da Carlo', senderId: 'carlo');
    await tester.pumpWidget(
      _wrap(const ChatScreen(conversationId: 'g1'), chat: chat),
    );
    await _open(tester);

    expect(find.text('Viaggio'), findsOneWidget);
    expect(find.text('3 members'), findsOneWidget);
    expect(find.text('Carlo'), findsOneWidget);
    expect(find.text('da Carlo'), findsOneWidget);
  });

  group('Friends tab', () {
    Future<void> pumpTab(
      WidgetTester tester,
      FakeChatService chat,
      FakeFriendsService friends,
    ) async {
      final view = tester.view;
      view.physicalSize = Size(
        800 * view.devicePixelRatio,
        1600 * view.devicePixelRatio,
      );
      addTearDown(view.resetPhysicalSize);
      await tester.pumpWidget(
        _wrap(const FriendsScreen(), chat: chat, friends: friends),
      );
      await _open(tester);
    }

    testWidgets('lists chats with preview and unread count', (tester) async {
      final chat = FakeChatService()
        ..conversations.addAll([
          fakeConversation(
            id: 'c1',
            unreadCount: 3,
            lastMessage: ChatMessage(
              id: 'x',
              conversationId: 'c1',
              senderId: 'me',
              senderDisplayName: null,
              body: 'a domani',
              createdAt: DateTime.utc(2026, 10, 1),
              deleted: false,
            ),
          ),
          fakeConversation(
            id: 'g1',
            kind: ConversationKind.group,
            title: 'Viaggio',
            memberCount: 4,
          ),
        ]);
      await pumpTab(tester, chat, FakeFriendsService());

      expect(find.text('You: a domani'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Viaggio'), findsOneWidget);
      expect(find.text('4 members'), findsOneWidget);
    });

    testWidgets('tapping a friend opens the 1:1 chat', (tester) async {
      final chat = FakeChatService()
        ..conversations.add(fakeConversation(id: 'direct-bea'))
        ..members['direct-bea'] = [_member('me', 'Io'), _member('bea', 'Bea')];
      final friends = FakeFriendsService()
        ..friends.add(
          const Friend(userId: 'bea', displayName: 'Bea', friendsSince: null),
        );
      await pumpTab(tester, chat, friends);

      await tester.tap(find.byKey(const ValueKey('friend_bea')));
      await tester.pumpAndSettle();

      expect(chat.calls, contains('openDirect:bea'));
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('No messages yet. Say hi!'), findsOneWidget);
    });
  });

  testWidgets('a new group needs a name and a friend, then opens', (
    tester,
  ) async {
    final chat = FakeChatService();
    final friends = FakeFriendsService()
      ..friends.addAll(const [
        Friend(userId: 'bea', displayName: 'Bea', friendsSince: null),
        Friend(userId: 'carlo', displayName: 'Carlo', friendsSince: null),
      ]);
    await tester.pumpWidget(
      _wrap(const NewGroupScreen(), chat: chat, friends: friends),
    );
    await _open(tester);

    await tester.tap(find.byKey(const Key('createGroupButton')));
    await tester.pumpAndSettle();
    expect(find.text('Use 1 to 60 characters.'), findsOneWidget);
    expect(find.text('Choose at least one friend.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('groupTitleField')),
      ' Calcetto ',
    );
    await tester.tap(find.byKey(const ValueKey('pickFriend_carlo')));
    await tester.tap(find.byKey(const Key('createGroupButton')));
    await tester.pumpAndSettle();

    expect(chat.calls, contains('createGroup:Calcetto:carlo'));
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('group info: the admin removes a member, anyone can leave', (
    tester,
  ) async {
    final chat = FakeChatService()
      ..members['g1'] = [
        _member('me', 'Io', role: MemberRole.admin),
        _member('bea', 'Bea'),
      ];
    await tester.pumpWidget(
      _wrap(const GroupInfoScreen(conversationId: 'g1'), chat: chat),
    );
    await _open(tester);

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.byKey(const ValueKey('removeMember_me')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('removeMember_bea')));
    await tester.pumpAndSettle();
    expect(find.text('Bea will no longer see this group.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(chat.calls, contains('removeMember:g1:bea'));
    expect(find.text('Bea'), findsNothing);

    await tester.tap(find.byKey(const Key('leaveGroupButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(chat.calls, contains('leaveGroup:g1'));
    expect(find.text('open'), findsOneWidget);
  });
}
