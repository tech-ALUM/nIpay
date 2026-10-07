import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nipay/data/services/exchange_rate_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tassi fissi per i test: nessuna chiamata di rete.
class FakeExchangeRateService implements ExchangeRateService {
  FakeExchangeRateService(this.rates);

  final Map<(String, String), double> rates;

  @override
  Future<double> getRate({required String from, required String to}) async {
    if (from == to) return 1.0;
    final rate = rates[(from, to)];
    if (rate == null) {
      throw ExchangeRateException('Nessun tasso per $from → $to');
    }
    return rate;
  }
}

void main() {
  test('same currency returns rate 1.0 without lookup', () async {
    final service = FakeExchangeRateService(const {});
    expect(await service.getRate(from: 'EUR', to: 'EUR'), 1.0);
  });

  test('returns the configured rate for a known pair', () async {
    final service = FakeExchangeRateService({('USD', 'EUR'): 0.92});
    expect(await service.getRate(from: 'USD', to: 'EUR'), 0.92);
  });

  test('throws ExchangeRateException for an unknown pair', () async {
    final service = FakeExchangeRateService(const {});
    expect(
      () => service.getRate(from: 'USD', to: 'EUR'),
      throwsA(isA<ExchangeRateException>()),
    );
  });

  group('CachedExchangeRateService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test(
      'no cache: blocks on a fetch, then computes the cross rate',
      () async {
        var calls = 0;
        final client = MockClient((request) async {
          calls++;
          return http.Response(
            jsonEncode({
              'amount': 1,
              'base': 'EUR',
              'rates': {'USD': 1.1, 'GBP': 0.9},
            }),
            200,
          );
        });
        final service = CachedExchangeRateService(prefs: prefs, client: client);

        // 1 EUR = 1.1 USD, 1 EUR = 0.9 GBP → 1 USD = 0.9/1.1 GBP.
        final rate = await service.getRate(from: 'USD', to: 'GBP');
        expect(rate, closeTo(0.9 / 1.1, 1e-9));
        expect(calls, 1);
      },
    );

    test(
      'no cache and the fetch fails: throws, nothing cached',
      () async {
        final client = MockClient(
          (request) async => http.Response('error', 500),
        );
        final service = CachedExchangeRateService(prefs: prefs, client: client);
        expect(
          () => service.getRate(from: 'USD', to: 'EUR'),
          throwsA(isA<ExchangeRateException>()),
        );
      },
    );

    test(
      'cache from today: never touches the network again',
      () async {
        var calls = 0;
        final client = MockClient((request) async {
          calls++;
          return http.Response(
            jsonEncode({
              'amount': 1,
              'base': 'EUR',
              'rates': {'USD': 1.1},
            }),
            200,
          );
        });
        final service = CachedExchangeRateService(prefs: prefs, client: client);

        await service.getRate(from: 'USD', to: 'EUR'); // popola la cache
        expect(calls, 1);
        await service.getRate(from: 'USD', to: 'EUR'); // stessa giornata
        await service.getRate(from: 'EUR', to: 'USD');
        expect(calls, 1); // nessuna nuova chiamata di rete
      },
    );

    test(
      'stale cache (offline): returns the old rate instead of blocking or '
      'throwing',
      () async {
        // Precarica una cache "di ieri" direttamente in SharedPreferences,
        // così il servizio la trova già scaduta al primo getRate.
        await prefs.setString(
          'exchangeRates.ratesJson',
          jsonEncode({'EUR': 1.0, 'USD': 1.2}),
        );
        await prefs.setString('exchangeRates.fetchedOn', '2000-01-01');

        // Il tentativo di refresh in background fallisce (rete assente):
        // non deve né bloccare né far fallire questa chiamata.
        final client = MockClient(
          (request) async => http.Response('offline', 500),
        );
        final service = CachedExchangeRateService(prefs: prefs, client: client);

        final rate = await service.getRate(from: 'EUR', to: 'USD');
        expect(rate, 1.2); // la cache vecchia, usata comunque
      },
    );

    group('SECURITY_AUDIT NIP-23: tassi non plausibili', () {
      MockClient respondWith(Map<String, Object?> rates) => MockClient(
        (request) async => http.Response(
          jsonEncode({'amount': 1, 'base': 'EUR', 'rates': rates}),
          200,
        ),
      );

      for (final bad in <Object>[0, -1.1, 1e12]) {
        test('a rate of $bad is rejected and nothing is cached', () async {
          final service = CachedExchangeRateService(
            prefs: prefs,
            client: respondWith({'USD': bad, 'GBP': 0.9}),
          );
          await expectLater(
            service.getRate(from: 'EUR', to: 'USD'),
            throwsA(isA<ExchangeRateException>()),
          );
          expect(prefs.getString('exchangeRates.ratesJson'), isNull);
        });
      }

      test('an anomalous jump versus the cache is discarded: the old rate '
          'stays', () async {
        await prefs.setString(
          'exchangeRates.ratesJson',
          jsonEncode({'EUR': 1.0, 'USD': 1.1}),
        );
        await prefs.setString('exchangeRates.fetchedOn', '2000-01-01');
        final service = CachedExchangeRateService(
          prefs: prefs,
          client: respondWith({'USD': 11.0}),
        );

        expect(await service.getRate(from: 'EUR', to: 'USD'), 1.1);
        await Future<void>.delayed(Duration.zero); // refresh in background
        expect(await service.getRate(from: 'EUR', to: 'USD'), 1.1);
        expect(prefs.getString('exchangeRates.fetchedOn'), '2000-01-01');
      });

      test('a normal daily change is accepted', () async {
        await prefs.setString(
          'exchangeRates.ratesJson',
          jsonEncode({'EUR': 1.0, 'USD': 1.1}),
        );
        await prefs.setString('exchangeRates.fetchedOn', '2000-01-01');
        final service = CachedExchangeRateService(
          prefs: prefs,
          client: respondWith({'USD': 1.12}),
        );
        await service.getRate(from: 'EUR', to: 'USD');
        await Future<void>.delayed(Duration.zero);
        expect(await service.getRate(from: 'EUR', to: 'USD'), 1.12);
      });
    });

    test('same currency returns 1.0 without any cache or network', () async {
      final client = MockClient(
        (request) async => throw StateError('non doveva chiamare la rete'),
      );
      final service = CachedExchangeRateService(prefs: prefs, client: client);
      expect(await service.getRate(from: 'EUR', to: 'EUR'), 1.0);
    });
  });
}
