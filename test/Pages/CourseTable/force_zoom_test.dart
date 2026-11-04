import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/src/factory.dart';
import 'package:wheretosleepinnju/Models/CourseModel.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/ClassTitle.dart';
import 'package:wheretosleepinnju/Pages/CourseTable/Widgets/CourseWidget.dart';
import 'package:wheretosleepinnju/main.dart';
import 'package:wheretosleepinnju/generated/l10n.dart';
import 'package:wheretosleepinnju/Utils/States/MainState.dart';

class TimetableDatabase implements Database {
  int periods = 14;

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (table == 'CourseTable') {
      return [
        {
          'id': 1,
          'name': '测试课表',
          'data': jsonEncode({
            'class_time_list': [
              for (var i = 0; i < periods; i++)
                {'start': '${8 + i}:00', 'end': '${8 + i}:45'},
            ],
          }),
        },
      ];
    }
    return [
      Course(
        1,
        '最后一节课程',
        '[6]',
        1,
        periods,
        0,
        0,
        id: 1,
        courseId: 1,
        classroom: '测试教室',
      ).toMap(),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TimetableFactory implements SqfliteDatabaseFactory {
  final TimetableDatabase database;
  TimetableFactory(this.database);

  @override
  Future<String> getDatabasesPath() async => '/tmp/timetable-zoom-test';

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async => database;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'force zoom fits the viewport and restores scrolling when disabled',
    (tester) async {
      final previousFactory = databaseFactoryOrNull;
      final db = TimetableDatabase();
      databaseFactory = TimetableFactory(db);
      addTearDown(() => databaseFactoryOrNull = previousFactory);
      addTearDown(tester.view.reset);
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        pathChannel,
        (_) async => '/tmp/timetable-zoom-test',
      );
      addTearDown(() => messenger.setMockMethodCallHandler(pathChannel, null));
      SharedPreferences.setMockInitialValues({
        'tableId': 1,
        'weekIndex': 6,
        'tmpWeekIndex': 6,
        'classHeight': 90,
        'forceZoom': true,
        'showClassTime': true,
        'showDate': true,
      });
      final prefs = await SharedPreferences.getInstance();

      for (final scenario in [
        (
          name: 'portrait',
          size: const Size(393, 852),
          scale: 1.0,
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          dates: true,
          periods: 14,
        ),
        (
          name: 'small portrait',
          size: const Size(320, 568),
          scale: 1.0,
          padding: const EdgeInsets.only(top: 20, bottom: 34),
          dates: true,
          periods: 14,
        ),
        (
          name: 'large text',
          size: const Size(393, 852),
          scale: 3.2,
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          dates: true,
          periods: 14,
        ),
        (
          name: 'landscape',
          size: const Size(852, 393),
          scale: 1.0,
          padding: const EdgeInsets.only(left: 59, right: 59, bottom: 21),
          dates: true,
          periods: 14,
        ),
        (
          name: 'short landscape and large text',
          size: const Size(568, 320),
          scale: 3.2,
          padding: const EdgeInsets.only(bottom: 21),
          dates: true,
          periods: 14,
        ),
        (
          name: 'labels hidden',
          size: const Size(393, 852),
          scale: 1.0,
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          dates: false,
          periods: 13,
        ),
      ]) {
        db.periods = scenario.periods;
        await prefs.setBool('showDate', scenario.dates);
        await prefs.setBool('showMonth', scenario.dates);
        await prefs.setBool('showClassTime', scenario.dates);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.size;
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
                  data: MediaQuery.of(context).copyWith(
                    padding: scenario.padding,
                    viewPadding: scenario.padding,
                    textScaler: TextScaler.linear(scenario.scale),
                  ),
                  child: const MyApp(0, ThemeMode.light, ''),
                ),
          ),
        );
        await tester.pumpAndSettle();
        final labels = find.byType(ClassTitle);
        final course = find.byType(CourseWidget);
        expect(labels, findsOneWidget, reason: scenario.name);
        final scroll = find.ancestor(
          of: labels,
          matching: find.byType(SingleChildScrollView),
        );
        var position =
            tester.widget<SingleChildScrollView>(scroll).controller!.position;
        expect(
          position.maxScrollExtent,
          closeTo(0, .01),
          reason: scenario.name,
        );
        final bottom = scenario.size.height - scenario.padding.bottom;
        expect(
          tester.getRect(labels).bottom,
          closeTo(bottom, .01),
          reason: scenario.name,
        );
        expect(
          tester.getRect(course).bottom,
          closeTo(bottom, .01),
          reason: scenario.name,
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: course, matching: find.byType(RichText)),
        );
        expect(
          paragraph.size.height,
          greaterThanOrEqualTo(paragraph.preferredLineHeight - .01),
          reason: 'Course text is vertically clipped in ${scenario.name}',
        );
        final text = find.descendant(
          of: course,
          matching: find.byType(RichText),
        );
        final cell = find.descendant(
          of: course,
          matching: find.byType(InkWell),
        );
        expect(
          tester.getRect(text).bottom,
          lessThanOrEqualTo(tester.getRect(cell).bottom + .01),
          reason: scenario.name,
        );
        expect(tester.takeException(), isNull, reason: scenario.name);
        if (!scenario.dates) {
          final model = MainStateModel.of(tester.element(labels));
          model.setForceZoom(false);
          await tester.pumpAndSettle();
          expect(tester.getSize(labels).height, closeTo(db.periods * 90, .01));
          position =
              tester.widget<SingleChildScrollView>(scroll).controller!.position;
          expect(position.maxScrollExtent, greaterThan(0));
          await tester.drag(scroll, const Offset(0, -200));
          await tester.pumpAndSettle();
          expect(position.pixels, greaterThan(0));
          MainStateModel.of(tester.element(labels)).setForceZoom(true);
          await tester.pumpAndSettle();
          position =
              tester.widget<SingleChildScrollView>(scroll).controller!.position;
          expect(position.maxScrollExtent, closeTo(0, .01));
          expect(position.pixels, closeTo(0, .01));
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    },
  );
}
