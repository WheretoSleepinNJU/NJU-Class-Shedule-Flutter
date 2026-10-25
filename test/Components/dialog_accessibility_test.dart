import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Components/Dialog.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseDetailDialog.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

Future<void> openDialog(
  WidgetTester tester,
  WidgetBuilder dialog, {
  double scale = 3.2,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
      home: Builder(
        builder:
            (context) => Scaffold(
              body: TextButton(
                onPressed:
                    () => showDialog<void>(context: context, builder: dialog),
                child: const Text('打开'),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dialog clamps transient negative iOS keyboard insets', (
    tester,
  ) async {
    await openDialog(
      tester,
      (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(viewInsets: const EdgeInsets.only(bottom: -50)),
        child: const MDialog('修改课表名称', TextField()),
      ),
      scale: 1,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('修改课表名称'), findsOneWidget);
    final padding = tester.widget<AnimatedPadding>(
      find.byType(AnimatedPadding),
    );
    expect(padding.padding.isNonNegative, isTrue);
  });

  const title = 'QA-超过十五字的完整课程名称与课堂讨论实践';
  for (final size in [
    const Size(393, 852),
    const Size(320, 568),
    const Size(852, 393),
  ]) {
    testWidgets('large detail is readable and dismissible at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final course = Course(
        1,
        title,
        '[1,2,3]',
        1,
        1,
        0,
        0,
        classroom: '仙林校区教学楼三层 QA-101',
        teacher: '测试教师',
        info: List.filled(20, '长备注需要滚动阅读，关闭提示保持可见。').join(),
      );
      await openDialog(
        tester,
        (context) =>
            CourseDetailDialog(course, true, () => Navigator.of(context).pop()),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(title),
        findsOneWidget,
        reason: 'Keep the complete title.',
      );
      final body = tester.widgetList<SelectableLinkify>(
        find.byType(SelectableLinkify),
      );
      expect(body, isNotEmpty);
      expect(
        body.every((text) => text.textScaleFactor == 2),
        isTrue,
        reason: 'Linkified detail rows must scale with the title and buttons.',
      );
      expect(
        MediaQuery.textScalerOf(tester.element(find.text(title))).scale(16),
        32,
      );
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      expect(find.text('确认'), findsNothing);
      expect(find.text('点击空白处关闭').hitTestable(), findsOneWidget);
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('点击空白处关闭').hitTestable(), findsOneWidget);
      await tester.tapAt(const Offset(4, 100));
      await tester.pumpAndSettle();
      expect(find.byType(CourseDetailsDialog), findsNothing);
    });
  }

  testWidgets('default detail keeps normal typography and full title', (
    tester,
  ) async {
    await openDialog(
      tester,
      (context) => CourseDetailDialog(
        Course(1, title, '[1]', 1, 1, 0, 0, classroom: 'QA-101'),
        true,
        () => Navigator.of(context).pop(),
      ),
      scale: 1,
    );
    expect(find.text(title), findsOneWidget);
    expect(
      tester
          .widget<SelectableLinkify>(find.byType(SelectableLinkify).first)
          .textScaleFactor,
      1,
    );
    expect(
      find.byIcon(Icons.account_circle),
      findsNothing,
      reason: 'No empty teacher row.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('large confirmation retains both actions on a small screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    var accepted = false;
    await openDialog(
      tester,
      (context) => MDialog(
        '删除课程',
        const Text('确定删除这门名称较长的课程吗？'),
        widgetCancelAction: () => Navigator.of(context).pop(),
        widgetOKAction: () {
          accepted = true;
          Navigator.of(context).pop();
        },
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('取消').hitTestable(), findsOneWidget);
    expect(find.text('确认').hitTestable(), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(accepted, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('large input dialog keeps actions above the keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await openDialog(
      tester,
      (context) => MDialog(
        '新增课表',
        const TextField(),
        widgetCancelAction: () => Navigator.of(context).pop(),
        widgetOKAction: () => Navigator.of(context).pop(),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('确认').hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(find.text('确认')).dy, lessThan(308));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
