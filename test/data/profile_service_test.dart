import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  group('formatFriendCode', () {
    test('divide il codice in due gruppi da 5', () {
      expect(formatFriendCode('ABCDE23456'), 'ABCDE-23456');
    });

    test('lascia com\'è un valore inatteso', () {
      expect(formatFriendCode('ABC'), 'ABC');
    });
  });

  group('profileErrorOf (errori del server tradotti, mai il testo grezzo)', () {
    test('hint rate_limited → rateLimited', () {
      expect(
        profileErrorOf(
          const PostgrestException(
            message: 'troppe richieste',
            hint: 'rate_limited',
          ),
        ).code,
        ProfileErrorCode.rateLimited,
      );
    });

    test('hint invalid_display_name → invalidDisplayName', () {
      expect(
        profileErrorOf(
          const PostgrestException(
            message: 'nome non valido',
            hint: 'invalid_display_name',
          ),
        ).code,
        ProfileErrorCode.invalidDisplayName,
      );
    });

    test('errore di rete → network', () {
      expect(
        profileErrorOf(const SocketException('offline')).code,
        ProfileErrorCode.network,
      );
    });

    test('qualunque altro errore → unknown', () {
      expect(
        profileErrorOf(const PostgrestException(message: 'boom')).code,
        ProfileErrorCode.unknown,
      );
      expect(profileErrorOf(StateError('x')).code, ProfileErrorCode.unknown);
    });
  });
}
