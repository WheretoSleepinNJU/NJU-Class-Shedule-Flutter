import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCoursePresenter.dart';
import 'package:wheretosleepinnju/Pages/EditCourse/EditCourseView.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';

class HoldingProvider extends CourseProvider {
  int calls = 0;
  final result = Completer<bool>();
  @override
  Future<bool> saveMeetingGroup(List<Course> originals, List<Course> courses) {
    calls++;
    return result.future;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nju/compose-titlebar');
  Future<Map<Object?, Object?>> waitFor(
    WidgetTester tester,
    bool Function(Map<Object?, Object?>) ready,
  ) async {
    Map<Object?, Object?> last = {};
    for (var i = 0; i < 80; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      last = (await channel.invokeMapMethod<Object?, Object?>('diagnostics'))!;
      if (ready(last)) return last;
    }
    fail('Native editor state not reached: $last');
  }

  Future<void> save(WidgetTester tester, Object? owner) async {
    await tester.runAsync(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall('action', {'owner': owner, 'index': 0}),
            ),
            (_) {},
          ),
    );
  }

  for (final creating in [true, false]) {
    testWidgets(
      'real ${creating ? 'add' : 'edit'} page keeps native chrome through save and fallback',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final preference = AdaptiveUIController();
        final provider = HoldingProvider();
        await tester.pumpWidget(
          AdaptiveUIApp(
            controller: preference,
            supportedLocales: const [Locale('zh', 'CN')],
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: EditCourseView(
              tableId: 3,
              classTimeList: const [],
              course: creating
                  ? null
                  : Course(3, '原课程', '[1,2]', 1, 1, 0, 1, id: 17),
              presenter: EditCoursePresenter(
                provider: provider,
                refreshWidgets: () async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final first = await waitFor(
          tester,
          (d) =>
              d['toolbarVisible'] == true && (d['actions'] as List).length == 1,
        );
        expect(
          find.byType(AppBar),
          findsNothing,
          reason: 'The real page must use the full Compose TitleBar.',
        );
        expect(first['glassTopBars'], 0);
        expect(
          find.byKey(const ValueKey('delete-course')),
          creating ? findsNothing : findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('edit-course-name')),
          '原生保存测试',
        );
        await tester.pumpAndSettle();
        final field = tester.state(
          find.byKey(const ValueKey('edit-course-name')),
        );
        final owner = first['owner'];
        await save(tester, owner);
        await tester.pump();
        await waitFor(
          tester,
          (d) => (d['actions'] as List).first['loading'] == true,
        );
        expect(find.byType(AppBar), findsNothing);
        await save(tester, owner);
        expect(
          provider.calls,
          1,
          reason: 'Repeated native activation during save is blocked.',
        );
        provider.result.complete(false);
        await tester.pumpAndSettle();
        await waitFor(
          tester,
          (d) =>
              (d['actions'] as List).first['loading'] == false &&
              (d['actions'] as List).first['enabled'] == true,
        );
        await tester.runAsync(() => preference.setUseOriginalComponents(true));
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byKey(const ValueKey('save-course')), findsOneWidget);
        expect(
          identical(
            tester.state(find.byKey(const ValueKey('edit-course-name'))),
            field,
          ),
          true,
        );
        await tester.runAsync(() => preference.setUseOriginalComponents(false));
        await tester.pumpAndSettle();
        await waitFor(tester, (d) => d['toolbarVisible'] == true);
        expect(find.byType(AppBar), findsNothing);
        expect(find.text('原生保存测试'), findsOneWidget);
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(16);
        await tester.pumpAndSettle();
        final scrolled = await waitFor(
          tester,
          (d) => (d['progress'] as num? ?? 0) > .49,
        );
        expect(scrolled['progress'] as num, closeTo(.5, .01));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        preference.dispose();
      },
    );
  }
}
