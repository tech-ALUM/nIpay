import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

/// Azioni su un portafoglio esistente: rinomina o elimina (soft-delete).
Future<void> showWalletActionsSheet(BuildContext context, Wallet wallet) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _WalletActionsSheet(wallet: wallet),
    );

class _WalletActionsSheet extends ConsumerWidget {
  const _WalletActionsSheet({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: wallet.name);
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
            controller: controller,
            decoration: InputDecoration(labelText: l10n.walletName),
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
                  onPressed: () async {
                    await ref
                        .read(walletRepositoryProvider)
                        .softDelete(wallet.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  child: Text(l10n.save),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      await ref
                          .read(walletRepositoryProvider)
                          .rename(wallet.id, name);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
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

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final cents = parseCents(_balance.text) ?? 0;
    await ref
        .read(walletRepositoryProvider)
        .create(name: name, colorHex: _color, initialBalanceCents: cents);
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
            decoration: InputDecoration(labelText: l10n.walletName),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('walletBalanceField'),
            controller: _balance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.initialBalance,
              suffixText: '€',
            ),
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
