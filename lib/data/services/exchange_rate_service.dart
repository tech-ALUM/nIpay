import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Lanciata quando nessun tasso di cambio è disponibile: né in cache né via
/// rete. Capita solo se l'app non ha MAI scaricato i tassi con successo
/// (es. primo avvio offline) — una volta che una cache esiste, viene
/// sempre riusata anche senza connessione, e questa eccezione non scatta più.
class ExchangeRateException implements Exception {
  const ExchangeRateException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ExchangeRateService {
  /// Tasso per convertire un importo da [from] a [to] (1.0 se from == to).
  /// Lancia [ExchangeRateException] se nessun tasso è mai stato ottenuto.
  Future<double> getRate({required String from, required String to});
}

/// Tassi scaricati al massimo una volta al giorno (Frankfurter, ECB, senza
/// chiave API) e tenuti in cache locale (SharedPreferences): [getRate] non
/// fa mai una chiamata di rete bloccante se una cache esiste già, che sia di
/// oggi o di giorni fa — l'app resta utilizzabile offline indefinitamente.
/// L'aggiornamento del giorno, se dovuto, parte in background senza
/// bloccare la conversione in corso.
class CachedExchangeRateService implements ExchangeRateService {
  CachedExchangeRateService({required SharedPreferences prefs, http.Client? client})
    : _prefs = prefs,
      _client = client ?? http.Client();

  static const _ratesKey = 'exchangeRates.ratesJson';
  static const _dateKey = 'exchangeRates.fetchedOn';

  static final _currencyCode = RegExp(r'^[A-Z]{3}$');

  /// Un tasso (unità di valuta per 1 EUR) fuori da questo intervallo non è
  /// plausibile per nessuna valuta reale: un valore 0, negativo o enorme
  /// (servizio compromesso, risposta corrotta) altererebbe in modo
  /// permanente gli importi salvati (SECURITY_AUDIT NIP-23).
  static bool _plausible(double rate) =>
      rate.isFinite && rate >= 1e-3 && rate <= 1e6;

  /// Variazione massima accettata rispetto alla cache in un aggiornamento:
  /// oltre si tiene la cache e si riprova il giorno dopo.
  static const _maxDailyChange = 1.5;

  final SharedPreferences _prefs;
  final http.Client _client;

  @override
  Future<double> getRate({required String from, required String to}) async {
    if (from == to) return 1.0;
    var rates = _readCachedRates();
    if (rates == null) {
      // Nessuna cache pregressa: qui il fetch è per forza bloccante, non
      // c'è alcun tasso da cui partire.
      rates = await _fetchAndStore();
    } else if (_prefs.getString(_dateKey) != _today()) {
      // Cache presente ma non di oggi: si aggiorna in background per la
      // prossima chiamata; questa usa comunque subito quella che c'è,
      // online o offline che sia.
      unawaited(_fetchAndStore().catchError((_) => rates!));
    }
    return _crossRate(rates, from, to);
  }

  double _crossRate(Map<String, double> rates, String from, String to) {
    final r1 = rates[from];
    final r2 = rates[to];
    if (r1 == null || r2 == null) {
      throw ExchangeRateException(
        'Tasso di cambio non disponibile per $from/$to',
      );
    }
    return r2 / r1;
  }

  Map<String, double>? _readCachedRates() {
    final json = _prefs.getString(_ratesKey);
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final rates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      return rates.values.every(_plausible) ? rates : null;
    } catch (_) {
      return null; // cache illeggibile: come se non ci fosse
    }
  }

  String _today() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<Map<String, double>> _fetchAndStore() async {
    final uri = Uri.https('api.frankfurter.dev', '/v1/latest', {
      'base': 'EUR',
    });
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw ExchangeRateException(
          'Servizio tassi di cambio non disponibile (${response.statusCode})',
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rawRates = body['rates'] as Map<String, dynamic>?;
      if (rawRates == null) {
        throw const ExchangeRateException(
          'Risposta del servizio tassi di cambio non valida',
        );
      }
      final rates = <String, double>{'EUR': 1.0};
      for (final entry in rawRates.entries) {
        final value = entry.value;
        if (!_currencyCode.hasMatch(entry.key) || value is! num) continue;
        if (!_plausible(value.toDouble())) {
          throw const ExchangeRateException(
            'Risposta del servizio tassi di cambio non valida',
          );
        }
        rates[entry.key] = value.toDouble();
      }
      final previous = _readCachedRates();
      if (previous != null) {
        for (final MapEntry(key: code, value: rate) in rates.entries) {
          final old = previous[code];
          if (old == null) continue;
          final change = rate / old;
          if (change > _maxDailyChange || change < 1 / _maxDailyChange) {
            throw const ExchangeRateException(
              'Variazione anomala dei tassi di cambio: aggiornamento scartato',
            );
          }
        }
      }
      await _prefs.setString(_ratesKey, jsonEncode(rates));
      await _prefs.setString(_dateKey, _today());
      return rates;
    } on ExchangeRateException {
      rethrow;
    } catch (_) {
      throw const ExchangeRateException(
        'Impossibile ottenere il tasso di cambio: controlla la connessione',
      );
    }
  }
}
