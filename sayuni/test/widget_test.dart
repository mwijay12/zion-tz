import 'package:flutter_test/flutter_test.dart';
import 'package:sayuni/main.dart';

void main() {
  testWidgets('App smoke test loads SayuniApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SayuniApp());
    expect(find.byType(SayuniApp), findsOneWidget);
  });
}
