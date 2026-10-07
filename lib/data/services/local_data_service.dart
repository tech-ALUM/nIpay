import 'dart:io';

import '../db/app_database.dart';
import 'sync_lock.dart';

/// Rimozione dei dati personali da questo device: usata al logout (se
/// l'utente lo sceglie) e quando i dati locali appartengono a un altro
/// account (vedi `LocalDataOwnedByAnotherUserException`).
abstract interface class LocalDataService {
  /// Cancella fisicamente tutte le righe del DB locale — incluse quelle
  /// soft-deleted e gli stati di sync, che sono il marchio di proprietà
  /// del device — e i file degli allegati. Le preferenze del dispositivo
  /// (tema, lingua, cache tassi) restano.
  Future<void> wipe();
}

class DeviceLocalDataService implements LocalDataService {
  /// [_appDir] restituisce la directory documenti dell'app (base dei path
  /// relativi degli allegati). [lock] è lo stesso della sync: una sync in
  /// background non può reinserire righe (o il marchio di proprietà
  /// dell'account) dopo la rimozione (SECURITY_AUDIT NIP-14).
  DeviceLocalDataService(this._db, this._appDir, {SyncLock? lock})
    : _lock = lock ?? SyncLock();

  final AppDatabase _db;
  final Future<Directory> Function() _appDir;
  final SyncLock _lock;

  @override
  Future<void> wipe() => _lock.run(_wipeLocked);

  Future<void> _wipeLocked() async {
    await _db.transaction(() async {
      // `allTables` è in ordine di dichiarazione (genitori prima dei
      // figli): al contrario si cancellano prima i figli, così nessuna
      // foreign key locale viene violata.
      for (final table in _db.allTables.toList().reversed) {
        await _db.delete(table).go();
      }
    });

    // Stesso path usato da add_transaction_sheet.dart per salvare le foto.
    final attachments = Directory('${(await _appDir()).path}/attachments');
    if (await attachments.exists()) {
      await attachments.delete(recursive: true);
    }
  }
}
