// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => 'Inicio';

  @override
  String get transactionsTab => 'Transacciones';

  @override
  String get statsTab => 'Estadísticas';

  @override
  String get settingsTab => 'Más';

  @override
  String get totalBalance => 'Saldo total';

  @override
  String get thisMonth => 'este mes';

  @override
  String get wallets => 'Carteras';

  @override
  String get newWallet => 'Nueva cartera';

  @override
  String get walletName => 'Nombre';

  @override
  String get currency => 'Moneda';

  @override
  String get walletNameDuplicate => 'Ya existe una cartera con este nombre';

  @override
  String get walletNameRequired => 'Introduce un nombre para la cartera';

  @override
  String get initialBalance => 'Saldo inicial';

  @override
  String get recentTransactions => 'Transacciones recientes';

  @override
  String get noTransactions =>
      'Aún no hay transacciones. Toca + para añadir la primera.';

  @override
  String get noWallets => 'Crea tu primera cartera para empezar.';

  @override
  String get newTransaction => 'Nueva transacción';

  @override
  String get expense => 'Gasto';

  @override
  String get income => 'Ingreso';

  @override
  String get transfer => 'Transferencia';

  @override
  String get amount => 'Importe';

  @override
  String get invalidAmount => 'Importe no válido';

  @override
  String get exchangeRateError =>
      'No se pudo obtener el tipo de cambio: revisa tu conexión e inténtalo de nuevo';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount al tipo de cambio actual';
  }

  @override
  String get description => 'Descripción';

  @override
  String get category => 'Categoría';

  @override
  String get wallet => 'Cartera';

  @override
  String get fromWallet => 'Desde';

  @override
  String get toWallet => 'Hasta';

  @override
  String get date => 'Fecha';

  @override
  String get save => 'Guardar';

  @override
  String get apply => 'Aplicar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteWalletTitle => '¿Eliminar la cartera?';

  @override
  String deleteWalletBody(String name) {
    return 'Para confirmar, escribe \"$name\" en el campo de abajo. Esta acción no se puede deshacer.';
  }

  @override
  String get allWallets => 'Todas las carteras';

  @override
  String get allCategories => 'Todas las categorías';

  @override
  String get searchTransactions => 'Buscar transacciones…';

  @override
  String get receipt => 'Recibo';

  @override
  String get fromCamera => 'Cámara';

  @override
  String get fromGallery => 'Galería';

  @override
  String get attachments => 'Adjuntos';

  @override
  String get transactionDetail => 'Transacción';

  @override
  String get deleteTransaction => 'Eliminar transacción';

  @override
  String get addCard => 'Añadir tarjeta';

  @override
  String get cardCategoryDonut => 'Gastos por categoría';

  @override
  String get cardTrend => 'Tendencia de 6 meses';

  @override
  String get cardCashflow => 'Flujo de caja';

  @override
  String get cardBudget => 'Presupuesto';

  @override
  String get netLabel => 'Neto';

  @override
  String get noStatsData => 'No hay datos para este período.';

  @override
  String get emptyDashboard => 'Compón tu panel: añade tu primera tarjeta.';

  @override
  String get customization => 'Personalización';

  @override
  String get budgets => 'Presupuesto';

  @override
  String get newBudget => 'Nuevo presupuesto';

  @override
  String get monthlyLimit => 'Límite mensual';

  @override
  String get recurring => 'Recurrentes';

  @override
  String get newRecurring => 'Nueva transacción recurrente';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get freqDaily => 'Diaria';

  @override
  String get freqWeekly => 'Semanal';

  @override
  String get freqMonthly => 'Mensual';

  @override
  String get freqYearly => 'Anual';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get nextRun => 'Próxima';

  @override
  String get paused => 'Pausada';

  @override
  String budgetNear(String category, int percent) {
    return 'Presupuesto $category al $percent%';
  }

  @override
  String budgetExceeded(String category) {
    return '¡Presupuesto $category superado!';
  }

  @override
  String get manageCategories => 'Categorías';

  @override
  String get manageTags => 'Etiquetas';

  @override
  String get manageCustomFields => 'Campos personalizados';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get editCategory => 'Editar categoría';

  @override
  String get icon => 'Icono (emoji)';

  @override
  String get color => 'Color';

  @override
  String get kindBoth => 'Ambos';

  @override
  String get newTag => 'Nueva etiqueta';

  @override
  String get tagNameRequired => 'Introduce un nombre para la etiqueta';

  @override
  String get tagNameDuplicate => 'Ya existe una etiqueta con este nombre';

  @override
  String get costCenterNameRequired =>
      'Introduce un nombre para el centro de coste';

  @override
  String get tagName => 'Nombre de la etiqueta';

  @override
  String get newField => 'Nuevo campo';

  @override
  String get fieldName => 'Nombre del campo';

  @override
  String get fieldType => 'Tipo';

  @override
  String get typeText => 'Texto';

  @override
  String get typeNumber => 'Número';

  @override
  String get typeChoice => 'Opción';

  @override
  String get typeDate => 'Fecha';

  @override
  String get choiceOptions => 'Opciones (separadas por comas)';

  @override
  String get tags => 'Etiquetas';

  @override
  String get customFields => 'Campos personalizados';

  @override
  String get allTags => 'Todas las etiquetas';

  @override
  String get noItems => 'Nada por aquí todavía.';

  @override
  String get expenseReport => 'Informe de gastos';

  @override
  String get expenseReportFlag => 'Informe de gastos';

  @override
  String get costCenter => 'Centro de coste';

  @override
  String get manageCostCenters => 'Centros de coste';

  @override
  String get newCostCenter => 'Nuevo centro de coste';

  @override
  String get reimbursable => 'Reembolsable';

  @override
  String get eInvoice => 'Factura electrónica';

  @override
  String get pendingReimbursement => 'Pendiente de reembolso';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get createReport => 'Crear informe de gastos';

  @override
  String get reportName => 'Nombre del informe';

  @override
  String get statusDraft => 'Borrador';

  @override
  String get statusSent => 'Enviado';

  @override
  String get statusReimbursed => 'Reembolsado';

  @override
  String get markSent => 'Marcar como enviado';

  @override
  String get markReimbursed => 'Marcar como reembolsado';

  @override
  String get reportArchive => 'Archivo';

  @override
  String get flaggedExpenses => 'Gastos marcados';

  @override
  String get expenseReportOnlyField => 'Solo para informes de gastos';

  @override
  String get edit => 'Editar';

  @override
  String get editTransaction => 'Editar transacción';

  @override
  String get fromDate => 'Desde';

  @override
  String get toDate => 'Hasta';

  @override
  String get none => 'Ninguno';

  @override
  String get language => 'Idioma';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get account => 'Account';

  @override
  String get accountLocalModeDescription =>
      'You\'re not signed in: your data stays on this device only. Sign in to sync it across devices.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmSignOut =>
      'Sign out of your account? Your data stays on this device and keeps working offline.';

  @override
  String get noAccountYet => 'Don\'t have an account? Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordSent =>
      'Password reset email sent — check your inbox.';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get changePassword => 'Change password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';

  @override
  String get passwordChanged =>
      'Password changed. Other devices have been signed out.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed. Check your connection and try again.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmBody =>
      'Your account will be permanently deleted in 30 days. You can cancel any time before then by signing back in. This does not affect the data on this device, which keeps working offline.';

  @override
  String get deleteAccountRequested =>
      'Account deletion requested. You have 30 days to cancel.';

  @override
  String deletionPending(String date) {
    return 'Account scheduled for deletion on $date.';
  }

  @override
  String get cancelDeletion => 'Cancel deletion';

  @override
  String get deletionCanceled => 'Account deletion canceled.';

  @override
  String get signOutRemoveLocalData => 'Eliminar los datos de este dispositivo';

  @override
  String get signOutRemoveLocalDataHint =>
      'Tus datos se sincronizan primero con tu cuenta y luego se eliminan de este dispositivo. Las fotos de los recibos aún no se sincronizan y se perderán.';

  @override
  String get signOutSyncFailed =>
      'No se pudo sincronizar antes de eliminar los datos. No se ha eliminado nada y sigues con la sesión iniciada: revisa tu conexión e inténtalo de nuevo.';

  @override
  String get localDataRemoved => 'Datos eliminados de este dispositivo';

  @override
  String get foreignLocalDataBody =>
      'Este dispositivo contiene datos de otra cuenta, así que la sincronización está en pausa para mantenerlos separados. Elimina esos datos para sincronizar esta cuenta, o cierra sesión.';

  @override
  String get removeLocalDataAndSync => 'Eliminar datos y sincronizar';

  @override
  String get removeForeignLocalDataConfirmBody =>
      'Se eliminarán todas las carteras, transacciones y fotos de recibos de este dispositivo. Lo que la otra cuenta ya sincronizó sigue a salvo en esa cuenta. ¿Continuar?';

  @override
  String get syncBlockedForeignData =>
      'Sincronización en pausa: este dispositivo contiene datos de otra cuenta.';
}
