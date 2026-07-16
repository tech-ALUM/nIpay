import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/attachment_repository.dart';
import 'package:nipay/data/repositories/dashboard_repository.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

void main() {
  late AppDatabase db;
  late String wallet;
  late String txId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    wallet = await DriftWalletRepository(
      db,
    ).create(name: 'Conto', colorHex: '#0E7C86');
    txId = await DriftTransactionRepository(db).createExpense(
      walletId: wallet,
      amountCents: 4250,
      date: DateTime(2026, 7, 15),
    );
  });

  tearDown(() async => db.close());

  test('adds an attachment and lists it for the transaction', () async {
    final repo = DriftAttachmentRepository(db);
    await repo.add(
      transactionId: txId,
      relativePath: 'attachments/scontrino1.jpg',
      mimeType: 'image/jpeg',
    );

    final list = await repo.listOf(txId);
    expect(list.single.relativePath, 'attachments/scontrino1.jpg');
  });

  test('dashboard cards persist type, order and config', () async {
    final repo = DriftDashboardRepository(db);
    await repo.addCard(
      walletId: wallet,
      type: 'categoryDonut',
      configJson: '{"period":"month"}',
    );
    final trendId = await repo.addCard(
      walletId: wallet,
      type: 'trend',
      configJson: '{"months":6}',
    );

    var cards = await repo.getCards(wallet);
    expect(cards.map((c) => c.type), ['categoryDonut', 'trend']);

    await repo.moveCard(trendId, 0);
    cards = await repo.getCards(wallet);
    expect(cards.map((c) => c.type), ['trend', 'categoryDonut']);
    expect(cards.first.configJson, '{"months":6}');
  });
}
