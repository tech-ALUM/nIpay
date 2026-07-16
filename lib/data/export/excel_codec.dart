import 'package:excel/excel.dart';

import '../db/app_database.dart';

/// Fogli esportati e reimportabili (round-trip solo per file nIpay).
/// Le celle contengono i valori del JSON canonico di ogni riga, così
/// l'import riusa le stesse factory `fromJson` dei data class Drift.
const _sheets = ['Portafogli', 'Categorie', 'Transazioni', 'Budget'];

/// Con [walletId] esporta solo lo spazio di quel portafoglio.
Future<List<int>> exportToExcel(AppDatabase db, {String? walletId}) async {
  final excel = Excel.createExcel();

  Future<void> writeSheet(String name, List<Map<String, dynamic>> rows) async {
    final sheet = excel[name];
    if (rows.isEmpty) return;
    final keys = rows.first.keys.toList();
    sheet.appendRow([for (final k in keys) TextCellValue(k)]);
    for (final row in rows) {
      sheet.appendRow([for (final k in keys) _toCell(row[k])]);
    }
  }

  await writeSheet('Portafogli', [
    for (final r in await db.select(db.wallets).get())
      if (walletId == null || r.id == walletId) r.toJson(),
  ]);
  await writeSheet('Categorie', [
    for (final r in await db.select(db.categories).get())
      if (walletId == null || r.walletId == walletId) r.toJson(),
  ]);
  await writeSheet('Transazioni', [
    for (final r in await db.select(db.transactions).get())
      if (walletId == null ||
          r.walletId == walletId ||
          r.walletToId == walletId)
        r.toJson(),
  ]);
  await writeSheet('Budget', [
    for (final r in await db.select(db.budgets).get())
      if (walletId == null || r.walletId == walletId) r.toJson(),
  ]);

  excel.delete('Sheet1');
  return excel.encode()!;
}

CellValue? _toCell(dynamic v) => switch (v) {
  null => null,
  final int i => IntCellValue(i),
  final double d => DoubleCellValue(d),
  final bool b => BoolCellValue(b),
  _ => TextCellValue(v.toString()),
};

dynamic _fromCell(CellValue? v) => switch (v) {
  null => null,
  final IntCellValue i => i.value,
  final DoubleCellValue d => d.value,
  final BoolCellValue b => b.value,
  final TextCellValue t => t.value.text,
  _ => v.toString(),
};

/// Import da un .xlsx generato da nIpay: ripristina portafogli, categorie,
/// transazioni e budget (le altre entità restano intatte... no: vengono
/// azzerate le quattro tabelle coinvolte e reinserite).
Future<void> importFromExcel(AppDatabase db, List<int> bytes) async {
  final excel = Excel.decodeBytes(bytes);
  if (!_sheets.every(excel.sheets.containsKey)) {
    throw const FormatException('File Excel nIpay non valido');
  }

  List<Map<String, dynamic>> readSheet(String name) {
    final sheet = excel.sheets[name]!;
    if (sheet.rows.length < 2) return const [];
    final keys = [
      for (final c in sheet.rows.first) _fromCell(c?.value) as String?,
    ];
    return [
      for (final row in sheet.rows.skip(1))
        {
          for (var i = 0; i < keys.length; i++)
            if (keys[i] != null)
              keys[i]!: i < row.length ? _fromCell(row[i]?.value) : null,
        },
    ];
  }

  await db.transaction(() async {
    await db.delete(db.budgets).go();
    await db.delete(db.transactions).go();
    await db.delete(db.categories).go();
    await db.delete(db.wallets).go();

    await db.batch((b) {
      b.insertAll(db.wallets, readSheet('Portafogli').map(Wallet.fromJson));
      b.insertAll(db.categories, readSheet('Categorie').map(Category.fromJson));
      b.insertAll(
        db.transactions,
        readSheet('Transazioni').map(Transaction.fromJson),
      );
      b.insertAll(db.budgets, readSheet('Budget').map(Budget.fromJson));
    });
  });
}
