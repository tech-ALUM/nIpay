import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/attachment_repository.dart';
import 'package:nipay/data/repositories/category_repository.dart';
import 'package:nipay/data/repositories/tag_repository.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';
import 'package:nipay/data/services/local_data_service.dart';

void main() {
  late AppDatabase db;
  late Directory appDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    appDir = await Directory.systemTemp.createTemp('nipay_wipe_');
  });

  tearDown(() async {
    await db.close();
    if (await appDir.exists()) await appDir.delete(recursive: true);
  });

  test('wipe removes every row of every table, soft-deleted ones and the '
      'sync ownership marker included', () async {
    final walletId = await DriftWalletRepository(
      db,
    ).create(name: 'Conto', colorHex: '#000000');
    await DriftCategoryRepository(db).seedDefaults(walletId);
    final transactions = DriftTransactionRepository(db);
    final txId = await transactions.createExpense(
      walletId: walletId,
      amountCents: 1250,
      date: DateTime(2026, 9, 1),
    );
    final deletedTx = await transactions.createExpense(
      walletId: walletId,
      amountCents: 99,
      date: DateTime(2026, 9, 2),
    );
    await transactions.softDelete(deletedTx);
    final tags = DriftTagRepository(db);
    await tags.tagTransaction(
      txId,
      await tags.create('lavoro', walletId: walletId),
    );
    await DriftAttachmentRepository(db).add(
      transactionId: txId,
      relativePath: 'attachments/scontrino.jpg',
      mimeType: 'image/jpeg',
    );
    await db
        .into(db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            userId: 'user-1',
            lastPushedAt: DateTime.utc(2026),
            lastPulledAt: DateTime.utc(2026),
          ),
        );

    await DeviceLocalDataService(db, () async => appDir).wipe();

    for (final table in db.allTables) {
      final count = await db
          .customSelect('SELECT COUNT(*) AS c FROM ${table.actualTableName}')
          .map((row) => row.read<int>('c'))
          .getSingle();
      expect(count, 0, reason: 'tabella ${table.actualTableName}');
    }
  });

  test('wipe deletes the receipt photos but nothing else in the app '
      'directory', () async {
    final attachments = Directory('${appDir.path}/attachments')..createSync();
    File('${attachments.path}/scontrino.jpg').writeAsBytesSync([1, 2, 3]);
    final unrelated = File('${appDir.path}/altro.txt')..writeAsStringSync('x');

    await DeviceLocalDataService(db, () async => appDir).wipe();

    expect(attachments.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
  });

  test('wipe works when there are no attachments at all', () async {
    await DeviceLocalDataService(db, () async => appDir).wipe();
    expect(await db.select(db.wallets).get(), isEmpty);
  });
}
