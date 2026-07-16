import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../budgets/budget_manager_screen.dart';
import '../recurring/recurring_manager_screen.dart';
import 'backup_actions.dart';
import 'category_manager_screen.dart';
import 'custom_field_manager_screen.dart';
import 'tag_manager_screen.dart';

/// Conferma distruttiva prima dell'import, poi esegue e notifica l'esito.
Future<void> _confirmAndImport(
  BuildContext context,
  WidgetRef ref,
  Future<bool> Function(WidgetRef) action,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.importConfirmTitle),
      content: Text(l10n.importConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final done = await action(ref);
    if (done) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importDone)));
    }
  } on FormatException {
    messenger.showSnackBar(SnackBar(content: Text(l10n.importFailed)));
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          Text(l10n.settingsTab, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            l10n.customization,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (icon, label, screen) in [
                  (
                    Icons.category_outlined,
                    l10n.manageCategories,
                    const CategoryManagerScreen() as Widget,
                  ),
                  (Icons.tag, l10n.manageTags, const TagManagerScreen()),
                  (
                    Icons.tune,
                    l10n.manageCustomFields,
                    const CustomFieldManagerScreen(),
                  ),
                  (
                    Icons.savings_outlined,
                    l10n.budgets,
                    const BudgetManagerScreen(),
                  ),
                  (
                    Icons.autorenew,
                    l10n.recurring,
                    const RecurringManagerScreen(),
                  ),
                ])
                  ListTile(
                    leading: Icon(icon, size: 20),
                    title: Text(label, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => screen)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.backup, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined, size: 20),
                  title: Text(
                    l10n.exportJson,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => exportJsonBackup(ref),
                ),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined, size: 20),
                  title: Text(
                    l10n.exportExcel,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => exportExcelBackup(ref),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined, size: 20),
                  title: Text(
                    l10n.importJson,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () =>
                      _confirmAndImport(context, ref, importJsonBackup),
                ),
                ListTile(
                  leading: const Icon(Icons.grid_on_outlined, size: 20),
                  title: Text(
                    l10n.importExcel,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () =>
                      _confirmAndImport(context, ref, importExcelBackup),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.settingsTheme,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: mode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
              child: Column(
                children: [
                  for (final (value, label) in [
                    (ThemeMode.system, l10n.themeSystem),
                    (ThemeMode.light, l10n.themeLight),
                    (ThemeMode.dark, l10n.themeDark),
                  ])
                    RadioListTile<ThemeMode>(
                      title: Text(label, style: const TextStyle(fontSize: 14)),
                      value: value,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
