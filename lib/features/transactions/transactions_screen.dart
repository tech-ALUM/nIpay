import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';
import 'transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _search = TextEditingController();
  String _query = '';
  Set<String> _categoryIds = {};
  Set<String> _tagIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final loc = MaterialLocalizations.of(context);
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    // MVP: filtro client-side sulle ultime transazioni; query dedicata in M6.
    final all =
        ref.watch(recentTransactionsProvider).valueOrNull ??
        const <Transaction>[];
    // Una transazione passa il filtro tag se ha ALMENO UNO dei tag selezionati.
    Set<String>? tagFilterIds;
    if (_tagIds.isNotEmpty) {
      tagFilterIds = {
        for (final id in _tagIds)
          ...ref.watch(txIdsWithTagProvider(id)).valueOrNull ?? const {},
      };
    }
    // La ricerca guarda anche i valori dei campi custom.
    final fieldMatchIds = _query.isEmpty
        ? const <String>{}
        : ref.watch(txIdsMatchingFieldProvider(_query)).valueOrNull ??
              const <String>{};

    final inMonth = all.where(
      (t) =>
          t.date.year == _month.year &&
          t.date.month == _month.month &&
          (_categoryIds.isEmpty || _categoryIds.contains(t.categoryId)) &&
          (tagFilterIds == null || tagFilterIds.contains(t.id)) &&
          (_query.isEmpty ||
              t.description.toLowerCase().contains(_query.toLowerCase()) ||
              fieldMatchIds.contains(t.id)),
    );

    // Raggruppa per giorno, più recente prima.
    final byDay = <DateTime, List<Transaction>>{};
    for (final t in inMonth) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      byDay.putIfAbsent(day, () => []).add(t);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: CenteredListView(
        top: 0,
        children: [
          PageHeader(l10n.transactionsTab),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchTransactions,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: loc.clearButtonTooltip,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MultiFilterDropdown<String>(
                  icon: Icons.category_outlined,
                  title: l10n.category,
                  selected: _categoryIds,
                  nullLabel: l10n.allCategories,
                  items: [
                    for (final c
                        in ref.watch(categoriesProvider).valueOrNull ??
                            const <Category>[])
                      (c.id, c.label(l10n)),
                  ],
                  onChanged: (v) => setState(() => _categoryIds = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MultiFilterDropdown<String>(
                  icon: Icons.sell_outlined,
                  title: l10n.tags,
                  selected: _tagIds,
                  nullLabel: l10n.allTags,
                  items: [
                    for (final t
                        in ref.watch(tagsProvider).valueOrNull ?? const <Tag>[])
                      (t.id, '#${t.name}'),
                  ],
                  onChanged: (v) => setState(() => _tagIds = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: MonthSwitcher(
              month: _month,
              onChanged: (m) => setState(() => _month = m),
            ),
          ),
          if (days.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              message: l10n.noTransactions,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            )
          else
            for (final day in days) ...[
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            loc.formatMediumDate(day),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Text(
                        formatCents(
                          _dayNet(byDay[day]!),
                          currency: currency,
                          signed: true,
                        ),
                        style: moneyStyle(
                          size: 13,
                          weight: FontWeight.w600,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, t) in byDay[day]!.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      TransactionTile(transaction: t),
                    ],
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Filtro compatto multi-selezione: mostra [nullLabel] quando nulla è
/// selezionato, altrimenti i nomi scelti; tocca per aprire il selettore.
/// Quando è attivo cambia sfondo e bordo, così si vede a colpo d'occhio
/// che la lista è filtrata.
class _MultiFilterDropdown<T> extends StatelessWidget {
  const _MultiFilterDropdown({
    required this.icon,
    required this.title,
    required this.selected,
    required this.nullLabel,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final Set<T> selected;
  final String nullLabel;
  final List<(T, String)> items;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = selected.isNotEmpty;
    final label = active
        ? items
              .where((e) => selected.contains(e.$1))
              .map((e) => e.$2)
              .join(', ')
        : nullLabel;
    final fg = active ? scheme.onSecondaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      label: '$title: $label',
      excludeSemantics: true,
      child: Material(
        color: active ? scheme.secondaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: active ? scheme.primary : scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final result = await showAppSheet<Set<T>>(
              context,
              builder: (_) => _MultiSelectSheet<T>(
                title: title,
                items: items,
                selected: selected,
              ),
            );
            if (result != null) onChanged(result);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more, size: 20, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiSelectSheet<T> extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.items,
    required this.selected,
  });

  final String title;
  final List<(T, String)> items;
  final Set<T> selected;

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late final Set<T> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SheetScaffold(
      title: widget.title,
      actions: [
        OutlinedButton(
          onPressed: _selected.isEmpty
              ? null
              : () => setState(() => _selected.clear()),
          child: Text(l10n.none),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.apply),
        ),
      ],
      children: [
        if (widget.items.isEmpty)
          EmptyState(icon: Icons.inbox_outlined, message: l10n.noItems),
        for (final (value, label) in widget.items)
          CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            value: _selected.contains(value),
            title: Text(label),
            onChanged: (checked) => setState(
              () => (checked ?? false)
                  ? _selected.add(value)
                  : _selected.remove(value),
            ),
          ),
      ],
    );
  }
}

int _dayNet(List<Transaction> txs) {
  var net = 0;
  for (final t in txs) {
    if (t.type == TransactionType.expense) net -= t.amountCents;
    if (t.type == TransactionType.income) net += t.amountCents;
  }
  return net;
}
