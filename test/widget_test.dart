import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/CourseTableView.dart';

import 'package:wheretosleepinnju/main.dart';

void main() {
  testWidgets('App boots into course table view', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(0, ThemeMode.light, ''));
    await tester.pumpAndSettle();

    expect(find.byType(CourseTableView), findsOneWidget);
  });
}
