import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../budgets/budget_manager_screen.dart';
import '../recurring/recurring_manager_screen.dart';
import 'category_manager_screen.dart';
import 'cost_center_manager_screen.dart';
import 'custom_field_manager_screen.dart';
import 'tag_manager_screen.dart';

/// Lingue supportate: codice + nome nella lingua stessa (non tradotto),
/// così ognuno riconosce la propria indipendentemente dalla lingua attiva.
const _languages = [
  (Locale('en'), 'English'),
  (Locale('it'), 'Italiano'),
  (Locale('es'), 'Español'),
  (Locale('fr'), 'Français'),
  (Locale('de'), 'Deutsch'),
  (Locale('ar'), 'العربية'),
  (Locale('zh'), '中文'),
  (Locale('hi'), 'हिन्दी'),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

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
                  (
                    Icons.work_outline,
                    l10n.manageCostCenters,
                    const CostCenterManagerScreen(),
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
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonFormField<Locale>(
                initialValue: locale,
                isExpanded: true,
                decoration: const InputDecoration(border: InputBorder.none),
                items: [
                  for (final (value, label) in _languages)
                    DropdownMenuItem(
                      value: value,
                      child: Text(label, style: const TextStyle(fontSize: 14)),
                    ),
                ],
                onChanged: (v) => ref.read(localeProvider.notifier).set(v!),
              ),
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
              onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
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
