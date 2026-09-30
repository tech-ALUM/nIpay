import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/sync_service.dart';
import '../../l10n/app_localizations.dart';

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
        child: Padding(
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

  @override
  void initState() {
    super.initState();
    _refreshDeletionStatus();
    _refreshForeignLocalData();
  }

  void _refreshForeignLocalData() {
    _foreignLocalData = ref
        .read(syncServiceProvider)
        .hasLocalDataOfAnotherUser();
  }

  void _refreshDeletionStatus() {
    _deletionStatus = ref.read(authServiceProvider).getAccountDeletionRequestedAt();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.signedInAs(widget.email)),
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
                            onPressed: () => ref
                                .read(authServiceProvider)
                                .signOut(),
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirmBody),
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
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authServiceProvider).requestAccountDeletion();
      setState(_refreshDeletionStatus);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deleteAccountRequested)));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _cancelDeletion() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(authServiceProvider).cancelAccountDeletion();
    setState(_refreshDeletionStatus);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deletionCanceled)));
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
    if (!mounted) return;
    setState(_refreshForeignLocalData);
    await _syncNow();
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSyncing = true);
    try {
      await ref.read(syncServiceProvider).syncNow();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.syncComplete)));
      }
    } on LocalDataOwnedByAnotherUserException {
      if (mounted) {
        setState(_refreshForeignLocalData);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.syncBlockedForeignData)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.syncFailed)));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
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
    final localData = ref.read(localDataServiceProvider);
    final activeWallet = ref.read(activeWalletIdProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (removeLocalData) {
      // Sync finale obbligatoria: se fallisce non si cancella nulla, così
      // le modifiche non ancora inviate non vanno perse.
      try {
        await ref.read(syncServiceProvider).syncNow();
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.signOutSyncFailed)),
        );
        return;
      }
    }
    await auth.signOut();
    if (removeLocalData) {
      await localData.wipe();
      activeWallet.clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.localDataRemoved)));
    }
  }
}

class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm();

  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;

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
            decoration: InputDecoration(labelText: l10n.email),
            validator: (value) =>
                (value == null || !value.contains('@'))
                ? l10n.invalidEmail
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.password),
            validator: (value) =>
                (value == null || value.length < 8)
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
            child: Text(_isSignUp ? l10n.alreadyHaveAccount : l10n.noAccountYet),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _showError(l10n.invalidEmail);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resetPasswordSent)));
      }
    } on AuthException catch (e) {
      _showError(e.message);
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

/// Cambio password per l'utente già loggato: a differenza del reset via
/// email (per chi ha dimenticato la password), qui la nuova password si
/// imposta direttamente, senza email intermedia.
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends ConsumerState<_ChangePasswordDialog> {
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
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.newPassword),
              validator: (value) =>
                  (value == null || value.length < 8)
                  ? l10n.passwordTooShort
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.confirmPassword),
              validator: (value) =>
                  value != _newPasswordController.text
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
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
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
          .changePassword(_newPasswordController.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
