import 'package:flutter_test/flutter_test.dart';
import 'package:closekart_support/main.dart';

void main() {
  testWidgets('Closekart app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ClosekartSupportApp());
    expect(find.text('CLOSEKART'), findsOneWidget);
  });
}
