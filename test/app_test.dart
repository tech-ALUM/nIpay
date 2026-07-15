import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('app starts and shows home placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NipayApp()));
    await tester.pumpAndSettle();

    expect(find.text('nIpay'), findsOneWidget);
    expect(find.text('Welcome to nIpay'), findsOneWidget);
  });
}
