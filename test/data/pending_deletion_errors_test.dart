import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/services/chat_service.dart';
import 'package:nipay/data/services/friends_service.dart';
import 'package:nipay/data/services/shared_expense_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Account in cancellazione (M-SOC5): il server risponde con l'hint
/// pending_deletion su messaggi, amicizie, chat e spese divise.
void main() {
  const error = PostgrestException(
    message: 'account in cancellazione',
    hint: 'pending_deletion',
  );

  test('every social service recognises an account being deleted', () {
    expect(friendsErrorOf(error).code, FriendsErrorCode.pendingDeletion);
    expect(chatErrorOf(error).code, ChatErrorCode.pendingDeletion);
    expect(
      sharedExpenseErrorOf(error).code,
      SharedExpenseErrorCode.pendingDeletion,
    );
  });
}
