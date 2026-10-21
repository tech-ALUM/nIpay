import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../core/validation.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCategory),
      ),
      body: categories.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.category_outlined,
                message: l10n.noItems,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) => ReorderableListView.builder(
                padding: centeredPadding(
                  constraints.maxWidth,
                  top: 8,
                  bottom: kFabClearance,
                ),
                buildDefaultDragHandles: false,
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
                  return Padding(
                    key: ValueKey(c.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    // Pressione lunga ovunque o trascinamento dalla maniglia.
                    child: ReorderableDelayedDragStartListener(
                      index: i,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: 14,
                            end: 4,
                          ),
                          leading: IconBadge(
                            emoji: c.icon,
                            color: colorFromHex(c.colorHex),
                          ),
                          title: Text(c.displayName(l10n)),
                          subtitle: Text(switch (c.kind) {
                            CategoryKind.expense => l10n.expense,
                            CategoryKind.income => l10n.income,
                            CategoryKind.both => l10n.kindBoth,
                          }),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.edit,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showCategorySheet(
                                  context,
                                  ref,
                                  existing: c,
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.delete,
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () async {
                                  final confirmed = await confirmDeletion(
                                    context,
                                    title: l10n.deleteItemTitle(
                                      c.displayName(l10n),
                                    ),
                                  );
                                  if (!confirmed) return;
                                  await ref
                                      .read(categoryRepositoryProvider)
                                      .softDelete(c.id);
                                },
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: ExcludeSemantics(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: context.nipay.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
  // Le categorie di default si mostrano (e si modificano) nella lingua
  // attiva: se il nome tradotto non viene toccato, resta quello del seed e
  // continua a seguire la lingua.
  final shownName = existing?.displayName(l10n) ?? '';
  final name = TextEditingController(text: shownName);
  final icon = TextEditingController(text: existing?.icon ?? '');
  var color = existing?.colorHex ?? _categoryColors.first;
  var kind = existing?.kind ?? CategoryKind.expense;
  String? nameError;

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) => SheetScaffold(
        title: existing == null ? l10n.newCategory : l10n.editCategory,
        actions: [
          FilledButton(
            onPressed: () async {
              final typed = name.text.trim();
              if (typed.isEmpty) {
                setState(() => nameError = l10n.fieldRequired);
                return;
              }
              final n = existing != null && typed == shownName
                  ? existing.name
                  : typed;
              final i = icon.text.trim().isEmpty ? '📦' : icon.text.trim();
              final repo = ref.read(categoryRepositoryProvider);
              final active = ref.read(activeWalletProvider);
              if (existing == null) {
                if (active == null) return;
                await repo.create(
                  walletId: active.id,
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
            child: Text(l10n.save),
          ),
        ],
        children: [
          TextField(
            controller: name,
            inputFormatters: [LengthLimitingTextInputFormatter(kMaxNameLength)],
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (nameError != null) setState(() => nameError = null);
            },
            decoration: InputDecoration(
              labelText: l10n.walletName,
              errorText: nameError,
            ),
          ),
          kFieldGap,
          TextField(
            controller: icon,
            inputFormatters: [LengthLimitingTextInputFormatter(kMaxIconLength)],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.icon,
              // Anteprima di come apparirà la categoria nelle liste.
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8),
                child: IconBadge(
                  emoji: icon.text.trim().isEmpty ? '📦' : icon.text.trim(),
                  color: colorFromHex(color),
                  size: 32,
                ),
              ),
            ),
          ),
          if (existing == null) ...[
            FieldLabel(l10n.fieldType),
            SegmentedButton<CategoryKind>(
              showSelectedIcon: false,
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
          ],
          FieldLabel(l10n.color),
          ColorChoiceRow(
            colors: _categoryColors,
            selected: color,
            onSelected: (hex) => setState(() => color = hex),
          ),
        ],
      ),
    ),
  );
}
