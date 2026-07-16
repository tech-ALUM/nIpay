import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/money.dart';
import '../db/app_database.dart';
import '../repositories/expense_report_repository.dart';

/// Importi nel PDF: i font Type1 non hanno €/NBSP/minus tipografico.
String _pdfAmount(int cents) =>
    formatCents(cents).replaceAll(' €', ' EUR').replaceAll('−', '-');

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}';

const _coral = PdfColor.fromInt(0xFFFF6F61);
const _ink = PdfColor.fromInt(0xFF15181D);

/// Genera il PDF della nota spese: intestazione, tabella spese e
/// giustificativi (foto scontrini) in appendice, numerati e riferiti.
Future<Uint8List> buildExpenseReportPdf({
  required String walletName,
  required DateTime from,
  required DateTime to,
  required List<FlaggedExpense> rows,
  required Map<String, Category> categoriesById,
  required Map<String, CostCenter> costCentersById,
  required Map<String, List<Uint8List>> attachmentsByTx,
  String? reportName,
}) async {
  final doc = pw.Document();
  final total = rows.fold(0, (s, r) => s + r.transaction.amountCents);
  final reimbursable = rows
      .where((r) => r.entry.reimbursable)
      .fold(0, (s, r) => s + r.transaction.amountCents);

  // Numerazione giustificativi: G1, G2... nell'ordine delle righe.
  final receiptNumbers = <String, List<int>>{};
  var receiptCounter = 0;
  for (final r in rows) {
    final images = attachmentsByTx[r.transaction.id] ?? const [];
    receiptNumbers[r.transaction.id] = [
      for (var i = 0; i < images.length; i++) ++receiptCounter,
    ];
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'nIpay - pag. ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
      ),
      build: (ctx) => [
        pw.Text(
          reportName ?? 'Nota spese',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Portafoglio: $walletName  |  Periodo: ${_d(from)} - ${_d(to.subtract(const Duration(days: 1)))}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Divider(color: _coral, thickness: 2),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          headerStyle: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(52),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FixedColumnWidth(30),
            5: const pw.FixedColumnWidth(30),
            6: const pw.FixedColumnWidth(35),
            7: const pw.FixedColumnWidth(60),
          },
          headers: [
            'Data',
            'Descrizione',
            'Categoria',
            'Centro di costo',
            'Rimb.',
            'F.E.',
            'Giust.',
            'Importo',
          ],
          data: [
            for (final r in rows)
              [
                _d(r.transaction.date),
                r.transaction.description,
                categoriesById[r.transaction.categoryId]?.name ?? '-',
                costCentersById[r.entry.costCenterId]?.name ?? '-',
                r.entry.reimbursable ? 'SI' : 'NO',
                r.entry.eInvoice ? 'SI' : 'NO',
                (receiptNumbers[r.transaction.id] ?? [])
                    .map((n) => 'G$n')
                    .join(','),
                _pdfAmount(r.transaction.amountCents),
              ],
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Totale: ${_pdfAmount(total)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'di cui rimborsabile: ${_pdfAmount(reimbursable)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _coral,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // Appendice giustificativi: una pagina per foto, con riferimento.
  for (final r in rows) {
    final images = attachmentsByTx[r.transaction.id] ?? const [];
    final numbers = receiptNumbers[r.transaction.id]!;
    for (var i = 0; i < images.length; i++) {
      final image = pw.MemoryImage(images[i]);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Giustificativo G${numbers[i]} - ${_d(r.transaction.date)} - '
                '${r.transaction.description} - '
                '${_pdfAmount(r.transaction.amountCents)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  return doc.save();
}
