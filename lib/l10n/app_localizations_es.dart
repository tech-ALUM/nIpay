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
}
