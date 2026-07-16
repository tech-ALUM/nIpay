import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../budgets/budget_manager_screen.dart';
import '../budgets/budget_progress_bar.dart';
import '../transactions/transaction_tile.dart';
import '../wallets/wallet_form_sheet.dart'
    show showWalletActionsSheet, showWalletFormSheet;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    final total = ref.watch(totalBalanceProvider).valueOrNull;
    final monthTotals = ref.watch(monthTotalsProvider).valueOrNull;
    final recent = ref.watch(recentTransactionsProvider).valueOrNull ?? [];
    final palette = context.nipay;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          Text(l10n.totalBalance, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            total == null ? '…' : formatCents(total),
            style: moneyStyle(
              size: 40,
              weight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (monthTotals != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _DeltaChip(
                  text:
                      '${formatCents(monthTotals.incomeCents, signed: true)} · '
                      '${formatCents(-monthTotals.expenseCents)} ${l10n.thisMonth}',
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.wallets,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const Key('addWalletButton'),
                onPressed: () => showWalletFormSheet(context),
                icon: const Icon(Icons.add_circle_outline),
                color: NipayColors.coral,
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (wallets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.noWallets,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _WalletCard(wallet: wallets[i]),
              ),
            ),
          ..._buildBudgetSection(context, ref, l10n),
          const SizedBox(height: 24),
          Text(
            l10n.recentTransactions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.noTransactions,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, tx) in recent.take(10).indexed) ...[
                    if (i > 0) const Divider(),
                    TransactionTile(transaction: tx),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sezione "Budget" della home: barre di avanzamento del mese corrente.
/// Nascosta finché non esiste almeno un budget; tap → manager.
List<Widget> _buildBudgetSection(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
  final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <Budget>[];
  if (budgets.isEmpty) return const [];
  final categories =
      ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

  return [
    const SizedBox(height: 24),
    Text(l10n.budgets, style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 10),
    GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BudgetManagerScreen())),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (final (i, b) in budgets.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                BudgetProgressBar(
                  budget: b,
                  category: categories
                      .where((c) => c.id == b.categoryId)
                      .firstOrNull,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  ];
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.nipay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: palette.income.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: moneyStyle(
          size: 12,
          weight: FontWeight.w500,
          color: palette.income,
        ),
      ),
    );
  }
}

class _WalletCard extends ConsumerWidget {
  const _WalletCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider(wallet.id)).valueOrNull;
    final base = _parseHex(wallet.colorHex);

    return GestureDetector(
      onLongPress: () => showWalletActionsSheet(context, wallet),
      child: Container(
        width: 158,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base.withValues(alpha: .92), _darken(base)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wallet.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: .9),
              ),
            ),
            const Spacer(),
            Text(
              balance == null ? '…' : formatCents(balance),
              style: moneyStyle(size: 19, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseHex(String hex) {
  final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xFF6F61;
  return Color(0xFF000000 | v);
}

Color _darken(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - .18).clamp(0.0, 1.0)).toColor();
}
