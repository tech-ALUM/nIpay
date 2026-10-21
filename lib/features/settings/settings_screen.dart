import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
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
    final palette = context.nipay;
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final email = ref.watch(authStateProvider).valueOrNull?.email;

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return SafeArea(
      child: CenteredListView(
        top: 0,
        children: [
          PageHeader(l10n.settingsTab),
          Card(
            clipBehavior: Clip.antiAlias,
            child: _NavTile(
              icon: Icons.account_circle_outlined,
              color: palette.income,
              label: l10n.account,
              subtitle: email,
              onTap: () => open(const AccountScreen()),
            ),
          ),
          SectionHeader(l10n.customization),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, (icon, label, screen)) in [
                  (
                    Icons.category_outlined,
                    l10n.manageCategories,
                    const CategoryManagerScreen() as Widget,
                  ),
                  (
                    Icons.sell_outlined,
                    l10n.manageTags,
                    const TagManagerScreen(),
                  ),
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
                ].indexed) ...[
                  if (i > 0) const Divider(indent: 68),
                  _NavTile(
                    icon: icon,
                    color: palette.muted,
                    label: label,
                    onTap: () => open(screen),
                  ),
                ],
              ],
            ),
          ),
          SectionHeader(l10n.language),
          // Il titolo di sezione fa da etichetta visibile; agli screen reader
          // arriva dalla Semantics.
          Semantics(
            label: l10n.language,
            child: DropdownButtonFormField<Locale>(
              initialValue: locale,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.translate),
              ),
              items: [
                for (final (value, label) in _languages)
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (v) => ref.read(localeProvider.notifier).set(v!),
            ),
          ),
          SectionHeader(l10n.settingsTheme),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// Voce di menu che apre una schermata: icona in badge, etichetta, chevron.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: IconBadge(icon: icon, color: color, size: 36),
    title: Text(label),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
