import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartStockApp());
    expect(find.byType(SmartStockApp), findsOneWidget);
  });
}
