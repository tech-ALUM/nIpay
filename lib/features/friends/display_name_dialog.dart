import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/validation.dart';
import '../../data/services/profile_service.dart';
import '../../l10n/app_localizations.dart';

/// Testo per l'utente di un errore del profilo (mai il messaggio del
/// server, SECURITY_AUDIT NIP-17).
String profileErrorText(AppLocalizations l10n, ProfileErrorCode code) =>
    switch (code) {
      ProfileErrorCode.invalidDisplayName => l10n.displayNameInvalid,
      ProfileErrorCode.rateLimited => l10n.authErrorRateLimited,
      ProfileErrorCode.network => l10n.authErrorNetwork,
      ProfileErrorCode.unknown => l10n.authErrorGeneric,
    };

/// "Come ti chiami?": sceglie o cambia il nome visualizzato agli amici.
/// Restituisce il nome salvato dal server, o null se annullato. Usato da
/// Account e, in M-SOC2, alla prima apertura di Amici.
Future<String?> showDisplayNameDialog(
  BuildContext context, {
  String? initialName,
}) => showDialog<String>(
  context: context,
  builder: (_) => _DisplayNameDialog(initialName: initialName),
);

class _DisplayNameDialog extends ConsumerStatefulWidget {
  const _DisplayNameDialog({this.initialName});

  final String? initialName;

  @override
  ConsumerState<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends ConsumerState<_DisplayNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    // Stesse regole del server: un nome rifiutato qui non parte nemmeno.
    final name = normalizeDisplayName(_controller.text);
    if (name == null) {
      setState(() => _error = l10n.displayNameInvalid);
      return;
    }
    setState(() {
      _error = null;
      _isSaving = true;
    });
    try {
      final saved = await ref.read(profileServiceProvider).setDisplayName(name);
      if (mounted) Navigator.of(context).pop(saved);
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = profileErrorText(l10n, e.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.displayNameDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.displayNameHelp),
          const SizedBox(height: 16),
          TextField(
            key: const Key('displayNameField'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: kMaxDisplayNameLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.displayName,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('displayNameSaveButton'),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
