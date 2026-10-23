import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/services/friends_service.dart';
import '../../l10n/app_localizations.dart';
import 'add_friend_screen.dart';

/// Apre "Aggiungi amico" quando arriva il link di un QR amico
/// (`com.alum.nipay://friend/<codice>`), per esempio letto con la
/// fotocamera di sistema. Senza account porta alla tab Amici
/// ([onNeedsSignIn]), dove c'è l'invito ad accedere. Gli altri link
/// (recupero password, link estranei) li ignora: li gestisce Supabase o
/// nessuno.
class FriendLinkListener extends ConsumerStatefulWidget {
  const FriendLinkListener({
    super.key,
    required this.child,
    required this.onNeedsSignIn,
  });

  final Widget child;
  final VoidCallback onNeedsSignIn;

  @override
  ConsumerState<FriendLinkListener> createState() => _FriendLinkListenerState();
}

class _FriendLinkListenerState extends ConsumerState<FriendLinkListener> {
  StreamSubscription<Uri>? _subscription;

  /// Arrivato prima che lo stato di login fosse noto (avvio da link).
  String? _pendingCode;

  /// Ultimo codice gestito e quando: lo stesso link può arrivare due volte
  /// (link iniziale + flusso), si apre una sola volta.
  String? _lastCode;
  DateTime? _lastAt;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(incomingLinksProvider).listen(_onLink);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onLink(Uri uri) {
    final code = friendCodeFromScan(uri.toString());
    if (code == null) return;
    final now = DateTime.now();
    if (code == _lastCode &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastCode = code;
    _lastAt = now;
    final auth = ref.read(authStateProvider);
    if (auth.isLoading && !auth.hasValue) {
      _pendingCode = code;
      return;
    }
    _open(code, signedIn: auth.valueOrNull != null);
  }

  void _open(String code, {required bool signedIn}) {
    if (!mounted) return;
    if (!signedIn) {
      widget.onNeedsSignIn();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.friendsSignInPrompt),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddFriendScreen(initialCode: code)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Link arrivato all'avvio, prima che si sapesse se c'è un account.
    ref.listen(authStateProvider, (previous, next) {
      final code = _pendingCode;
      if (code == null || (next.isLoading && !next.hasValue)) return;
      _pendingCode = null;
      _open(code, signedIn: next.valueOrNull != null);
    });
    return widget.child;
  }
}
