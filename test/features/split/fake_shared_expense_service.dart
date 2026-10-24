import 'package:nipay/data/services/shared_expense_service.dart';

/// Doppio di [SharedExpenseService]: spese, saldi e rimborsi in memoria,
/// chiamate registrate.
class FakeSharedExpenseService implements SharedExpenseService {
  final created = <Map<String, Object?>>[];
  final updated = <Map<String, Object?>>[];
  final deleted = <String>[];
  final calls = <String>[];
  final expenses = <SharedExpense>[];
  final balanceRows = <FriendBalance>[];
  final settlementRows = <Settlement>[];
  SharedExpenseErrorCode? failNext;

  void _maybeFail() {
    final code = failNext;
    if (code == null) return;
    failNext = null;
    throw SharedExpenseException(code);
  }

  Map<String, Object?> _args(
    String? description,
    int totalCents,
    String currency,
    String paidBy,
    List<ShareInput> shares,
  ) => {
    'description': description,
    'total': totalCents,
    'currency': currency,
    'paidBy': paidBy,
    'shares': {for (final s in shares) s.userId: s.shareCents},
  };

  @override
  Future<String> create({
    required String? description,
    required int totalCents,
    required String currency,
    required DateTime spentOn,
    required String paidBy,
    required List<ShareInput> shares,
  }) async {
    _maybeFail();
    created.add(_args(description, totalCents, currency, paidBy, shares));
    return 'se-${created.length}';
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
  }) async {
    _maybeFail();
    updated.add({
      'id': expenseId,
      ..._args(description, totalCents, currency, paidBy, shares),
    });
  }

  @override
  Future<void> delete(String expenseId) async {
    _maybeFail();
    deleted.add(expenseId);
  }

  @override
  Future<List<SharedExpense>> list() async => [...expenses];

  @override
  Future<List<FriendBalance>> balances() async => [...balanceRows];

  @override
  Future<List<Settlement>> settlements() async => [...settlementRows];

  @override
  Future<void> registerMyShare(String expenseId) async {
    _maybeFail();
    calls.add('registerMyShare:$expenseId');
  }

  @override
  Future<String> recordSettlement({
    required String toUser,
    required int amountCents,
    required String currency,
  }) async {
    _maybeFail();
    calls.add('recordSettlement:$toUser:$amountCents:$currency');
    return 'st-new';
  }

  @override
  Future<void> respondSettlement(
    String settlementId, {
    required bool accept,
  }) async {
    _maybeFail();
    calls.add('respondSettlement:$settlementId:$accept');
  }

  @override
  Future<void> cancelSettlement(String settlementId) async {
    _maybeFail();
    calls.add('cancelSettlement:$settlementId');
  }

  @override
  Future<void> registerMySettlement(String settlementId) async {
    _maybeFail();
    calls.add('registerMySettlement:$settlementId');
  }
}
