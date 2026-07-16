import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/custom_field_repository.dart';
import '../../l10n/app_localizations.dart';

class CustomFieldManagerScreen extends ConsumerWidget {
  const CustomFieldManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final defs =
        ref.watch(customFieldDefsProvider).valueOrNull ??
        const <CustomFieldDef>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageCustomFields)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFieldSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: defs.isEmpty
          ? Center(
              child: Text(
                l10n.noItems,
                style: TextStyle(color: context.nipay.muted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                for (final d in defs)
                  ListTile(
                    title: Text(d.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _typeLabel(l10n, d.type) +
                          (d.options == null
                              ? ''
                              : ' · ${d.options!.join(", ")}'),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.nipay.muted,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () async {
                        await ref
                            .read(customFieldRepositoryProvider)
                            .softDeleteDefinition(d.id);
                        ref.invalidate(customFieldDefsProvider);
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

String _typeLabel(AppLocalizations l10n, CustomFieldType type) =>
    switch (type) {
      CustomFieldType.text => l10n.typeText,
      CustomFieldType.number => l10n.typeNumber,
      CustomFieldType.choice => l10n.typeChoice,
      CustomFieldType.date => l10n.typeDate,
    };

Future<void> _showFieldSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final name = TextEditingController();
  final options = TextEditingController();
  var type = CustomFieldType.text;
  var expenseOnly = false;

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
              l10n.newField,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.fieldName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomFieldType>(
              initialValue: type,
              decoration: InputDecoration(labelText: l10n.fieldType),
              items: [
                for (final t in CustomFieldType.values)
                  DropdownMenuItem(value: t, child: Text(_typeLabel(l10n, t))),
              ],
              onChanged: (v) => setState(() => type = v!),
            ),
            if (type == CustomFieldType.choice) ...[
              const SizedBox(height: 12),
              TextField(
                controller: options,
                decoration: InputDecoration(labelText: l10n.choiceOptions),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                l10n.expenseReportOnlyField,
                style: const TextStyle(fontSize: 13),
              ),
              value: expenseOnly,
              onChanged: (v) => setState(() => expenseOnly = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                child: Text(l10n.save),
                onPressed: () async {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  final opts = type == CustomFieldType.choice
                      ? options.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList()
                      : null;
                  final active = ref.read(activeWalletProvider);
                  if (active == null) return;
                  await ref
                      .read(customFieldRepositoryProvider)
                      .define(
                        walletId: active.id,
                        name: n,
                        type: type,
                        options: opts,
                        expenseReportOnly: expenseOnly,
                      );
                  ref.invalidate(customFieldDefsProvider);
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
