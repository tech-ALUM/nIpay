import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
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
  String _query = '';
  Set<String> _categoryIds = {};
  Set<String> _tagIds = {};

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
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

    final monthLabel = '${_monthNames[_month.month - 1]} ${_month.year}';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionsTab,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchTransactions,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MultiFilterDropdown<String>(
                        title: l10n.category,
                        selected: _categoryIds,
                        nullLabel: l10n.allCategories,
                        items: [
                          for (final c
                              in ref.watch(categoriesProvider).valueOrNull ??
                                  const <Category>[])
                            (c.id, '${c.icon} ${c.name}'),
                        ],
                        onChanged: (v) => setState(() => _categoryIds = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MultiFilterDropdown<String>(
                        title: l10n.tags,
                        selected: _tagIds,
                        nullLabel: l10n.allTags,
                        items: [
                          for (final t
                              in ref.watch(tagsProvider).valueOrNull ??
                                  const <Tag>[])
                            (t.id, '#${t.name}'),
                        ],
                        onChanged: (v) => setState(() => _tagIds = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          monthLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: days.isEmpty
                ? Center(
                    child: Text(
                      l10n.noTransactions,
                      style: TextStyle(color: palette.muted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    children: [
                      for (final day in days) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${day.day} ${_monthNames[day.month - 1]}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                              ),
                              Text(
                                formatCents(
                                  _dayNet(byDay[day]!),
                                  currency: currency,
                                  signed: true,
                                ),
                                style: moneyStyle(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final (i, t) in byDay[day]!.indexed) ...[
                                if (i > 0) const Divider(),
                                TransactionTile(transaction: t),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Filtro compatto multi-selezione: mostra [nullLabel] quando nulla è
/// selezionato, altrimenti i nomi scelti; tocca per aprire il selettore.
class _MultiFilterDropdown<T> extends StatelessWidget {
  const _MultiFilterDropdown({
    required this.title,
    required this.selected,
    required this.nullLabel,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final Set<T> selected;
  final String nullLabel;
  final List<(T, String)> items;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = selected.isEmpty
        ? nullLabel
        : items
              .where((e) => selected.contains(e.$1))
              .map((e) => e.$2)
              .join(', ');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await showModalBottomSheet<Set<T>>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _MultiSelectSheet<T>(
            title: title,
            items: items,
            selected: selected,
          ),
        );
        if (result != null) onChanged(result);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: Text(l10n.none),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (value, label) in widget.items)
                    CheckboxListTile(
                      value: _selected.contains(value),
                      title: Text(label),
                      onChanged: (checked) => setState(
                        () => (checked ?? false)
                            ? _selected.add(value)
                            : _selected.remove(value),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text(l10n.apply),
                ),
              ),
            ),
          ],
        ),
      ),
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

const _monthNames = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];
