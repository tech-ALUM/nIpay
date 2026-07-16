import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/custom_field_repository.dart';
import 'package:nipay/data/repositories/tag_repository.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

void main() {
  late AppDatabase db;
  late TagRepository tags;
  late CustomFieldRepository fields;
  late String txId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tags = DriftTagRepository(db);
    fields = DriftCustomFieldRepository(db);
    final wallet = await DriftWalletRepository(
      db,
    ).create(name: 'Conto', colorHex: '#0E7C86');
    txId = await DriftTransactionRepository(db).createExpense(
      walletId: wallet,
      amountCents: 4250,
      date: DateTime(2026, 7, 15),
    );
  });

  tearDown(() async => db.close());

  test('tags a transaction and reads tags back', () async {
    final casa = await tags.create('casa');
    await tags.create('auto');
    await tags.tagTransaction(txId, casa);

    final ofTx = await tags.tagsOf(txId);
    expect(ofTx.map((t) => t.name), ['casa']);
  });

  test('tagging is idempotent per (transaction, tag)', () async {
    final casa = await tags.create('casa');
    await tags.tagTransaction(txId, casa);
    await tags.tagTransaction(txId, casa);

    expect(await tags.tagsOf(txId), hasLength(1));
  });

  test('defines a custom field and sets a value on a transaction', () async {
    final fieldId = await fields.define(
      name: 'Metodo pagamento',
      type: CustomFieldType.choice,
      options: ['Carta', 'Contanti', 'Bonifico'],
    );
    await fields.setValue(
      transactionId: txId,
      fieldId: fieldId,
      value: 'Carta',
    );

    final values = await fields.valuesOf(txId);
    expect(values, hasLength(1));
    expect(values.first.value, 'Carta');

    final defs = await fields.getDefinitions();
    expect(defs.single.options, ['Carta', 'Contanti', 'Bonifico']);
  });

  test('transactionIdsWithTag returns only tagged transactions', () async {
    final casa = await tags.create('casa');
    await tags.tagTransaction(txId, casa);

    expect(await tags.transactionIdsWithTag(casa), {txId});
    final altro = await tags.create('altro');
    expect(await tags.transactionIdsWithTag(altro), isEmpty);
  });

  test(
    'transactionIdsMatching finds transactions by custom field value',
    () async {
      final fieldId = await fields.define(
        name: 'Luogo',
        type: CustomFieldType.text,
      );
      await fields.setValue(
        transactionId: txId,
        fieldId: fieldId,
        value: 'Milano Centrale',
      );

      expect(await fields.transactionIdsMatching('milano'), {txId});
      expect(await fields.transactionIdsMatching('roma'), isEmpty);
    },
  );

  test('setValue overwrites the previous value for the same field', () async {
    final fieldId = await fields.define(
      name: 'Luogo',
      type: CustomFieldType.text,
    );
    await fields.setValue(
      transactionId: txId,
      fieldId: fieldId,
      value: 'Milano',
    );
    await fields.setValue(
      transactionId: txId,
      fieldId: fieldId,
      value: 'Lecco',
    );

    final values = await fields.valuesOf(txId);
    expect(values.single.value, 'Lecco');
  });
}
