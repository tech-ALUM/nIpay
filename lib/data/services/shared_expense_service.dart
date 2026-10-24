import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Quota di un partecipante di una spesa divisa (M-SOC4).
typedef ShareInput = ({String userId, int shareCents});

/// Quota di un partecipante in una spesa letta dal server; [userId] null =
/// account cancellato.
class SharedExpenseShare {
  const SharedExpenseShare({
    required this.userId,
    required this.displayName,
    required this.shareCents,
    required this.registered,
  });

  final String? userId;
  final String? displayName;
  final int shareCents;
  final bool registered;
}

/// Una spesa divisa a cui partecipo. [locked]: un altro partecipante ha già
/// registrato la sua quota, quindi non si modifica più.
class SharedExpense {
  const SharedExpense({
    required this.id,
    required this.createdBy,
    required this.paidBy,
    required this.payerDisplayName,
    required this.description,
    required this.totalCents,
    required this.currency,
    required this.spentOn,
    required this.myShareCents,
    required this.myShareRegistered,
    required this.locked,
    required this.shares,
  });

  final String id;
  final String? createdBy;
  final String? paidBy;
  final String? payerDisplayName;
  final String? description;
  final int totalCents;
  final String currency;
  final DateTime spentOn;
  final int myShareCents;
  final bool myShareRegistered;
  final bool locked;
  final List<SharedExpenseShare> shares;
}

/// Saldo con una persona in una valuta: positivo = mi deve, negativo = le
/// devo. [userId] null = account cancellato.
class FriendBalance {
  const FriendBalance({
    required this.userId,
    required this.displayName,
    required this.currency,
    required this.balanceCents,
    required this.isFriend,
  });

  final String? userId;
  final String? displayName;
  final String currency;
  final int balanceCents;
  final bool isFriend;
}

enum SettlementDirection { incoming, outgoing }

enum SettlementStatus { pending, confirmed, declined }

/// Un rimborso: [outgoing] l'ho pagato io, [incoming] lo ricevo.
/// [myRegistered]: la mia parte è già nel mio portafoglio.
class Settlement {
  const Settlement({
    required this.id,
    required this.direction,
    required this.userId,
    required this.displayName,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.myRegistered,
  });

  final String id;
  final SettlementDirection direction;
  final String? userId;
  final String? displayName;
  final int amountCents;
  final String currency;
  final SettlementStatus status;
  final DateTime createdAt;
  final bool myRegistered;
}

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
  Future<void> update(
    String expenseId, {
    required String? description,
    required int totalCents,
    required String currency,
    required DateTime spentOn,
    required String paidBy,
    required List<ShareInput> shares,
  });

  /// Solo chi l'ha creata, finché nessun altro ha registrato la quota.
  Future<void> delete(String expenseId);

  Future<List<SharedExpense>> list();
  Future<List<FriendBalance>> balances();
  Future<List<Settlement>> settlements();

  /// Dopo aver creato i movimenti nel portafoglio scelto.
  Future<void> registerMyShare(String expenseId);

  /// Rimborso di quanto devo a [toUser] (fino al debito); conta quando
  /// l'altro lo conferma.
  Future<String> recordSettlement({
    required String toUser,
    required int amountCents,
    required String currency,
  });
  Future<void> respondSettlement(String settlementId, {required bool accept});
  Future<void> cancelSettlement(String settlementId);

  /// Dopo aver registrato nel portafoglio un rimborso confermato.
  Future<void> registerMySettlement(String settlementId);
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
      params: _expenseParams(
        description: description,
        totalCents: totalCents,
        currency: currency,
        spentOn: spentOn,
        paidBy: paidBy,
        shares: shares,
      ),
    ),
  );

  Map<String, dynamic> _expenseParams({
    required String? description,
    required int totalCents,
    required String currency,
    required DateTime spentOn,
    required String paidBy,
    required List<ShareInput> shares,
  }) => {
    'description': description,
    'total_cents': totalCents,
    'currency': currency,
    'spent_on': _isoDate(spentOn),
    'paid_by': paidBy,
    'shares': [
      for (final s in shares)
        {'user_id': s.userId, 'share_cents': s.shareCents},
    ],
  };

  Future<List<Map<String, dynamic>>> _rows(String function) async {
    final rows = await _client.rpc<List<dynamic>>(function);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> update(
    String expenseId, {
    required String? description,
    required int totalCents,
    required String currency,
    required DateTime spentOn,
    required String paidBy,
    required List<ShareInput> shares,
  }) => _guard(
    () => _client.rpc<void>(
      'update_shared_expense',
      params: {
        'target': expenseId,
        ..._expenseParams(
          description: description,
          totalCents: totalCents,
          currency: currency,
          spentOn: spentOn,
          paidBy: paidBy,
          shares: shares,
        ),
      },
    ),
  );

  @override
  Future<List<SharedExpense>> list() => _guard(() async {
    final rows = await _rows('list_shared_expenses');
    return [
      for (final r in rows)
        SharedExpense(
          id: r['expense_id'] as String,
          createdBy: r['created_by'] as String?,
          paidBy: r['paid_by'] as String?,
          payerDisplayName: r['payer_display_name'] as String?,
          description: r['description'] as String?,
          totalCents: r['total_cents'] as int,
          currency: r['currency'] as String,
          spentOn: DateTime.parse(r['spent_on'] as String),
          myShareCents: r['my_share_cents'] as int,
          myShareRegistered: r['my_share_registered'] as bool,
          locked: r['locked'] as bool,
          shares: [
            for (final x in (r['shares'] as List? ?? const []))
              SharedExpenseShare(
                userId: (x as Map<String, dynamic>)['user_id'] as String?,
                displayName: x['display_name'] as String?,
                shareCents: x['share_cents'] as int,
                registered: x['registered'] as bool,
              ),
          ],
        ),
    ];
  });

  @override
  Future<List<FriendBalance>> balances() => _guard(() async {
    final rows = await _rows('friend_balances');
    return [
      for (final r in rows)
        FriendBalance(
          userId: r['user_id'] as String?,
          displayName: r['display_name'] as String?,
          currency: r['currency'] as String,
          balanceCents: r['balance_cents'] as int,
          isFriend: r['is_friend'] as bool,
        ),
    ];
  });

  @override
  Future<List<Settlement>> settlements() => _guard(() async {
    final rows = await _rows('list_settlements');
    return [
      for (final r in rows)
        Settlement(
          id: r['settlement_id'] as String,
          direction: r['direction'] == 'outgoing'
              ? SettlementDirection.outgoing
              : SettlementDirection.incoming,
          userId: r['user_id'] as String?,
          displayName: r['display_name'] as String?,
          amountCents: r['amount_cents'] as int,
          currency: r['currency'] as String,
          status: switch (r['status']) {
            'confirmed' => SettlementStatus.confirmed,
            'declined' => SettlementStatus.declined,
            _ => SettlementStatus.pending,
          },
          createdAt: DateTime.parse(r['created_at'] as String),
          myRegistered: r['my_registered'] as bool,
        ),
    ];
  });

  @override
  Future<void> registerMyShare(String expenseId) => _guard(
    () => _client.rpc<void>('register_my_share', params: {'target': expenseId}),
  );

  @override
  Future<String> recordSettlement({
    required String toUser,
    required int amountCents,
    required String currency,
  }) => _guard(
    () => _client.rpc<String>(
      'record_settlement',
      params: {
        'to_user': toUser,
        'amount_cents': amountCents,
        'currency': currency,
      },
    ),
  );

  @override
  Future<void> respondSettlement(String settlementId, {required bool accept}) =>
      _guard(
        () => _client.rpc<void>(
          'respond_settlement',
          params: {'target': settlementId, 'accept': accept},
        ),
      );

  @override
  Future<void> cancelSettlement(String settlementId) => _guard(
    () => _client.rpc<void>(
      'cancel_settlement',
      params: {'target': settlementId},
    ),
  );

  @override
  Future<void> registerMySettlement(String settlementId) => _guard(
    () => _client.rpc<void>(
      'register_my_settlement',
      params: {'target': settlementId},
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
