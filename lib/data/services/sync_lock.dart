import 'dart:async';

/// Mutex asincrono rientrante, condiviso da sync, logout e rimozione dei
/// dati locali (SECURITY_AUDIT NIP-14).
///
/// Senza, una sync in background (timer, resume, login) poteva girare in
/// parallelo a un'altra sync o a `wipe()`, e reinserire righe scaricate
/// (e il marchio di proprietà dell'account) DOPO la rimozione dei dati.
///
/// Rientrante: una sezione critica può chiamarne un'altra (es. il logout
/// con rimozione dei dati fa sync finale + wipe dentro lo stesso lock)
/// senza deadlock. La rientranza è legata alla Zone dell'azione, quindi
/// vale solo per il codice lanciato dentro [run].
class SyncLock {
  Future<void> _tail = Future.value();
  final Object _zoneKey = Object();

  /// True se il codice corrente gira già dentro il lock.
  bool get isHeldByCurrentZone => Zone.current[_zoneKey] == true;

  Future<T> run<T>(Future<T> Function() action) async {
    if (isHeldByCurrentZone) return action();

    final previous = _tail;
    final released = Completer<void>();
    _tail = released.future;
    try {
      await previous;
      return await runZoned(action, zoneValues: {_zoneKey: true});
    } finally {
      released.complete();
    }
  }
}
