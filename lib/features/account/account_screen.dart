import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/validation.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/sync_service.dart';
import '../../l10n/app_localizations.dart';

/// Messaggio l10n per un errore di autenticazione: mai il testo grezzo del
/// server (SECURITY_AUDIT NIP-17).
String authErrorText(AppLocalizations l10n, AuthErrorCode code) =>
    switch (code) {
      AuthErrorCode.invalidCredentials => l10n.authErrorInvalidCredentials,
      AuthErrorCode.wrongCurrentPassword => l10n.wrongCurrentPassword,
      AuthErrorCode.weakPassword => l10n.authErrorWeakPassword,
      AuthErrorCode.samePassword => l10n.authErrorSamePassword,
      AuthErrorCode.rateLimited => l10n.authErrorRateLimited,
      AuthErrorCode.reauthenticationRequired => l10n.authErrorReauthRequired,
      AuthErrorCode.network => l10n.authErrorNetwork,
      AuthErrorCode.unknown => l10n.authErrorGeneric,
    };

String? _newPasswordError(AppLocalizations l10n, String? value) =>
    (value == null || !isStrongPassword(value)) ? l10n.passwordTooWeak : null;

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  return '${_formatDate(local)} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// Ingresso account: mostra il form di login/registrazione in modalità
/// solo-locale, o email + logout se già autenticato, con sync manuale e
/// gestione dei dati locali (rimozione al logout, blocco se appartengono a
/// un altro account).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: user == null
              ? const _AuthForm()
              : _SignedInView(email: user.email ?? ''),
        ),
      ),
    );
  }
}

class _SignedInView extends ConsumerStatefulWidget {
  const _SignedInView({required this.email});

  final String email;

  @override
  ConsumerState<_SignedInView> createState() => _SignedInViewState();
}

class _SignedInViewState extends ConsumerState<_SignedInView> {
  bool _isSyncing = false;
  Future<DateTime?>? _deletionStatus;
  Future<bool>? _foreignLocalData;
  Future<SyncStatus?>? _syncStatus;

  @override
  void initState() {
    super.initState();
    _refreshDeletionStatus();
    _refreshForeignLocalData();
    _refreshSyncStatus();
  }

  void _refreshForeignLocalData() {
    _foreignLocalData = ref
        .read(syncServiceProvider)
        .hasLocalDataOfAnotherUser();
  }

  void _refreshDeletionStatus() {
    _deletionStatus = ref
        .read(authServiceProvider)
        .getAccountDeletionRequestedAt()
        .catchError((Object _) => null);
  }

  void _refreshSyncStatus() {
    _syncStatus = ref.read(syncServiceProvider).status();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.signedInAs(widget.email)),
        FutureBuilder<SyncStatus?>(
          future: _syncStatus,
          builder: (context, snapshot) {
            final status = snapshot.data;
            final muted = Theme.of(context).textTheme.bodySmall;
            final error = TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: muted?.fontSize,
            );
            return Padding(
              key: const Key('syncStatus'),
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status?.lastSuccessAt == null
                        ? l10n.lastSyncNever
                        : l10n.lastSyncAt(
                            _formatDateTime(status!.lastSuccessAt!),
                          ),
                    style: muted,
                  ),
                  if (status?.lastError != null)
                    Text(l10n.syncLastFailed, style: error),
                  if ((status?.pendingIssues ?? 0) > 0)
                    Text(l10n.syncIssues(status!.pendingIssues), style: error),
                ],
              ),
            );
          },
        ),
        FutureBuilder<DateTime?>(
          future: _deletionStatus,
          builder: (context, snapshot) {
            final requestedAt = snapshot.data;
            if (requestedAt == null) return const SizedBox.shrink();
            final purgeDate = requestedAt.add(const Duration(days: 30));
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.deletionPending(_formatDate(purgeDate))),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _cancelDeletion,
                        child: Text(l10n.cancelDeletion),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        FutureBuilder<bool>(
          future: _foreignLocalData,
          builder: (context, snapshot) {
            if (snapshot.data != true) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                key: const Key('foreignLocalDataBanner'),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.foreignLocalDataBody),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: _isSyncing
                                ? null
                                : _removeForeignDataAndSync,
                            child: Text(l10n.removeLocalDataAndSync),
                          ),
                          OutlinedButton(
                            onPressed: _signOutKeepingData,
                            child: Text(l10n.signOut),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _isSyncing ? null : _syncNow,
          icon: _isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(l10n.syncNow),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _ChangePasswordDialog(),
          ),
          child: Text(l10n.changePassword),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _confirmSignOut(context, ref),
          child: Text(l10n.signOut),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _confirmSignOutEverywhere,
          child: Text(l10n.signOutEverywhere),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          onPressed: _confirmDeleteAccount,
          child: Text(l10n.deleteAccount),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final requested = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (requested != true || !mounted) return;
    setState(_refreshDeletionStatus);
    _showSnack(l10n.deleteAccountRequested);
  }

  Future<void> _cancelDeletion() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(authServiceProvider).cancelAccountDeletion();
      if (!mounted) return;
      setState(_refreshDeletionStatus);
      _showSnack(l10n.deletionCanceled);
    } on AuthException catch (e) {
      _showSnack(authErrorText(l10n, e.code));
    }
  }

  /// I dati dell'altro account non vengono sincronizzati prima: questo
  /// utente non ha i permessi per scriverli (RLS), e quelli già inviati da
  /// quell'account restano al sicuro sul suo cloud.
  Future<void> _removeForeignDataAndSync() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeLocalDataAndSync),
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
            child: Text(l10n.removeLocalDataAndSync),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(localDataServiceProvider).wipe();
    ref.read(activeWalletIdProvider.notifier).clear();
    ref.invalidate(localDataAccessProvider);
    if (!mounted) return;
    setState(_refreshForeignLocalData);
    await _syncNow();
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSyncing = true);
    try {
      await ref.read(syncServiceProvider).syncNow();
      _showSnack(l10n.syncComplete);
    } on LocalDataOwnedByAnotherUserException {
      if (mounted) setState(_refreshForeignLocalData);
      _showSnack(l10n.syncBlockedForeignData);
    } catch (_) {
      _showSnack(l10n.syncFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _refreshSyncStatus();
        });
      }
    }
  }

  Future<void> _signOutKeepingData() async {
    final auth = ref.read(authServiceProvider);
    await ref.read(syncServiceProvider).exclusive(auth.signOut);
  }

  Future<void> _confirmSignOutEverywhere() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutEverywhere),
        content: Text(l10n.signOutEverywhereConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOutEverywhere),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = ref.read(authServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(syncServiceProvider).exclusive(auth.signOutEverywhere);
      messenger.showSnackBar(SnackBar(content: Text(l10n.signedOutEverywhere)));
    } on AuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(authErrorText(l10n, e.code))),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    var removeLocalData = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.signOut),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                removeLocalData
                    ? l10n.signOutRemoveLocalDataHint
                    : l10n.confirmSignOut,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('removeLocalDataCheckbox'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: removeLocalData,
                onChanged: (value) =>
                    setDialogState(() => removeLocalData = value ?? false),
                title: Text(l10n.signOutRemoveLocalData),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.signOut),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Letti prima del logout: dopo signOut() questa vista viene smontata
    // (l'AccountScreen passa al form) e `ref` non è più utilizzabile.
    final auth = ref.read(authServiceProvider);
    final sync = ref.read(syncServiceProvider);
    final localData = ref.read(localDataServiceProvider);
    final activeWallet = ref.read(activeWalletIdProvider.notifier);
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // Sync finale, logout e rimozione nello stesso lock della sync: una
    // sync in background non può infilarsi in mezzo e reinserire dati
    // dopo la rimozione (SECURITY_AUDIT NIP-14).
    final removed = await sync.exclusive(() async {
      if (removeLocalData) {
        // Sync finale obbligatoria: se fallisce non si cancella nulla, così
        // le modifiche non ancora inviate non vanno perse.
        try {
          await sync.syncNow();
        } catch (_) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.signOutSyncFailed)),
          );
          return null;
        }
      }
      await auth.signOut();
      if (!removeLocalData) return false;
      await localData.wipe();
      return true;
    });
    if (removed == true) {
      activeWallet.clear();
      container.invalidate(localDataAccessProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.localDataRemoved)));
    }
  }
}

/// Richiesta di cancellazione dell'account: serve la password attuale
/// (SECURITY_AUDIT NIP-05). La data la decide il server.
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty) {
      setState(() => _error = l10n.confirmWithPassword);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .requestAccountDeletion(currentPassword: _passwordController.text);
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e.code));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.deleteAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountConfirmBody),
          const SizedBox(height: 12),
          TextField(
            key: const Key('deleteAccountPassword'),
            controller: _passwordController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: kMaxPasswordLength,
            decoration: InputDecoration(
              labelText: l10n.currentPassword,
              helperText: l10n.confirmWithPassword,
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: Text(l10n.deleteAccount),
        ),
      ],
    );
  }
}

class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm();

  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  /// Pausa tra due richieste di email di recupero dallo stesso device: il
  /// provider email di Supabase ha un limite globale molto basso
  /// (SECURITY_AUDIT NIP-11). Il limite vero resta quello del server.
  static const _resetCooldown = Duration(seconds: 60);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  DateTime? _lastResetRequest;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.accountLocalModeDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            maxLength: 254,
            decoration: InputDecoration(labelText: l10n.email, counterText: ''),
            validator: (value) => (value == null || !isValidEmail(value.trim()))
                ? l10n.invalidEmail
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: kMaxPasswordLength,
            decoration: InputDecoration(
              labelText: l10n.password,
              helperText: _isSignUp ? l10n.passwordTooWeak : null,
              helperMaxLines: 2,
              counterText: '',
            ),
            validator: (value) => _isSignUp
                ? _newPasswordError(l10n, value)
                : (value == null || value.length < 8)
                ? l10n.passwordTooShort
                : null,
          ),
          if (!_isSignUp) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting ? null : _sendPasswordReset,
                child: Text(l10n.forgotPassword),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSignUp ? l10n.signUp : l10n.signIn),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp ? l10n.alreadyHaveAccount : l10n.noAccountYet,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    final service = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      if (_isSignUp) {
        await service.signUpWithEmail(email: email, password: password);
      } else {
        await service.signInWithEmail(email: email, password: password);
      }
    } on AuthException catch (e) {
      _showError(authErrorText(l10n, e.code));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (!isValidEmail(email)) {
      _showError(l10n.invalidEmail);
      return;
    }
    final last = _lastResetRequest;
    if (last != null && DateTime.now().difference(last) < _resetCooldown) {
      _showError(l10n.resetPasswordCooldown);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      _lastResetRequest = DateTime.now();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resetPasswordSent)));
      }
    } on AuthException catch (e) {
      _showError(authErrorText(l10n, e.code));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Cambio password per l'utente già loggato: serve la password attuale
/// (SECURITY_AUDIT NIP-08), poi tutte le altre sessioni vengono chiuse.
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.changePassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('currentPasswordField'),
              controller: _currentPasswordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: kMaxPasswordLength,
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                counterText: '',
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? l10n.confirmWithPassword
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('newPasswordField'),
              controller: _newPasswordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: kMaxPasswordLength,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                counterText: '',
              ),
              validator: (value) => _newPasswordError(l10n, value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('confirmPasswordField'),
              controller: _confirmPasswordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: kMaxPasswordLength,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                counterText: '',
              ),
              validator: (value) => value != _newPasswordController.text
                  ? l10n.passwordsDontMatch
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(authServiceProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e.code));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Nuova password dopo aver aperto il link di recupero dall'email
/// (SECURITY_AUDIT NIP-09). Mostrata dalla shell dell'app quando
/// [AuthService.passwordRecoveryRequests] emette.
class PasswordRecoveryDialog extends ConsumerStatefulWidget {
  const PasswordRecoveryDialog({super.key});

  @override
  ConsumerState<PasswordRecoveryDialog> createState() =>
      _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState
    extends ConsumerState<PasswordRecoveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .completePasswordRecovery(_newPasswordController.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.passwordResetDone)));
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = authErrorText(l10n, e.code));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.resetPasswordTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: kMaxPasswordLength,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                helperText: l10n.passwordTooWeak,
                helperMaxLines: 2,
                counterText: '',
              ),
              validator: (value) => _newPasswordError(l10n, value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: kMaxPasswordLength,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                counterText: '',
              ),
              validator: (value) => value != _newPasswordController.text
                  ? l10n.passwordsDontMatch
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
