import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../data/export/excel_codec.dart';
import '../../data/export/json_codec.dart';

String _stamp() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, "0")}${now.day.toString().padLeft(2, "0")}';
}

/// Export JSON; se ci sono allegati produce uno .zip con dentro
/// `nipay.json` + la cartella attachments/.
Future<void> exportJsonBackup(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final json = await exportToJson(db);
  final jsonBytes = utf8.encode(
    const JsonEncoder.withIndent('  ').convert(json),
  );
  final attachments = await db.select(db.attachments).get();
  final tmp = await getTemporaryDirectory();

  final File out;
  if (attachments.isEmpty) {
    out = File('${tmp.path}/nipay-backup-${_stamp()}.json');
    await out.writeAsBytes(jsonBytes);
  } else {
    final appDir = await ref.read(appDirProvider.future);
    final archive = Archive()
      ..addFile(ArchiveFile('nipay.json', jsonBytes.length, jsonBytes));
    for (final a in attachments) {
      final f = File('${appDir.path}/${a.relativePath}');
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        archive.addFile(ArchiveFile(a.relativePath, bytes.length, bytes));
      }
    }
    out = File('${tmp.path}/nipay-backup-${_stamp()}.zip');
    await out.writeAsBytes(ZipEncoder().encode(archive)!);
  }

  await SharePlus.instance.share(ShareParams(files: [XFile(out.path)]));
}

/// Export JSON del solo portafoglio attivo (zip se ha allegati).
Future<void> exportWalletBackup(WidgetRef ref) async {
  final active = ref.read(activeWalletProvider);
  if (active == null) return;
  final db = ref.read(databaseProvider);
  final json = await exportWalletToJson(db, active.id);
  final jsonBytes = utf8.encode(
    const JsonEncoder.withIndent('  ').convert(json),
  );
  final attachmentPaths = [
    for (final a in (json['attachments'] as List))
      (a as Map)['relativePath'] as String,
  ];
  final tmp = await getTemporaryDirectory();
  final safeName = active.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  final File out;
  if (attachmentPaths.isEmpty) {
    out = File('${tmp.path}/nipay-$safeName-${_stamp()}.json');
    await out.writeAsBytes(jsonBytes);
  } else {
    final appDir = await ref.read(appDirProvider.future);
    final archive = Archive()
      ..addFile(ArchiveFile('nipay.json', jsonBytes.length, jsonBytes));
    for (final rel in attachmentPaths) {
      final f = File('${appDir.path}/$rel');
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        archive.addFile(ArchiveFile(rel, bytes.length, bytes));
      }
    }
    out = File('${tmp.path}/nipay-$safeName-${_stamp()}.zip');
    await out.writeAsBytes(ZipEncoder().encode(archive)!);
  }
  await SharePlus.instance.share(ShareParams(files: [XFile(out.path)]));
}

/// Import ADDITIVO di un portafoglio (json o zip). Non tocca gli altri spazi.
Future<bool> importWalletBackup(WidgetRef ref) async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'nIpay wallet', extensions: ['json', 'zip']),
    ],
  );
  if (file == null) return false;
  final db = ref.read(databaseProvider);
  final bytes = await file.readAsBytes();

  Map<String, dynamic> json;
  if (file.name.toLowerCase().endsWith('.zip')) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.files
        .where((f) => f.name == 'nipay.json')
        .firstOrNull;
    if (entry == null) {
      throw const FormatException('nipay.json mancante nello zip');
    }
    json =
        jsonDecode(utf8.decode(entry.content as List<int>))
            as Map<String, dynamic>;
    final appDir = await ref.read(appDirProvider.future);
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('attachments/')) {
        final target = File('${appDir.path}/${f.name}');
        await target.create(recursive: true);
        await target.writeAsBytes(f.content as List<int>);
      }
    }
  } else {
    json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  final newId = await importWalletFromJson(db, json);
  ref.read(activeWalletIdProvider.notifier).set(newId);
  _invalidateAll(ref);
  return true;
}

/// Export Excel del solo portafoglio attivo.
Future<void> exportWalletExcelBackup(WidgetRef ref) async {
  final active = ref.read(activeWalletProvider);
  if (active == null) return;
  final bytes = await exportToExcel(
    ref.read(databaseProvider),
    walletId: active.id,
  );
  final tmp = await getTemporaryDirectory();
  final safeName = active.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final out = File('${tmp.path}/nipay-$safeName-${_stamp()}.xlsx');
  await out.writeAsBytes(bytes);
  await SharePlus.instance.share(ShareParams(files: [XFile(out.path)]));
}

Future<void> exportExcelBackup(WidgetRef ref) async {
  final bytes = await exportToExcel(ref.read(databaseProvider));
  final tmp = await getTemporaryDirectory();
  final out = File('${tmp.path}/nipay-export-${_stamp()}.xlsx');
  await out.writeAsBytes(bytes);
  await SharePlus.instance.share(ShareParams(files: [XFile(out.path)]));
}

/// Import JSON o zip. Ritorna false se l'utente annulla la selezione.
/// Lancia [FormatException] se il file non è valido.
Future<bool> importJsonBackup(WidgetRef ref) async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'nIpay backup', extensions: ['json', 'zip']),
    ],
  );
  if (file == null) return false;

  final db = ref.read(databaseProvider);
  final bytes = await file.readAsBytes();

  Map<String, dynamic> json;
  if (file.name.toLowerCase().endsWith('.zip')) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final jsonEntry = archive.files
        .where((f) => f.name == 'nipay.json')
        .firstOrNull;
    if (jsonEntry == null) {
      throw const FormatException('nipay.json mancante nello zip');
    }
    json =
        jsonDecode(utf8.decode(jsonEntry.content as List<int>))
            as Map<String, dynamic>;
    // Ripristina i file allegati nella dir dell'app.
    final appDir = await ref.read(appDirProvider.future);
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('attachments/')) {
        final target = File('${appDir.path}/${f.name}');
        await target.create(recursive: true);
        await target.writeAsBytes(f.content as List<int>);
      }
    }
  } else {
    json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  await importFromJson(db, json);
  _invalidateAll(ref);
  return true;
}

Future<bool> importExcelBackup(WidgetRef ref) async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Excel', extensions: ['xlsx']),
    ],
  );
  if (file == null) return false;
  await importFromExcel(ref.read(databaseProvider), await file.readAsBytes());
  _invalidateAll(ref);
  return true;
}

void _invalidateAll(WidgetRef ref) {
  // Gli StreamProvider (wallet, categorie, transazioni, dashboard) si
  // aggiornano da soli; i FutureProvider vanno invalidati a mano.
  ref
    ..invalidate(budgetsProvider)
    ..invalidate(tagsProvider)
    ..invalidate(customFieldDefsProvider)
    ..invalidate(recurringRulesProvider);
}
