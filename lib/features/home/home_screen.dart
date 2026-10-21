import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
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
    final recent = ref.watch(recentTransactionsProvider).valueOrNull ?? [];
    final signedInUser = ref.watch(authStateProvider).valueOrNull;

    // Ordine e spaziature pensati perché saldo, portafogli e le prime
    // transazioni recenti stiano nella prima schermata di un telefono.
    final sections = <Widget>[
      if (signedInUser != null) ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _SignedInBadge(email: signedInUser.email ?? ''),
        ),
        const SizedBox(height: 12),
      ],
      const _BalanceHero(),
      SectionHeader(
        l10n.wallets,
        action: TextButton.icon(
          key: const Key('addWalletButton'),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          onPressed: () => showWalletFormSheet(context),
          icon: const Icon(Icons.add, size: 20),
          label: Text(l10n.newWallet),
        ),
      ),
      if (wallets.isEmpty)
        _Raised(
          child: Card(
            child: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: l10n.noWallets,
            ),
          ),
        )
      else
        _WalletStrip(wallets: wallets),
      const SizedBox(height: 12),
      const _ExpenseReportCard(),
      ..._buildBudgetSection(context, ref, l10n),
      SectionHeader(l10n.recentTransactions),
      _Raised(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: recent.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: l10n.noTransactions,
                )
              : Column(
                  children: [
                    for (final (i, tx) in recent.take(10).indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      TransactionTile(transaction: tx),
                    ],
                  ],
                ),
        ),
      ),
    ];

    return AuroraBackdrop(
      child: SafeArea(
        child: CenteredListView(
          top: 12,
          children: [
            // Ingresso a cascata: ogni blocco entra poco dopo il precedente.
            for (final (i, section) in sections.indexed)
              FadeSlideIn(index: i, child: section),
          ],
        ),
      ),
    );
  }
}

/// Card in rilievo (ombra del tema) per i blocchi non toccabili per intero;
/// quelli toccabili usano [Pressable], che aggiunge il feedback al tocco.
class _Raised extends StatelessWidget {
  const _Raised({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: context.nipay.cardShadow,
    ),
    child: child,
  );
}

/// Banda "ink" con il saldo dello spazio attivo e il riepilogo del mese.
class _BalanceHero extends ConsumerWidget {
  const _BalanceHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final active = ref.watch(activeWalletProvider);
    final currency = active?.currency ?? 'EUR';
    final total = ref.watch(totalBalanceProvider).valueOrNull;
    final monthTotals = ref.watch(monthTotalsProvider).valueOrNull;

    final balanceStyle = moneyStyle(
      size: 44,
      weight: FontWeight.w700,
      color: palette.onHero,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.totalBalance}${active != null ? ' · ${active.name}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: palette.onHeroMuted),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: total == null
                    ? Text('…', style: balanceStyle)
                    // Il saldo scorre fino al valore; agli screen reader
                    // arriva sempre e solo quello finale.
                    : AnimatedCount(
                        value: total,
                        builder: (context, shown) => Text(
                          formatCents(shown, currency: currency),
                          semanticsLabel: formatCents(
                            total,
                            currency: currency,
                          ),
                          style: balanceStyle,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (monthTotals != null) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeroKpi(
                icon: Icons.south_west_rounded,
                label: l10n.income,
                value: formatCents(monthTotals.incomeCents, currency: currency),
                color: NipayColors.tealLight,
              ),
              _HeroKpi(
                icon: Icons.north_east_rounded,
                label: l10n.expense,
                value: formatCents(
                  monthTotals.expenseCents,
                  currency: currency,
                ),
                color: NipayColors.coralLight,
              ),
              Text(
                l10n.thisMonth,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.onHeroMuted),
              ),
            ],
          ),
        ],
      ],
    );

    // Mesh scuro con due bagliori del brand dentro la card: la "profondità"
    // di Ink Aurora. I bagliori sono decorativi (fuori dalla semantica).
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: palette.raisedShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: palette.heroGradient,
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              const PositionedDirectional(
                top: -70,
                end: -50,
                child: _HeroGlow(color: NipayColors.coral, size: 200),
              ),
              const PositionedDirectional(
                bottom: -90,
                start: -40,
                child: _HeroGlow(color: NipayColors.cyan, size: 220),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bagliore radiale dentro la banda saldo: decorativo, non tocca i tocchi.
class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .42), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

/// Entrate/uscite del mese nella banda saldo: freccia e colore indicano il
/// verso, l'etichetta completa arriva agli screen reader.
class _HeroKpi extends StatelessWidget {
  const _HeroKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(5, 5, 12, 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 7),
            Text(value, style: moneyStyle(size: 14.5, color: color)),
          ],
        ),
      ),
    ),
  );
}

/// Card portafogli orizzontali: tap = attiva lo spazio, pressione lunga =
/// trascina per riordinare, matita = foglio azioni.
class _WalletStrip extends ConsumerWidget {
  const _WalletStrip({required this.wallets});

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // L'altezza cresce col testo ingrandito dalle impostazioni di sistema.
    final height = MediaQuery.textScalerOf(
      context,
    ).scale(122).clamp(122.0, 190.0);
    return SizedBox(
      height: height,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        // Di default, durante il trascinamento Flutter avvolge l'elemento in
        // un Material bianco pieno slot (padding incluso), più largo della
        // card arrotondata sotto: qui lo rendiamo trasparente così si vede
        // solo la card che si sta spostando.
        proxyDecorator: (child, index, animation) =>
            Material(color: Colors.transparent, child: child),
        itemCount: wallets.length,
        onReorderItem: (oldIndex, newIndex) => ref
            .read(walletRepositoryProvider)
            .move(wallets[oldIndex].id, newIndex),
        itemBuilder: (context, i) => Padding(
          key: ValueKey(wallets[i].id),
          padding: const EdgeInsetsDirectional.only(end: 10),
          child: _WalletCard(wallet: wallets[i], index: i),
        ),
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
  void openManager() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const BudgetManagerScreen()));

  return [
    SectionHeader(
      l10n.budgets,
      action: TextButton(onPressed: openManager, child: Text(l10n.edit)),
    ),
    Pressable(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openManager,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final (i, b) in budgets.indexed) ...[
                  if (i > 0) const SizedBox(height: 16),
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
    ),
  ];
}

class _ExpenseReportCard extends ConsumerWidget {
  const _ExpenseReportCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final pending = ref.watch(pendingReimbursementProvider).valueOrNull ?? 0;
    return Pressable(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('expenseReportCard'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpenseReportScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Row(
              children: [
                IconBadge(icon: Icons.receipt_long, color: palette.income),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.expenseReport,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        l10n.pendingReimbursement,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCents(pending, currency: currency),
                  style: moneyStyle(size: 16, color: palette.income),
                ),
                const SizedBox(width: 4),
                ExcludeSemantics(
                  child: Icon(Icons.chevron_right, color: palette.muted),
                ),
              ],
            ),
          ),
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
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    return Semantics(
      button: true,
      label: l10n.signedInAs(email),
      excludeSemantics: true,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    email.isEmpty ? '?' : email[0].toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
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
    final l10n = AppLocalizations.of(context)!;
    final balance = ref.watch(walletBalanceProvider(wallet.id)).valueOrNull;
    final base = colorFromHex(wallet.colorHex);
    // Testo ink o bianco in base al colore scelto: leggibile su ogni card.
    final fg = foregroundOn(base);
    final lightText = fg == NipayColors.textDark;
    final isActive = ref.watch(activeWalletProvider)?.id == wallet.id;
    final radius = BorderRadius.circular(20);

    // Tenendo premuto si trascina per riordinare (l'intera card diventa la
    // maniglia); un tap semplice attiva il portafoglio; il bottone edit in
    // alto a destra apre il foglio azioni (rinomina/valuta/elimina).
    // Ombra tinta del colore del portafoglio; quello attivo ha anche un
    // anello e un bagliore più intenso, animati al cambio di spazio.
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Semantics(
        selected: isActive,
        child: Pressable(
          borderRadius: BorderRadius.circular(24),
          shadow: const [],
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.emphasized,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: base.withValues(alpha: isActive ? .55 : .28),
                  blurRadius: isActive ? 24 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                width: 164,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: lightText
                        ? [base, _shade(base, -.10)]
                        : [_shade(base, .06), base],
                  ),
                ),
                child: InkWell(
                  onTap: () =>
                      ref.read(activeWalletIdProvider.notifier).set(wallet.id),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 2, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isActive) ...[
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: fg,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                wallet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: fg,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              key: const Key('walletEditButton'),
                              tooltip: l10n.edit,
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              color: fg,
                              onPressed: () =>
                                  showWalletActionsSheet(context, wallet),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
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
                                style: moneyStyle(
                                  size: 22,
                                  weight: FontWeight.w700,
                                  color: fg,
                                ),
                              ),
                              if (balance != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  wallet.currency,
                                  style: moneyStyle(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: fg.withValues(alpha: .8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Schiarisce (amount > 0) o scurisce (amount < 0) un colore in HSL.
Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}
