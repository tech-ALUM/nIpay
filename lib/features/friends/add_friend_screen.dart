import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/profile_service.dart';
import '../../l10n/app_localizations.dart';
import 'display_name_dialog.dart';
import 'friends_ui.dart';

/// Aggiungi amico (M-SOC2): scansione del QR dell'altro, oppure codice
/// digitato a mano. In entrambi i casi: codice → chi è → conferma →
/// richiesta. L'amicizia nasce solo quando l'altro accetta.
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key, this.showCamera = true});

  /// False nei widget test (lì la fotocamera non esiste): resta solo il
  /// codice a mano, che segue lo stesso percorso della scansione.
  final bool showCamera;

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _codeController = TextEditingController();
  String? _codeError;

  /// Un codice in lavorazione (anche col dialog di conferma aperto):
  /// blocca nuove scansioni e invii doppi.
  bool _busy = false;

  /// Solo durante le chiamate al server: lo spinner gira mentre si
  /// aspetta la rete, non mentre si aspetta l'utente.
  bool _loading = false;

  /// L'ultimo valore scansionato: la fotocamera rilegge lo stesso QR più
  /// volte al secondo, si gestisce una volta sola.
  String? _lastScan;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onScan(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw == _lastScan || _busy) return;
    _lastScan = raw;
    final code = friendCodeFromScan(raw);
    if (code == null) {
      _showSnack(AppLocalizations.of(context)!.notANipayQr);
      return;
    }
    _addByCode(code);
  }

  void _onManualSubmit() {
    final code = friendCodeFromScan(_codeController.text);
    if (code == null) {
      setState(
        () => _codeError = AppLocalizations.of(context)!.invalidFriendCode,
      );
      return;
    }
    setState(() => _codeError = null);
    _addByCode(code);
  }

  Future<void> _addByCode(String code) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = _loading = true);
    try {
      final match = await ref
          .read(profileServiceProvider)
          .resolveFriendCode(code);
      if (!mounted) return;
      setState(() => _loading = false);
      if (match == null) {
        _showSnack(l10n.friendCodeNoMatch);
        return;
      }
      final name = personName(l10n, match.displayName);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: InitialsAvatar(name: match.displayName, radius: 26),
          title: Text(l10n.sendFriendRequestTitle(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('sendFriendRequestButton'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.sendRequest),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _loading = true);
      final result = await ref
          .read(friendsServiceProvider)
          .sendRequest(match.userId);
      if (!mounted) return;
      refreshFriends(ref);
      _showSnack(
        result == SendRequestResult.accepted
            ? l10n.nowFriends(name)
            : l10n.friendRequestSent(name),
      );
      Navigator.of(context).pop();
    } on ProfileException catch (e) {
      _showSnack(profileErrorText(l10n, e.code));
    } on FriendsException catch (e) {
      _showSnack(friendsErrorText(l10n, e.code));
    } finally {
      if (mounted) {
        setState(() {
          _busy = _loading = false;
          _lastScan = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = context.nipay.muted;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addFriend)),
      body: SafeArea(
        child: CenteredListView(
          top: 16,
          maxWidth: 480,
          children: [
            if (widget.showCamera) ...[
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: MobileScanner(
                    onDetect: _onScan,
                    errorBuilder: (context, error) => ColoredBox(
                      color: context.nipay.surface2,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.cameraUnavailable,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.scanQrHint,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
            FieldLabel(l10n.enterCodeManually),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('manualFriendCodeField'),
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: moneyStyle(size: 18, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'ABCDE-23456',
                      errorText: _codeError,
                    ),
                    onSubmitted: (_) => _busy ? null : _onManualSubmit(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  key: const Key('findFriendButton'),
                  onPressed: _busy ? null : _onManualSubmit,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.findFriend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
