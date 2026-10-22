import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/profile_service.dart';
import '../../l10n/app_localizations.dart';
import 'friends_ui.dart';

/// Il mio QR (M-SOC2): contiene il link `com.alum.nipay://friend/<codice>`,
/// che un amico scansiona per inviarmi la richiesta. Il QR è sempre nero su
/// bianco, anche in tema scuro: è quello che le fotocamere leggono meglio.
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myQrCode)),
      body: SafeArea(
        // Prima l'errore: `value` su un AsyncValue in errore rilancia
        // l'eccezione, `valueOrNull` no.
        child: switch (profile) {
          AsyncValue(hasError: true) => _ProfileUnavailable(ref: ref),
          AsyncValue(:final valueOrNull?) => _QrBody(profile: valueOrNull),
          // Caricato ma senza profilo (nessun account): stesso messaggio.
          AsyncValue(hasValue: true) => _ProfileUnavailable(ref: ref),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: EmptyState(
        icon: Icons.cloud_off_outlined,
        message: l10n.profileLoadFailed,
        action: OutlinedButton(
          onPressed: () => ref.invalidate(myProfileProvider),
          child: Text(l10n.retry),
        ),
      ),
    );
  }
}

class _QrBody extends StatelessWidget {
  const _QrBody({required this.profile});

  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final code = formatFriendCode(profile.friendCode);
    final link = friendLink(profile.friendCode);
    return CenteredListView(
      top: 24,
      maxWidth: 420,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                InitialsAvatar(name: profile.displayName, radius: 28),
                const SizedBox(height: 10),
                Text(
                  personName(l10n, profile.displayName),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Semantics(
                  label: '${l10n.myQrCode}: $code',
                  excludeSemantics: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: QrImageView(
                        key: const Key('myQrImage'),
                        data: link,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: NipayColors.ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: NipayColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  code,
                  key: const Key('myQrCodeText'),
                  style: moneyStyle(size: 24, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myQrHelp,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: context.nipay.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AdaptivePair(
          minSideBySideWidth: 300,
          first: OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded),
            label: Text(l10n.copyFriendCode),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.friendCodeCopied)));
            },
          ),
          second: FilledButton.icon(
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(l10n.shareFriendCode),
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: l10n.shareFriendCodeText(link, code)),
            ),
          ),
        ),
      ],
    );
  }
}
