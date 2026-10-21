import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../core/validation.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFieldSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newField),
      ),
      body: defs.isEmpty
          ? Center(
              child: EmptyState(icon: Icons.tune, message: l10n.noItems),
            )
          : CenteredListView(
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, d) in defs.indexed) ...[
                        if (i > 0) const Divider(indent: 68),
                        ListTile(
                          leading: IconBadge(
                            icon: _typeIcon(d.type),
                            color: context.nipay.muted,
                            size: 36,
                          ),
                          title: Text(d.name),
                          subtitle: Text(
                            [
                              _typeLabel(l10n, d.type),
                              if (d.options != null) d.options!.join(', '),
                              if (d.expenseReportOnly) l10n.expenseReport,
                            ].join(' · '),
                          ),
                          trailing: IconButton(
                            tooltip: l10n.delete,
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () async {
                              final confirmed = await confirmDeletion(
                                context,
                                title: l10n.deleteItemTitle(d.name),
                              );
                              if (!confirmed) return;
                              await ref
                                  .read(customFieldRepositoryProvider)
                                  .softDeleteDefinition(d.id);
                              ref.invalidate(customFieldDefsProvider);
                            },
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

IconData _typeIcon(CustomFieldType type) => switch (type) {
  CustomFieldType.text => Icons.short_text,
  CustomFieldType.number => Icons.pin_outlined,
  CustomFieldType.choice => Icons.list_alt,
  CustomFieldType.date => Icons.event_outlined,
};

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
  String? nameError;

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) => SheetScaffold(
        title: l10n.newField,
        actions: [
          FilledButton(
            onPressed: () async {
              final n = name.text.trim();
              if (n.isEmpty) {
                setState(() => nameError = l10n.fieldRequired);
                return;
              }
              final opts = type == CustomFieldType.choice
                  ? options.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .map(
                          (s) => s.length > kMaxNameLength
                              ? s.substring(0, kMaxNameLength)
                              : s,
                        )
                        .take(kMaxChoiceOptions)
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
              labelText: l10n.fieldName,
              errorText: nameError,
            ),
          ),
          kFieldGap,
          DropdownButtonFormField<CustomFieldType>(
            initialValue: type,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.fieldType),
            items: [
              for (final t in CustomFieldType.values)
                DropdownMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Icon(_typeIcon(t), size: 20),
                      const SizedBox(width: 12),
                      Text(_typeLabel(l10n, t)),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => type = v!),
          ),
          if (type == CustomFieldType.choice) ...[
            kFieldGap,
            TextField(
              controller: options,
              inputFormatters: [
                LengthLimitingTextInputFormatter(kMaxChoiceOptionsLength),
              ],
              decoration: InputDecoration(labelText: l10n.choiceOptions),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.receipt_long_outlined),
            title: Text(l10n.expenseReportOnlyField),
            value: expenseOnly,
            onChanged: (v) => setState(() => expenseOnly = v),
          ),
        ],
      ),
    ),
  );
}
