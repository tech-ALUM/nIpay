import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currencies.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../data/services/exchange_rate_service.dart';
import '../../l10n/app_localizations.dart';

/// Azioni su un portafoglio esistente: rinomina o elimina (soft-delete).
Future<void> showWalletActionsSheet(BuildContext context, Wallet wallet) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _WalletActionsSheet(wallet: wallet),
    );

/// Elimina un portafoglio solo se l'utente digita il suo nome esatto:
/// nessun errore possibile per un tap accidentale. Il nome è comunque
/// suggerito (placeholder + tocca-per-compilare) per non farne un incubo.
Future<void> _confirmWalletDeletion(
  BuildContext context,
  WidgetRef ref,
  Wallet wallet,
) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final matches = controller.text.trim() == wallet.name;
        return AlertDialog(
          title: Text(l10n.deleteWalletTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteWalletBody(wallet.name)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.walletName,
                  hintText: wallet.name,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: matches
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    ),
  );
  if (confirmed == true) {
    await ref.read(walletRepositoryProvider).softDelete(wallet.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _WalletActionsSheet extends ConsumerStatefulWidget {
  const _WalletActionsSheet({required this.wallet});

  final Wallet wallet;

  @override
  ConsumerState<_WalletActionsSheet> createState() =>
      _WalletActionsSheetState();
}

class _WalletActionsSheetState extends ConsumerState<_WalletActionsSheet> {
  late final _controller = TextEditingController(text: widget.wallet.name);
  late String _currency = widget.wallet.currency;
  String? _nameError;
  String? _currencyError;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// "Salva" fa da conferma unica: rinomina e/o cambio valuta insieme (solo
  /// il saldo iniziale del portafoglio si converte — transazioni, budget e
  /// regole ricorrenti restano nei loro importi originali).
  Future<void> _save(Wallet wallet) async {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final wallets = ref.read(walletsProvider).valueOrNull ?? const [];
    final duplicate = wallets.any(
      (w) =>
          w.id != wallet.id && w.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _nameError = l10n.walletNameDuplicate);
      return;
    }

    setState(() {
      _saving = true;
      _currencyError = null;
    });

    double? rate;
    if (_currency != wallet.currency) {
      try {
        rate = await ref
            .read(exchangeRateServiceProvider)
            .getRate(from: wallet.currency, to: _currency);
      } on ExchangeRateException {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _currencyError = l10n.exchangeRateError;
        });
        return;
      }
    }
    if (!mounted) return;

    final repo = ref.read(walletRepositoryProvider);
    if (name != wallet.name) await repo.rename(wallet.id, name);
    if (rate != null) await repo.changeCurrency(wallet.id, _currency, rate);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = widget.wallet;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(wallet.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: l10n.walletName,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('walletActionsCurrencyDropdown'),
            initialValue: _currency,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.currency,
              errorText: _currencyError,
            ),
            items: currencyMenuItems(),
            onChanged: (v) => setState(() {
              _currency = v ?? _currency;
              _currencyError = null;
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.delete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _confirmWalletDeletion(context, ref, wallet),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('walletActionsSaveButton'),
                  onPressed: _saving ? null : () => _save(wallet),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _walletColors = [
  '#0E7C86',
  '#FF6F61',
  '#7C5CBF',
  '#3A4150',
  '#2E9E6B',
  '#E0A800',
];

Future<void> showWalletFormSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _WalletFormSheet(),
    );

class _WalletFormSheet extends ConsumerStatefulWidget {
  const _WalletFormSheet();

  @override
  ConsumerState<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<_WalletFormSheet> {
  final _name = TextEditingController();
  final _balance = TextEditingController();
  String _color = _walletColors.first;
  String _currency = 'EUR';
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.walletNameRequired);
      return;
    }
    final wallets = ref.read(walletsProvider).valueOrNull ?? const [];
    final duplicate = wallets.any(
      (w) => w.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _nameError = l10n.walletNameDuplicate);
      return;
    }
    final cents = parseCents(_balance.text) ?? 0;
    final id = await ref
        .read(walletRepositoryProvider)
        .create(
          name: name,
          colorHex: _color,
          initialBalanceCents: cents,
          currency: _currency,
        );
    // Ogni nuovo portafoglio nasce col set di categorie di default
    // e diventa lo spazio attivo.
    await ref.read(categoryRepositoryProvider).seedDefaults(id);
    ref.read(activeWalletIdProvider.notifier).set(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.newWallet, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            key: const Key('walletNameField'),
            controller: _name,
            autofocus: true,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: l10n.walletName,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('walletBalanceField'),
                  controller: _balance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: moneyInputFormatters,
                  decoration: InputDecoration(labelText: l10n.initialBalance),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 132,
                child: DropdownButtonFormField<String>(
                  key: const Key('walletCurrencyDropdown'),
                  initialValue: _currency,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.currency),
                  items: currencyMenuItems(),
                  onChanged: (v) => setState(() => _currency = v ?? _currency),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final hex in _walletColors)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(
                          0xFF000000 | int.parse(hex.substring(1), radix: 16),
                        ),
                        border: _color == hex
                            ? Border.all(
                                width: 3,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('walletSaveButton'),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}
