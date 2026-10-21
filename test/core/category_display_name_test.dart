import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/ui/category_name.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/category_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';
import 'package:nipay/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repo;
  late String wallet;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftCategoryRepository(db);
    wallet = await DriftWalletRepository(
      db,
    ).create(name: 'Conto', colorHex: '#0E7C86');
    await repo.seedDefaults(wallet);
  });

  tearDown(() async => db.close());

  test('every default category has a translation in every language', () async {
    final defaults = await repo.getAll(wallet);
    expect(defaults, hasLength(kDefaultCategories.length));
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      final names = {for (final c in defaults) c.displayName(l10n)};
      // Nessun nome perso e nessun doppione nella stessa lingua.
      expect(names, hasLength(defaults.length), reason: '$locale');
    }
  });

  test('default categories follow the app language', () async {
    final en = lookupAppLocalizations(const Locale('en'));
    final it = lookupAppLocalizations(const Locale('it'));
    final groceries = (await repo.getAll(
      wallet,
    )).firstWhere((c) => c.name == 'Spesa');

    expect(groceries.displayName(en), 'Groceries');
    expect(groceries.displayName(it), 'Spesa');
    expect(groceries.label(en), '🛒 Groceries');
  });

  test(
    'a renamed default category keeps the name chosen by the user',
    () async {
      final en = lookupAppLocalizations(const Locale('en'));
      final groceries = (await repo.getAll(
        wallet,
      )).firstWhere((c) => c.name == 'Spesa');
      await repo.update(groceries.id, name: 'Supermercato');

      final renamed = (await repo.getAll(
        wallet,
      )).firstWhere((c) => c.id == groceries.id);
      expect(renamed.displayName(en), 'Supermercato');
    },
  );

  test('a custom category is never translated', () async {
    final en = lookupAppLocalizations(const Locale('en'));
    final id = await repo.create(
      walletId: wallet,
      name: 'Spesa',
      icon: '🛒',
      colorHex: '#FF6F61',
      kind: CategoryKind.expense,
    );
    final custom = (await repo.getAll(wallet)).firstWhere((c) => c.id == id);
    expect(custom.displayName(en), 'Spesa');
  });
}
