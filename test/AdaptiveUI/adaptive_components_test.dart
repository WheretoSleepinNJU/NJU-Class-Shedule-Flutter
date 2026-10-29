import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/AdaptiveUI/src/adaptive_miuix_theme.dart';

Widget host(
  AdaptiveUIController controller,
  Widget child, {
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  builder: (context, navigator) => AdaptiveUIScope(
    controller: controller,
    debugMiuix: true,
    child: AdaptiveMiuixTheme(child: navigator!),
  ),
  home: AdaptiveScaffold(body: child),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'MIUIX chip, edit action and compact row center their actual text lines',
    (tester) async {
      final preference = AdaptiveUIController();
      await tester.pumpWidget(
        host(
          preference,
          Column(
            children: [
              AdaptiveFilterChip(
                label: const Text('全校'),
                selected: true,
                onSelected: (_) {},
              ),
              AdaptiveButton.text(onPressed: () {}, child: const Text('编辑')),
              SizedBox(
                height: 40,
                width: 320,
                child: AdaptiveButton.text(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    textStyle: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, size: 16),
                      Expanded(child: Text('自由时间课程')),
                      Text('查看'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['全校', '编辑', '自由时间课程', '查看']) {
        final text = find.text(label);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final button = find
            .ancestor(of: text, matching: find.byType(miuix.MiuixButton))
            .first;
        final rect = tester.getRect(button);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: label.length),
        );
        expect(boxes, isNotEmpty);
        final line = boxes.first.toRect();
        final center = paragraph.localToGlobal(line.center);
        expect(
          center.dy,
          closeTo(rect.center.dy, 1),
          reason: '$label glyph center',
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      preference.dispose();
    },
  );

  testWidgets(
    'form value, selection, focus and validation survive renderer changes',
    (tester) async {
      final preference = AdaptiveUIController();
      final text = TextEditingController(text: 'initial');
      final focus = FocusNode();
      final form = GlobalKey<FormState>();
      String? saved;
      await tester.pumpWidget(
        host(
          preference,
          Form(
            key: form,
            child: AdaptiveTextFormField(
              key: const ValueKey('input'),
              controller: text,
              focusNode: focus,
              decoration: const InputDecoration(labelText: '课程'),
              validator: (value) => value!.isEmpty ? '必填' : null,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(miuix.MiuixTextField), findsOneWidget);
      final state = tester.state(find.byKey(const ValueKey('input')));
      await tester.enterText(find.byKey(const ValueKey('input')), 'draft');
      text.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      focus.requestFocus();
      await tester.pumpAndSettle();
      await preference.setUseOriginalComponents(true);
      await tester.pumpAndSettle();
      expect(find.byType(miuix.MiuixTextField), findsNothing);
      expect(
        identical(tester.state(find.byKey(const ValueKey('input'))), state),
        true,
      );
      expect(text.text, 'draft');
      expect(
        text.selection,
        const TextSelection(baseOffset: 1, extentOffset: 3),
      );
      expect(focus.hasFocus, true);
      text.text = '';
      expect(form.currentState!.validate(), false);
      await tester.pumpAndSettle();
      await preference.setUseOriginalComponents(false);
      await tester.pumpAndSettle();
      expect(find.text('必填'), findsOneWidget);
      text.text = 'programmatic';
      form.currentState!.save();
      expect(saved, 'programmatic');
      form.currentState!.reset();
      expect(text.text, 'initial');
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      text.dispose();
      preference.dispose();
    },
  );

  testWidgets('uncontrolled editor and initial form values persist and reset', (
    tester,
  ) async {
    final preference = AdaptiveUIController();
    final form = GlobalKey<FormState>();
    String? saved;
    await tester.pumpWidget(
      host(
        preference,
        Form(
          key: form,
          child: Column(
            children: [
              const AdaptiveTextField(key: ValueKey('uncontrolled')),
              AdaptiveTextFormField(
                key: const ValueKey('initial'),
                initialValue: 'seed',
                onSaved: (v) => saved = v,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('seed'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('uncontrolled')),
      'unsaved',
    );
    await preference.setUseOriginalComponents(true);
    await tester.pumpAndSettle();
    expect(find.text('unsaved'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('initial')), 'changed');
    form.currentState!.save();
    expect(saved, 'changed');
    form.currentState!.reset();
    await tester.pumpAndSettle();
    expect(find.text('seed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    preference.dispose();
  });

  testWidgets(
    'MIUIX actions respect loading, disabled state and full width styles',
    (tester) async {
      final preference = AdaptiveUIController();
      var calls = 0;
      await tester.pumpWidget(
        host(
          preference,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdaptiveButton.filled(
                onPressed: () => calls++,
                child: const Text('提交'),
              ),
              AdaptiveButton.filled(
                onPressed: () => calls++,
                loading: true,
                child: const Text('等待'),
              ),
              const AdaptiveButton.text(onPressed: null, child: Text('禁用')),
              AdaptiveButton.icon(
                variant: AdaptiveButtonVariant.outlined,
                onPressed: () => calls++,
                icon: const Icon(Icons.delete),
                label: const Text('删除'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
          brightness: Brightness.dark,
        ),
      );
      await tester.pump();
      expect(find.byType(miuix.MiuixButton), findsNWidgets(4));
      await tester.tap(find.text('提交'));
      await tester.tap(find.text('等待'));
      await tester.tap(find.text('禁用'));
      await tester.tap(find.text('删除'));
      expect(calls, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      preference.dispose();
    },
  );

  testWidgets(
    'MIUIX dropdown selection uses the page popup host and returns value',
    (tester) async {
      final preference = AdaptiveUIController();
      var value = 1;
      await tester.pumpWidget(
        host(
          preference,
          StatefulBuilder(
            builder: (context, update) => Align(
              alignment: Alignment.topLeft,
              child: AdaptiveDropdown<int>(
                value: value,
                items: const [
                  AdaptiveOption(value: 1, child: Text('一')),
                  AdaptiveOption(value: 2, child: Text('二')),
                ],
                onChanged: (next) => update(() => value = next!),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('一'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('二'));
      await tester.pumpAndSettle();
      expect(value, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      preference.dispose();
    },
  );

  testWidgets(
    'MIUIX dialog preserves arbitrary content, route result and non-dismissible barrier',
    (tester) async {
      final preference = AdaptiveUIController();
      final navigator = GlobalKey<NavigatorState>();
      final text = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => AdaptiveUIScope(
            controller: preference,
            debugMiuix: true,
            child: AdaptiveMiuixTheme(child: child!),
          ),
          home: const Scaffold(),
        ),
      );
      final result = showDialog<bool>(
        context: navigator.currentContext!,
        barrierDismissible: false,
        builder: (context) => AdaptiveDialog(
          title: const Text('表单'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(key: const ValueKey('dialog-input'), controller: text),
              CheckboxListTile(
                title: const Text('兼容 Material 内容'),
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
          actions: [
            AdaptiveButton.text(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(miuix.MiuixOverlayDialog), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('dialog-input')),
        'draft',
      );
      final field = tester.state(find.byKey(const ValueKey('dialog-input')));
      await preference.setUseOriginalComponents(true);
      await tester.pumpAndSettle();
      expect(
        identical(
          tester.state(find.byKey(const ValueKey('dialog-input'))),
          field,
        ),
        true,
      );
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(find.text('表单'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(await result, true);
      final next = showDialog<void>(
        context: navigator.currentContext!,
        builder: (_) => const AdaptiveDialog(title: Text('原始弹窗')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(miuix.MiuixOverlayDialog), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await next;
      await tester.pumpWidget(const SizedBox());
      text.dispose();
      preference.dispose();
    },
  );
  testWidgets('long MIUIX dialog actions stay inside the route safe viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.padding = const FakeViewPadding(top: 54, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 24);
    addTearDown(tester.view.reset);
    final preference = AdaptiveUIController();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) => AdaptiveUIScope(
          controller: preference,
          debugMiuix: true,
          child: AdaptiveMiuixTheme(child: child!),
        ),
        home: const Scaffold(),
      ),
    );
    final result = showDialog<void>(
      context: navigator.currentContext!,
      builder: (context) => AdaptiveDialog(
        title: const Text('长内容'),
        scrollable: true,
        content: Text(List.filled(80, '需要滚动阅读的内容').join('\n')),
        actions: [
          AdaptiveButton.text(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.text('完成')).dy, lessThan(852 - 24));
    expect(find.text('完成').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await result;
    await tester.pumpWidget(const SizedBox());
    preference.dispose();
  });
  testWidgets('adaptive controls isolate legacy filled Material colors', (
    tester,
  ) async {
    final preference = AdaptiveUIController();
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final theme = base.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(filled: true),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => AdaptiveUIScope(
          controller: preference,
          debugMiuix: true,
          child: AdaptiveMiuixTheme(child: child!),
        ),
        home: Scaffold(
          body: Column(
            children: [
              AdaptiveButton.text(onPressed: () {}, child: const Text('操作')),
              const AdaptiveTextField(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final colors = tester
        .widget<miuix.MiuixButton>(find.byType(miuix.MiuixButton))
        .colors!;
    expect(colors.color, Colors.transparent);
    expect(colors.contentColor, theme.colorScheme.primary);
    final editor = find.descendant(
      of: find.byType(miuix.MiuixTextField),
      matching: find.byType(TextField),
    );
    expect(InputDecorationTheme.of(tester.element(editor)).filled, false);
    await preference.setUseOriginalComponents(true);
    await tester.pumpAndSettle();
    expect(find.byType(miuix.MiuixButton), findsNothing);
    expect(
      TextButtonTheme.of(
        tester.element(find.byType(TextButton)),
      ).style!.backgroundColor!.resolve({}),
      theme.colorScheme.primary,
    );
    await tester.pumpWidget(const SizedBox());
    preference.dispose();
  });
  testWidgets(
    'short MIUIX dialogs fill the safe phone width and honor custom caps',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = AdaptiveUIController();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (_, child) => AdaptiveUIScope(
            controller: controller,
            debugMiuix: true,
            child: AdaptiveMiuixTheme(child: child!),
          ),
          home: const Scaffold(),
        ),
      );
      for (final width in [320.0, 393.0, 800.0]) {
        tester.view.physicalSize = Size(width, 852);
        await tester.pumpAndSettle();
        final result = showDialog<void>(
          context: navigator.currentContext!,
          builder: (_) =>
              const AdaptiveDialog(title: Text('添加课程'), content: Text('手动添加')),
        );
        await tester.pumpAndSettle();
        final panel = find
            .ancestor(
              of: find.text('添加课程'),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is SizedBox &&
                    widget.width != null &&
                    widget.width!.isFinite,
              ),
            )
            .first;
        final actual = tester.getSize(panel).width;
        expect(actual, closeTo(width < 600 ? width - 24 : 560, .01));
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        await result;
      }
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      final result = showDialog<void>(
        context: navigator.currentContext!,
        builder: (_) => const AdaptiveDialog(
          title: Text('指定宽度'),
          constraints: BoxConstraints(maxWidth: 300),
          content: Text('短内容'),
        ),
      );
      await tester.pumpAndSettle();
      final panel = find
          .ancestor(
            of: find.text('指定宽度'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is SizedBox &&
                  widget.width != null &&
                  widget.width!.isFinite,
            ),
          )
          .first;
      expect(tester.getSize(panel).width, 300);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await result;
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
