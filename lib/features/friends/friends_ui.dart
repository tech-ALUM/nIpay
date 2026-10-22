import 'package:flutter/material.dart';

import '../../data/services/friends_service.dart';
import '../../l10n/app_localizations.dart';

/// Testo per l'utente di un errore di amicizie (mai il messaggio del server).
String friendsErrorText(AppLocalizations l10n, FriendsErrorCode code) =>
    switch (code) {
      FriendsErrorCode.notAvailable => l10n.friendsErrorNotAvailable,
      FriendsErrorCode.cooldown => l10n.friendsErrorCooldown,
      FriendsErrorCode.tooManyPending => l10n.friendsErrorTooManyPending,
      FriendsErrorCode.notFound => l10n.friendsErrorNotFound,
      FriendsErrorCode.rateLimited => l10n.authErrorRateLimited,
      FriendsErrorCode.network => l10n.authErrorNetwork,
      FriendsErrorCode.unknown => l10n.authErrorGeneric,
    };

/// Nome da mostrare per un altro utente (può non averlo ancora scelto).
String personName(AppLocalizations l10n, String? displayName) =>
    displayName ?? l10n.unnamedUser;

/// Avatar con le iniziali del nome (niente foto profilo, decisione del
/// piano). Decorativo: il nome è sempre scritto accanto.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 20});

  final String? name;
  final double radius;

  static String initialsOf(String? name) {
    final words = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    final second = words.length > 1 ? words[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          initialsOf(name),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
