import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../core/validation.dart';
import '../../data/db/app_database.dart';
import '../../data/services/exchange_rate_service.dart';
import '../../l10n/app_localizations.dart';

/// Azioni su un portafoglio esistente: rinomina, colore, valuta o elimina
/// (soft-delete).
Future<void> showWalletActionsSheet(BuildContext context, Wallet wallet) =>
    showAppSheet<void>(
      context,
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
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: Text(l10n.deleteWalletTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteWalletBody(wallet.name)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kMaxNameLength),
                ],
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
              style: destructiveButtonStyle(dialogContext),
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
  late String _color = widget.wallet.colorHex;
  String? _nameError;
  String? _currencyError;
  bool _saving = false;

  /// Tasso valuta attuale → [_currency], per l'anteprima del saldo
  /// convertito; null finché non arriva (o se la valuta non cambia).
  double? _rate;
  bool _fetchingRate = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Scelta una nuova valuta, recupera subito il tasso: l'anteprima mostra
  /// il saldo convertito prima di salvare.
  Future<void> _onCurrencyChanged(String currency) async {
    final l10n = AppLocalizations.of(context)!;
    final from = widget.wallet.currency;
    setState(() {
      _currency = currency;
      _currencyError = null;
      _rate = null;
      _fetchingRate = currency != from;
    });
    if (currency == from) return;
    try {
      final rate = await ref
          .read(exchangeRateServiceProvider)
          .getRate(from: from, to: currency);
      // Nel frattempo potrebbe essere stata scelta un'altra valuta.
      if (!mounted || _currency != currency) return;
      setState(() {
        _rate = rate;
        _fetchingRate = false;
      });
    } on ExchangeRateException {
      if (!mounted || _currency != currency) return;
      setState(() {
        _fetchingRate = false;
        _currencyError = l10n.exchangeRateError;
      });
    }
  }

  /// "Salva" fa da conferma unica: rinomina, colore e/o cambio valuta
  /// insieme. Col cambio valuta si converte tutto il portafoglio (saldo,
  /// movimenti, budget, ricorrenti), vedi [WalletRepository.changeCurrency].
  Future<void> _save(Wallet wallet) async {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final wallets = ref.read(walletsProvider).valueOrNull ?? const [];
    final duplicate = wallets.any(
      (w) =>
          w.id != wallet.id &&
          w.name.trim().toLowerCase() == name.toLowerCase(),
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
      rate = _rate;
    }
    if (_currency != wallet.currency && rate == null) {
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
    if (_color != wallet.colorHex) await repo.recolor(wallet.id, _color);
    if (rate != null) await repo.changeCurrency(wallet.id, _currency, rate);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = widget.wallet;
    return SheetScaffold(
      title: wallet.name,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, size: 20),
          label: Text(l10n.delete),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _confirmWalletDeletion(context, ref, wallet),
        ),
        FilledButton(
          key: const Key('walletActionsSaveButton'),
          onPressed: _saving ? null : () => _save(wallet),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
      children: [
        TextField(
          controller: _controller,
          inputFormatters: [LengthLimitingTextInputFormatter(kMaxNameLength)],
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          decoration: InputDecoration(
            labelText: l10n.walletName,
            errorText: _nameError,
          ),
        ),
        kFieldGap,
        CurrencyField(
          key: const Key('walletActionsCurrencyDropdown'),
          value: _currency,
          errorText: _currencyError,
          prefixIcon: Icons.currency_exchange,
          onChanged: _onCurrencyChanged,
        ),
        if (_currency != wallet.currency && _currencyError == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: _fetchingRate
                ? const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _ConvertedBalancePreview(
                    wallet: wallet,
                    currency: _currency,
                    rate: _rate,
                  ),
          ),
        FieldLabel(l10n.color),
        ColorChoiceRow(
          // Un colore arrivato da fuori palette (es. da un altro device) resta
          // selezionabile.
          colors: [
            if (!_walletColors.contains(widget.wallet.colorHex))
              widget.wallet.colorHex,
            ..._walletColors,
          ],
          selected: _color,
          onSelected: (hex) => setState(() => _color = hex),
        ),
      ],
    );
  }
}

/// "≈ 1.100,00 USD al cambio attuale": il saldo del portafoglio come sarà
/// dopo il cambio valuta.
class _ConvertedBalancePreview extends ConsumerWidget {
  const _ConvertedBalancePreview({
    required this.wallet,
    required this.currency,
    required this.rate,
  });

  final Wallet wallet;
  final String currency;
  final double? rate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider(wallet.id)).valueOrNull;
    if (rate == null || balance == null) return const SizedBox.shrink();
    final muted = context.nipay.muted;
    return Row(
      children: [
        Icon(Icons.currency_exchange, size: 16, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.convertedPreview(
              formatCents((balance * rate!).round(), currency: currency),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
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

/// Le transazioni (anche ricorrenti) appartengono sempre a un portafoglio:
/// senza portafogli, al posto del form compare un errore con l'azione per
/// crearne uno. Torna true se si può procedere.
bool requireWallet(BuildContext context, WidgetRef ref) {
  final wallets = ref.read(walletsProvider).valueOrNull;
  if (wallets == null || wallets.isNotEmpty) return true;
  final l10n = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: scheme.error,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.noWalletForTransaction,
                style: TextStyle(
                  color: scheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: l10n.newWallet,
          textColor: scheme.onError,
          onPressed: () => showWalletFormSheet(context),
        ),
      ),
    );
  return false;
}

Future<void> showWalletFormSheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _WalletFormSheet());

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
    return SheetScaffold(
      title: l10n.newWallet,
      actions: [
        FilledButton(
          key: const Key('walletSaveButton'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
      children: [
        TextField(
          key: const Key('walletNameField'),
          controller: _name,
          inputFormatters: [LengthLimitingTextInputFormatter(kMaxNameLength)],
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          decoration: InputDecoration(
            labelText: l10n.walletName,
            errorText: _nameError,
          ),
        ),
        kFieldGap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('walletBalanceField'),
                controller: _balance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: moneyInputFormatters,
                style: moneyStyle(size: 18),
                decoration: InputDecoration(labelText: l10n.initialBalance),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 140,
              child: CurrencyField(
                key: const Key('walletCurrencyDropdown'),
                value: _currency,
                onChanged: (v) => setState(() => _currency = v),
              ),
            ),
          ],
        ),
        FieldLabel(l10n.color),
        ColorChoiceRow(
          colors: _walletColors,
          selected: _color,
          onSelected: (hex) => setState(() => _color = hex),
        ),
      ],
    );
  }
}
