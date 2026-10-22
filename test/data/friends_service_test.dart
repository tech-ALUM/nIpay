import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/services/friends_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  group('friendLink / friendCodeFromScan', () {
    test('il QR contiene il link dell\'app con il codice', () {
      expect(friendLink('ABCDE23456'), 'com.alum.nipay://friend/ABCDE23456');
    });

    test('dal link del QR si ricava il codice', () {
      expect(
        friendCodeFromScan('com.alum.nipay://friend/ABCDE23456'),
        'ABCDE23456',
      );
    });

    test('un codice digitato a mano viene normalizzato', () {
      expect(friendCodeFromScan(' abcde-23456 '), 'ABCDE23456');
      expect(friendCodeFromScan('ABCDE 23456'), 'ABCDE23456');
    });

    test(
      'QR di altre app, link estranei e codici malformati: nessun codice',
      () {
        expect(
          friendCodeFromScan('https://example.com/friend/ABCDE23456'),
          isNull,
        );
        expect(friendCodeFromScan('com.alum.nipay://auth-callback'), isNull);
        expect(friendCodeFromScan('com.alum.nipay://friend/ABC'), isNull);
        expect(friendCodeFromScan('ABCDE2345O'), isNull, reason: 'O è ambigua');
        expect(friendCodeFromScan('WIFI:S:casa;P:segreta;;'), isNull);
        expect(friendCodeFromScan(''), isNull);
      },
    );
  });

  group('friendsErrorOf (errori del server tradotti, mai il testo grezzo)', () {
    FriendsErrorCode codeOf(String hint) =>
        friendsErrorOf(PostgrestException(message: 'x', hint: hint)).code;

    test('hint del server → categoria per la UI', () {
      expect(codeOf('not_available'), FriendsErrorCode.notAvailable);
      expect(codeOf('cooldown'), FriendsErrorCode.cooldown);
      expect(codeOf('too_many_pending'), FriendsErrorCode.tooManyPending);
      expect(codeOf('not_found'), FriendsErrorCode.notFound);
      expect(codeOf('rate_limited'), FriendsErrorCode.rateLimited);
    });

    test('rete assente → network; il resto → unknown', () {
      expect(
        friendsErrorOf(const SocketException('offline')).code,
        FriendsErrorCode.network,
      );
      expect(
        friendsErrorOf(const PostgrestException(message: 'boom')).code,
        FriendsErrorCode.unknown,
      );
    });
  });
}
