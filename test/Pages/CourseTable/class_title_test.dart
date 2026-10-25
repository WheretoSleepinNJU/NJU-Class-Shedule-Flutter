import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/ClassTitle.dart';

void main() {
  testWidgets('period labels survive system font changes before row refresh', (
    tester,
  ) async {
    Future<void> show(double scale, double rowHeight, double rowWidth) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: ClassTitle(1, rowHeight, rowWidth, true, null),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('08:00\n08:50'), findsOneWidget);
    }

    await show(1, 52, 40);
    await show(1.4, 52, 40);
    await show(1.4, 72.8, 56);
    await show(1, 72.8, 56);
    await show(1, 52, 40);
  });
}
