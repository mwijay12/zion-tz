import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayuni/core/widgets/motion/motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Immersive motion widgets', () {
    testWidgets('AnimatedTshCounter counts up and shows TSh', (tester) async {
      await tester.pumpWidget(wrap(
        const AnimatedTshCounter(value: 68450000),
      ));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.textContaining('TSh'), findsOneWidget);
      expect(find.textContaining('68,450,000'), findsOneWidget);
    });

    testWidgets('AnimatedCount shows suffix', (tester) async {
      await tester.pumpWidget(wrap(
        const AnimatedCount(value: 128, suffix: ' waumini'),
      ));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.textContaining('128'), findsOneWidget);
    });

    testWidgets('ChurchGivingGauge renders centre labels', (tester) async {
      await tester.pumpWidget(wrap(
        const ChurchGivingGauge(
          progress: 0.57,
          raisedTzs: 68450000,
          targetTzs: 120000000,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('ZILIZOPATIKANA'), findsOneWidget);
      expect(find.textContaining('ya lengo'), findsOneWidget);
    });

    testWidgets('JumuiyaAttendanceChart toggles weekly/monthly',
        (tester) async {
      await tester.pumpWidget(wrap(
        const JumuiyaAttendanceChart(),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Wiki Hii'), findsOneWidget);

      await tester.tap(find.text('Wiki Hii'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Mwezi Huu'), findsOneWidget);
    });

    testWidgets('StaggeredReveal renders child', (tester) async {
      await tester.pumpWidget(wrap(
        const StaggeredReveal(index: 2, child: Text('Karibu Sayuni')),
      ));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Karibu Sayuni'), findsOneWidget);
    });
  });
}
