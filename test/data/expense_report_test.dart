import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/export/expense_report_pdf.dart';
import 'package:nipay/data/repositories/cost_center_repository.dart';
import 'package:nipay/data/repositories/expense_report_repository.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

void main() {
  late AppDatabase db;
  late String wallet;
  late TransactionRepository txs;
  late ExpenseReportRepository reports;
  late CostCenterRepository costCenters;

  Future<String> spesa(int cents, DateTime date, {String desc = ''}) =>
      txs.createExpense(
        walletId: wallet,
        amountCents: cents,
        date: date,
        description: desc,
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    wallet = await DriftWalletRepository(
      db,
    ).create(name: 'Conto', colorHex: '#0E7C86');
    txs = DriftTransactionRepository(db);
    reports = DriftExpenseReportRepository(db);
    costCenters = DriftCostCenterRepository(db);
  });

  tearDown(() async => db.close());

  test('flag e unflag nota spese su una transazione', () async {
    final cc = await costCenters.create('Cliente X', walletId: wallet);
    final tx = await spesa(4250, DateTime(2026, 7, 10), desc: 'Pranzo');

    await reports.setExpenseData(
      transactionId: tx,
      costCenterId: cc,
      reimbursable: true,
      eInvoice: false,
    );
    var data = await reports.dataOf(tx);
    expect(data, isNotNull);
    expect(data!.costCenterId, cc);
    expect(data.reimbursable, isTrue);

    // Modifica retroattiva: aggiorna i campi.
    await reports.setExpenseData(
      transactionId: tx,
      reimbursable: false,
      eInvoice: true,
    );
    data = await reports.dataOf(tx);
    expect(data!.reimbursable, isFalse);
    expect(data.eInvoice, isTrue);
    expect(data.costCenterId, isNull);

    // Unflag: la spesa non è più nota spese.
    await reports.clearExpenseData(tx);
    expect(await reports.dataOf(tx), isNull);
  });

  test('flaggedInRange ritorna solo le spese flaggate nel periodo', () async {
    final a = await spesa(1000, DateTime(2026, 7, 5), desc: 'Taxi');
    final b = await spesa(2000, DateTime(2026, 7, 20), desc: 'Hotel');
    await spesa(3000, DateTime(2026, 7, 10), desc: 'NonFlaggata');
    final fuori = await spesa(4000, DateTime(2026, 8, 2), desc: 'FuoriPeriodo');
    for (final id in [a, b, fuori]) {
      await reports.setExpenseData(transactionId: id);
    }

    final rows = await reports.flaggedInRange(
      walletId: wallet,
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 8, 1),
    );
    expect(rows.map((r) => r.transaction.description).toSet(), {
      'Taxi',
      'Hotel',
    });
    expect(rows.fold(0, (s, r) => s + r.transaction.amountCents), 3000);
  });

  test(
    'createReport aggancia le spese del periodo e gestisce gli stati',
    () async {
      final a = await spesa(1000, DateTime(2026, 7, 5));
      await reports.setExpenseData(transactionId: a);

      final reportId = await reports.createReport(
        walletId: wallet,
        name: 'Trasferta Milano',
        from: DateTime(2026, 7, 1),
        to: DateTime(2026, 8, 1),
      );

      var all = await reports.getReports(wallet);
      expect(all.single.status, ExpenseReportStatus.draft);
      expect((await reports.dataOf(a))!.reportId, reportId);

      await reports.setStatus(reportId, ExpenseReportStatus.sent);
      // Rimborso: entrata collegata → stato rimborsata.
      final income = await txs.createIncome(
        walletId: wallet,
        amountCents: 1000,
        date: DateTime(2026, 8, 10),
        description: 'Rimborso trasferta',
      );
      await reports.linkReimbursement(reportId, income);
      all = await reports.getReports(wallet);
      expect(all.single.status, ExpenseReportStatus.reimbursed);
      expect(all.single.reimburseTxId, income);
    },
  );

  test(
    'pendingReimbursementCents somma le rimborsabili non ancora rimborsate',
    () async {
      final a = await spesa(1500, DateTime(2026, 7, 5));
      final b = await spesa(2500, DateTime(2026, 7, 6));
      final c = await spesa(9900, DateTime(2026, 7, 7));
      await reports.setExpenseData(transactionId: a); // rimborsabile default
      await reports.setExpenseData(transactionId: b, reimbursable: false);
      await reports.setExpenseData(transactionId: c);

      expect(await reports.pendingReimbursementCents(wallet), 1500 + 9900);

      // c finisce in una nota rimborsata → esce dal pending.
      final r = await reports.createReport(
        walletId: wallet,
        name: 'NS',
        from: DateTime(2026, 7, 7),
        to: DateTime(2026, 7, 8),
      );
      await reports.setStatus(r, ExpenseReportStatus.reimbursed);
      expect(await reports.pendingReimbursementCents(wallet), 1500);
    },
  );

  test('il PDF della nota spese viene generato', () async {
    final tx = await spesa(4250, DateTime(2026, 7, 10), desc: 'Pranzo cliente');
    await reports.setExpenseData(transactionId: tx);
    final rows = await reports.flaggedInRange(
      walletId: wallet,
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 8, 1),
    );

    final bytes = await buildExpenseReportPdf(
      walletName: 'Conto',
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 8, 1),
      rows: rows,
      categoriesById: const {},
      costCentersById: const {},
      attachmentsByTx: const {},
    );
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
