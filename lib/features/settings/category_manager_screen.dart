import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';

class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageCategories)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategorySheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categories.isEmpty
          ? Center(
              child: Text(
                l10n.noItems,
                style: TextStyle(color: context.nipay.muted),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: categories.length,
              // onReorderItem: newIndex è già corretto per l'elemento rimosso.
              onReorderItem: (oldIndex, newIndex) {
                final ids = categories.map((c) => c.id).toList();
                final id = ids.removeAt(oldIndex);
                ids.insert(newIndex, id);
                ref.read(categoryRepositoryProvider).reorder(ids);
              },
              itemBuilder: (context, i) {
                final c = categories[i];
                return ListTile(
                  key: ValueKey(c.id),
                  leading: Text(c.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(c.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    switch (c.kind) {
                      CategoryKind.expense => l10n.expense,
                      CategoryKind.income => l10n.income,
                      CategoryKind.both => l10n.kindBoth,
                    },
                    style: TextStyle(fontSize: 11, color: context.nipay.muted),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _showCategorySheet(context, ref, existing: c),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => ref
                            .read(categoryRepositoryProvider)
                            .softDelete(c.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

const _categoryColors = [
  '#FF6F61',
  '#0E7C86',
  '#7C5CBF',
  '#2E9E6B',
  '#E0A800',
  '#3A4150',
];

Future<void> _showCategorySheet(
  BuildContext context,
  WidgetRef ref, {
  Category? existing,
}) {
  final l10n = AppLocalizations.of(context)!;
  final name = TextEditingController(text: existing?.name ?? '');
  final icon = TextEditingController(text: existing?.icon ?? '');
  var color = existing?.colorHex ?? _categoryColors.first;
  var kind = existing?.kind ?? CategoryKind.expense;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? l10n.newCategory : l10n.editCategory,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.walletName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: icon,
              decoration: InputDecoration(labelText: l10n.icon),
            ),
            const SizedBox(height: 12),
            if (existing == null)
              SegmentedButton<CategoryKind>(
                segments: [
                  ButtonSegment(
                    value: CategoryKind.expense,
                    label: Text(l10n.expense),
                  ),
                  ButtonSegment(
                    value: CategoryKind.income,
                    label: Text(l10n.income),
                  ),
                  ButtonSegment(
                    value: CategoryKind.both,
                    label: Text(l10n.kindBoth),
                  ),
                ],
                selected: {kind},
                onSelectionChanged: (s) => setState(() => kind = s.first),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final hex in _categoryColors)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => color = hex),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(
                            0xFF000000 | int.parse(hex.substring(1), radix: 16),
                          ),
                          border: color == hex
                              ? Border.all(
                                  width: 3,
                                  color: Theme.of(
                                    sheetContext,
                                  ).colorScheme.onSurface,
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
                child: Text(l10n.save),
                onPressed: () async {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  final i = icon.text.trim().isEmpty ? '📦' : icon.text.trim();
                  final repo = ref.read(categoryRepositoryProvider);
                  if (existing == null) {
                    await repo.create(
                      name: n,
                      icon: i,
                      colorHex: color,
                      kind: kind,
                    );
                  } else {
                    await repo.update(
                      existing.id,
                      name: n,
                      icon: i,
                      colorHex: color,
                    );
                  }
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
