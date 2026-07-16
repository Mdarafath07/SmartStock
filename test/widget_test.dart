import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    final connectivity = ConnectivityService();
    await tester.pumpWidget(SmartStockApp(connectivity: connectivity));
    expect(find.byType(SmartStockApp), findsOneWidget);
  });
}
