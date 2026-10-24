import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Quota di un partecipante di una spesa divisa (M-SOC4).
typedef ShareInput = ({String userId, int shareCents});

/// Categoria di errore per la UI (SECURITY_AUDIT NIP-17: mai il testo
/// grezzo del server).
enum SharedExpenseErrorCode {
  invalidExpense,
  invalidShares,
  noParticipants,
  tooManyParticipants,
  notAvailable,
  invalidPayer,
  locked,
  notFound,
  amountTooHigh,
  invalidAmount,
  rateLimited,
  network,
  unknown,
}

class SharedExpenseException implements Exception {
  const SharedExpenseException(this.code);

  final SharedExpenseErrorCode code;

  @override
  String toString() => 'SharedExpenseException(${code.name})';
}

abstract interface class SharedExpenseService {
  /// Crea la spesa divisa sul server (la mia quota nasce registrata).
  /// Importi in centesimi della valuta [currency]. Restituisce l'id.
  Future<String> create({
    required String? description,
    required int totalCents,
    required String currency,
    required DateTime spentOn,
    required String paidBy,
    required List<ShareInput> shares,
  });

  /// Solo chi l'ha creata, finché nessun altro ha registrato la quota.
  Future<void> delete(String expenseId);
}

SharedExpenseException sharedExpenseErrorOf(Object error) => switch (error) {
  SharedExpenseException() => error,
  sb.PostgrestException(:final hint) => SharedExpenseException(switch (hint) {
    'invalid_expense' => SharedExpenseErrorCode.invalidExpense,
    'invalid_shares' => SharedExpenseErrorCode.invalidShares,
    'no_participants' => SharedExpenseErrorCode.noParticipants,
    'too_many_participants' => SharedExpenseErrorCode.tooManyParticipants,
    'not_available' => SharedExpenseErrorCode.notAvailable,
    'invalid_payer' => SharedExpenseErrorCode.invalidPayer,
    'locked' => SharedExpenseErrorCode.locked,
    'not_found' => SharedExpenseErrorCode.notFound,
    'amount_too_high' => SharedExpenseErrorCode.amountTooHigh,
    'invalid_amount' => SharedExpenseErrorCode.invalidAmount,
    'rate_limited' => SharedExpenseErrorCode.rateLimited,
    _ => SharedExpenseErrorCode.unknown,
  }),
  SocketException() || http.ClientException() || TimeoutException() =>
    const SharedExpenseException(SharedExpenseErrorCode.network),
  _ => const SharedExpenseException(SharedExpenseErrorCode.unknown),
};

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class SupabaseSharedExpenseService implements SharedExpenseService {
  SupabaseSharedExpenseService(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<String> create({
    required String? description,
    required int totalCents,
    required String currency,
    required DateTime spentOn,
    required String paidBy,
    required List<ShareInput> shares,
  }) => _guard(
    () => _client.rpc<String>(
      'create_shared_expense',
      params: {
        'description': description,
        'total_cents': totalCents,
        'currency': currency,
        'spent_on': _isoDate(spentOn),
        'paid_by': paidBy,
        'shares': [
          for (final s in shares)
            {'user_id': s.userId, 'share_cents': s.shareCents},
        ],
      },
    ),
  );

  @override
  Future<void> delete(String expenseId) => _guard(
    () => _client.rpc<void>(
      'delete_shared_expense',
      params: {'target': expenseId},
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw sharedExpenseErrorOf(e);
    }
  }
}
