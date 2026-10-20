import 'package:flutter_test/flutter_test.dart';
import 'package:zion_mobile/main.dart';

void main() {
  testWidgets('App smoke test loads ZionChurchApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ZionChurchApp());
    expect(find.byType(ZionChurchApp), findsOneWidget);
  });
}
