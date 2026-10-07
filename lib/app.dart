import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/account/account_screen.dart';
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
      locale: ref.watch(localeProvider),
      theme: nipayLightTheme(),
      darkTheme: nipayDarkTheme(),
      themeMode: ref.watch(themeModeProvider),
      builder: (context, child) => _PrivacyShield(child: child!),
      home: const RootShell(),
    );
  }
}

/// Copre l'app quando non è in primo piano: l'anteprima dell'app switcher
/// non mostra saldi e movimenti (SECURITY_AUDIT NIP-13). Su Android 13+
/// anche MainActivity disattiva lo screenshot dei recenti.
class _PrivacyShield extends StatefulWidget {
  const _PrivacyShield({required this.child});

  final Widget child;

  @override
  State<_PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<_PrivacyShield>
    with WidgetsBindingObserver {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final obscured = state != AppLifecycleState.resumed;
    if (obscured != _obscured) setState(() => _obscured = obscured);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_obscured)
          Positioned.fill(
            child: ColoredBox(
              key: const Key('privacyShield'),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: Icon(Icons.lock_outline, size: 48)),
            ),
          ),
      ],
    );
  }
}

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _periodicSyncTimer;
  StreamSubscription<void>? _recoverySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForPasswordRecovery();
    // Periodico "di sicurezza": il grosso del lavoro lo fanno il trigger
    // al login e il resume dell'app: questo copre solo il caso di una
    // sessione app lasciata aperta a lungo in primo piano.
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _sync(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicSyncTimer?.cancel();
    _recoverySubscription?.cancel();
    super.dispose();
  }

  /// Link di recupero password aperto dall'email (deep link): si chiede
  /// subito la nuova password (SECURITY_AUDIT NIP-09).
  void _listenForPasswordRecovery() {
    try {
      _recoverySubscription = ref
          .read(authServiceProvider)
          .passwordRecoveryRequests
          .listen((_) {
            if (!mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const PasswordRecoveryDialog(),
            );
          });
    } catch (_) {
      // Supabase non inizializzato (test): nessun recupero possibile.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  /// Sync in background, mai bloccante per la UI. `syncNow()` è già un
  /// no-op silenzioso in modalità solo-locale — un eventuale errore di
  /// rete qui non deve mai propagarsi come eccezione non gestita. Gli
  /// errori non sono più invisibili: il motore li registra e la schermata
  /// Account mostra l'esito dell'ultima sync (SECURITY_AUDIT NIP-04).
  void _sync() {
    unawaited(
      ref.read(syncServiceProvider).syncNow().catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Seed categorie + catch-up ricorrenze prima di mostrare i dati.
    final ready = ref.watch(bootstrapProvider);
    // Dati legati a un account diverso da quello loggato (o a nessuno):
    // l'app non li mostra (SECURITY_AUDIT NIP-13).
    final access = ref.watch(localDataAccessProvider);
    final locked = access.valueOrNull?.isOpen != true;
    // Sync subito dopo il login (incluso l'avvio app con sessione già
    // valida) — non al logout, dove non c'è nulla da sincronizzare.
    ref.listen(authStateProvider, (previous, next) {
      if (next.valueOrNull != null) _sync();
    });

    if (locked) {
      final state = access.valueOrNull?.state;
      return Scaffold(
        body: state == null || state == LocalDataAccessState.pending
            ? (access.hasError
                  ? _LockedLocalData(access: null)
                  : const Center(child: CircularProgressIndicator()))
            : _LockedLocalData(access: access.valueOrNull),
      );
    }

    return Scaffold(
      body: ready.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Mai il testo dell'eccezione: può contenere path e dettagli interni
        // (SECURITY_AUDIT NIP-17).
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.startupError, textAlign: TextAlign.center),
          ),
        ),
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

/// Schermata al posto dell'app quando i dati del device sono legati a un
/// account diverso da quello loggato (o a nessuno). Si sblocca rientrando
/// con l'account giusto, oppure rimuovendo i dati dal device.
class _LockedLocalData extends ConsumerWidget {
  const _LockedLocalData({required this.access});

  /// Null se lo stato non è leggibile: per sicurezza si resta bloccati.
  final LocalDataAccess? access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final email = access?.ownerEmail;
    final body = switch (access?.state) {
      LocalDataAccessState.otherAccount => l10n.lockedDataOtherAccountBody,
      _ when email != null => l10n.lockedDataBody(email),
      _ => l10n.lockedDataBodyUnknownOwner,
    };
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            key: const Key('lockedLocalData'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n.lockedDataTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
                child: Text(l10n.account),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmRemove(context, ref),
                child: Text(l10n.signOutRemoveLocalData),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutRemoveLocalData),
        content: Text(l10n.removeForeignLocalDataConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOutRemoveLocalData),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(localDataServiceProvider).wipe();
    ref.read(activeWalletIdProvider.notifier).clear();
    ref.invalidate(localDataAccessProvider);
    // Se è loggato un account, i suoi dati arrivano subito (no-op se no).
    unawaited(ref.read(syncServiceProvider).syncNow().catchError((_) {}));
  }
}
