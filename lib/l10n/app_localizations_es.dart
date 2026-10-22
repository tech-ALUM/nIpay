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
  String get account => 'Cuenta';

  @override
  String get accountLocalModeDescription =>
      'No has iniciado sesión: tus datos se quedan solo en este dispositivo. Inicia sesión para sincronizarlos entre dispositivos.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmSignOut =>
      '¿Cerrar sesión en tu cuenta? Tus datos se quedan en este dispositivo, pero solo podrás volver a abrirlos iniciando sesión con esta cuenta.';

  @override
  String get noAccountYet => '¿No tienes cuenta? Regístrate';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get forgotPassword => '¿Has olvidado la contraseña?';

  @override
  String get resetPasswordSent =>
      'Correo para restablecer la contraseña enviado — revisa tu bandeja de entrada.';

  @override
  String signedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String get invalidEmail => 'Introduce un correo electrónico válido';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get passwordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get passwordChanged =>
      'Contraseña cambiada. Se ha cerrado la sesión en los demás dispositivos.';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncComplete => 'Sincronización completada';

  @override
  String get syncFailed =>
      'Error de sincronización. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountConfirmBody =>
      'Tu cuenta y sus datos en la nube se eliminarán definitivamente dentro de 30 días. Hasta entonces puedes cancelarlo desde esta pantalla. Los datos de este dispositivo no se eliminan.';

  @override
  String get deleteAccountRequested =>
      'Eliminación de la cuenta solicitada. Tienes 30 días para cancelarla.';

  @override
  String deletionPending(String date) {
    return 'La cuenta se eliminará el $date.';
  }

  @override
  String get cancelDeletion => 'Cancelar eliminación';

  @override
  String get deletionCanceled => 'Eliminación de la cuenta cancelada.';

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

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get wrongCurrentPassword => 'La contraseña actual no es correcta.';

  @override
  String get confirmWithPassword => 'Introduce tu contraseña para confirmar.';

  @override
  String get passwordTooWeak =>
      'Usa al menos 12 caracteres, con letras y números.';

  @override
  String get signOutEverywhere => 'Cerrar sesión en todos los dispositivos';

  @override
  String get signOutEverywhereConfirmBody =>
      'Se cerrarán todas las sesiones de esta cuenta, incluida esta. Úsalo si has perdido un dispositivo o te lo han robado. Los datos de este dispositivo se quedan aquí.';

  @override
  String get signedOutEverywhere => 'Sesión cerrada en todos los dispositivos.';

  @override
  String get authErrorInvalidCredentials =>
      'Correo o contraseña no válidos, o el correo aún no se ha confirmado.';

  @override
  String get authErrorWeakPassword =>
      'Esta contraseña no se acepta: elige una más larga y menos común.';

  @override
  String get authErrorSamePassword =>
      'La nueva contraseña debe ser distinta de la actual.';

  @override
  String get authErrorRateLimited =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get authErrorReauthRequired =>
      'Por seguridad, vuelve a introducir tu contraseña e inténtalo de nuevo.';

  @override
  String get authErrorNetwork =>
      'No se puede conectar con el servidor. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get authErrorGeneric => 'Algo ha salido mal. Inténtalo de nuevo.';

  @override
  String get resetPasswordTitle => 'Establece una nueva contraseña';

  @override
  String get passwordResetDone =>
      'Contraseña actualizada. Se ha cerrado la sesión en los demás dispositivos.';

  @override
  String get resetPasswordCooldown =>
      'Espera un minuto antes de solicitar otro correo.';

  @override
  String lastSyncAt(String date) {
    return 'Última sincronización: $date';
  }

  @override
  String get lastSyncNever => 'Aún no sincronizado';

  @override
  String get syncLastFailed =>
      'La última sincronización falló: se volverá a intentar automáticamente.';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementos no se han podido sincronizar y se volverán a intentar.',
      one: '1 elemento no se ha podido sincronizar y se volverá a intentar.',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => 'Datos bloqueados';

  @override
  String lockedDataBody(String email) {
    return 'Este dispositivo contiene los datos de $email. Inicia sesión con esa cuenta para verlos, o elimínalos de este dispositivo.';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      'Este dispositivo contiene los datos de una cuenta que no ha iniciado sesión. Inicia sesión con esa cuenta para verlos, o elimínalos de este dispositivo.';

  @override
  String get lockedDataOtherAccountBody =>
      'Este dispositivo contiene los datos de otra cuenta. Para usar esta cuenta aquí, elimina esos datos del dispositivo (abre Cuenta) o cierra sesión.';

  @override
  String get startupError =>
      'No se han podido abrir tus datos. Reinicia la app; si sigue ocurriendo, contacta con el soporte.';

  @override
  String get attachmentUnsupported =>
      'Este formato de imagen no es compatible: usa una foto JPEG, PNG o WebP.';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String deleteItemTitle(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get deleteItemBody => 'Esta acción no se puede deshacer.';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get fieldRequired => 'Obligatorio';

  @override
  String get noWalletForTransaction =>
      'Crea primero una cartera para añadir transacciones.';

  @override
  String get categoryGroceries => 'Supermercado';

  @override
  String get categoryRestaurants => 'Restaurantes';

  @override
  String get categoryTransport => 'Transporte';

  @override
  String get categoryHousing => 'Hogar';

  @override
  String get categoryLeisure => 'Ocio';

  @override
  String get categoryHealth => 'Salud';

  @override
  String get categoryShopping => 'Compras';

  @override
  String get categorySalary => 'Salario';

  @override
  String get categoryGifts => 'Regalos';

  @override
  String get categoryOther => 'Otros';
}
