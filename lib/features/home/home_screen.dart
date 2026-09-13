import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import '../budgets/budget_manager_screen.dart';
import '../budgets/budget_progress_bar.dart';
import '../expense_report/expense_report_screen.dart';
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
    final activeCurrency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final signedInUser = ref.watch(authStateProvider).valueOrNull;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          if (signedInUser != null) ...[
            _SignedInBadge(email: signedInUser.email ?? ''),
            const SizedBox(height: 12),
          ],
          Text(
            '${l10n.totalBalance}${ref.watch(activeWalletProvider) != null ? ' · ${ref.watch(activeWalletProvider)!.name}' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            total == null ? '…' : formatCents(total, currency: activeCurrency),
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
                      '${formatCents(monthTotals.incomeCents, currency: activeCurrency, signed: true)} · '
                      '${formatCents(-monthTotals.expenseCents, currency: activeCurrency)} ${l10n.thisMonth}',
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.wallets, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: wallets.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              l10n.noWallets,
                              style: TextStyle(color: palette.muted),
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          buildDefaultDragHandles: false,
                          // Di default, durante il trascinamento Flutter
                          // avvolge l'elemento in un Material bianco pieno
                          // slot (padding incluso), più largo della card
                          // arrotondata sotto: qui lo rendiamo trasparente
                          // così si vede solo la card che si sta spostando.
                          proxyDecorator: (child, index, animation) =>
                              Material(color: Colors.transparent, child: child),
                          itemCount: wallets.length,
                          onReorderItem: (oldIndex, newIndex) => ref
                              .read(walletRepositoryProvider)
                              .move(wallets[oldIndex].id, newIndex),
                          itemBuilder: (context, i) => Padding(
                            key: ValueKey(wallets[i].id),
                            padding: const EdgeInsets.only(right: 12),
                            child: _WalletCard(wallet: wallets[i], index: i),
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                const _AddWalletButton(),
              ],
            ),
          ),
          ..._buildBudgetSection(context, ref, l10n),
          const SizedBox(height: 24),
          Text(
            l10n.expenseReport,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            key: const Key('expenseReportCard'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseReportScreen()),
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.pendingReimbursement,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      formatCents(
                        ref.watch(pendingReimbursementProvider).valueOrNull ??
                            0,
                        currency: activeCurrency,
                      ),
                      style: moneyStyle(size: 15, color: palette.income),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, size: 18, color: palette.muted),
                  ],
                ),
              ),
            ),
          ),
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

class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton();

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('addWalletButton'),
    onPressed: () => showWalletFormSheet(context),
    icon: const Icon(Icons.add_circle_outline),
    color: NipayColors.coral,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
    visualDensity: VisualDensity.compact,
  );
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

/// Promemoria visivo di chi ha fatto accesso — l'app resta usabile in
/// locale senza account, quindi questo compare solo quando ce n'è uno,
/// non un banner permanente da dover ignorare.
class _SignedInBadge extends StatelessWidget {
  const _SignedInBadge({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              email,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends ConsumerWidget {
  const _WalletCard({required this.wallet, required this.index});

  final Wallet wallet;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider(wallet.id)).valueOrNull;
    final base = _parseHex(wallet.colorHex);
    final isActive = ref.watch(activeWalletProvider)?.id == wallet.id;

    // Tenendo premuto si trascina per riordinare (l'intera card diventa la
    // maniglia); un tap semplice attiva il portafoglio; il bottone edit in
    // alto a destra apre il foglio azioni (rinomina/valuta/elimina).
    return ReorderableDelayedDragStartListener(
      index: index,
      child: GestureDetector(
        onTap: () => ref.read(activeWalletIdProvider.notifier).set(wallet.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2.5,
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: isActive ? 1 : .55),
                _darken(base).withValues(alpha: isActive ? 1 : .55),
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: .9),
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          balance == null
                              ? '…'
                              : formatCents(
                                  balance,
                                  currency: wallet.currency,
                                  symbolOnly: true,
                                ),
                          maxLines: 1,
                          style: moneyStyle(size: 19, color: Colors.white),
                        ),
                        if (balance != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              wallet.currency,
                              style: moneyStyle(
                                size: 9,
                                weight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: .7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  key: const Key('walletEditButton'),
                  onTap: () => showWalletActionsSheet(context, wallet),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: .8),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
