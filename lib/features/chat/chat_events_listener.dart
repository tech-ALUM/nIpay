import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/services/chat_service.dart';

/// Tiene aggiornate lista chat, badge e amici con gli eventi in tempo
/// reale (M-SOC3), ovunque sia l'utente nell'app. Una raffica di eventi
/// (es. un gruppo appena creato) produce una sola ricarica.
class ChatEventsListener extends ConsumerStatefulWidget {
  const ChatEventsListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ChatEventsListener> createState() => _ChatEventsListenerState();
}

class _ChatEventsListenerState extends ConsumerState<ChatEventsListener> {
  static const _debounce = Duration(milliseconds: 300);

  StreamSubscription<ChatEvent>? _subscription;
  Timer? _timer;
  bool _friendsChanged = false;

  @override
  void initState() {
    super.initState();
    _listen(ref.read(chatEventsProvider));
  }

  void _listen(Stream<ChatEvent> events) {
    _subscription?.cancel();
    _subscription = events.listen((event) {
      if (event is FriendshipsChanged) _friendsChanged = true;
      _timer?.cancel();
      _timer = Timer(_debounce, _refresh);
    });
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(conversationsProvider);
    if (_friendsChanged) {
      _friendsChanged = false;
      refreshFriends(ref);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nuovo canale a ogni login/logout (il provider dipende dall'account).
    ref.listen(chatEventsProvider, (_, next) => _listen(next));
    return widget.child;
  }
}
