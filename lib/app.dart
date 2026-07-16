import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/transactions/add_transaction_sheet.dart';
import 'features/transactions/transactions_screen.dart';
import 'l10n/app_localizations.dart';

class NipayApp extends ConsumerWidget {
  const NipayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: nipayLightTheme(),
      darkTheme: nipayDarkTheme(),
      themeMode: ref.watch(themeModeProvider),
      home: const RootShell(),
    );
  }
}

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Seed categorie + catch-up ricorrenze prima di mostrare i dati.
    final ready = ref.watch(bootstrapProvider);

    return Scaffold(
      body: ready.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) => IndexedStack(
          index: _tab,
          children: const [
            HomeScreen(),
            TransactionsScreen(),
            StatsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      floatingActionButton: _tab <= 1
          ? FloatingActionButton(
              key: const Key('addTransactionFab'),
              onPressed: () => showAddTransactionSheet(context),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.homeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.transactionsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.donut_small_outlined),
            selectedIcon: const Icon(Icons.donut_small),
            label: l10n.statsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
