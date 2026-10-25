import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/core/widget_data/communication/native_data_bridge.dart';
import 'package:wheretosleepinnju/core/widget_data/models/widget_course.dart';
import 'package:wheretosleepinnju/core/widget_data/models/widget_schedule_data.dart';
import 'package:wheretosleepinnju/core/widget_data/models/school_time_template.dart';
import 'package:wheretosleepinnju/core/widget_data/services/unified_data_service.dart';

class RecordingBridge implements NativeDataBridge {
  WidgetScheduleData? lastSnapshot;
  final names = <String>[];
  bool failNext = false;
  @override
  Future<bool> sendWidgetData(WidgetScheduleData data) async {
    if (failNext) {
      failNext = false;
      throw StateError('native write rejected');
    }
    lastSnapshot = data;
    names.add(data.hasCoursesToday ? 'Sunday course' : 'empty');
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DelayedReadService extends UnifiedDataService {
  final List<Future<WidgetScheduleData>> reads;
  int index = 0;
  DelayedReadService(
    SharedPreferences preferences,
    RecordingBridge bridge,
    this.reads,
  ) : super(preferences: preferences, bridge: bridge);
  @override
  Future<WidgetScheduleData> getWidgetData() => reads[index++];
}

WidgetScheduleData snapshot({required bool added}) {
  final courses =
      added
          ? [
            WidgetCourse(
              id: 'sunday-added',
              name: 'Sunday course',
              startPeriod: 1,
              periodCount: 1,
              weekDay: 7,
              schoolId: 'qa',
              weeks: [6],
            ),
          ]
          : <WidgetCourse>[];
  return WidgetScheduleData(
    timestamp: DateTime(2026, 10, 25, 14),
    schoolId: 'qa',
    schoolName: 'QA',
    timeTemplate: SchoolTimeTemplate.nanjingUniversity,
    currentWeek: 6,
    currentWeekDay: 7,
    semesterName: 'QA',
    todayCourses: courses,
    tomorrowCourses: [],
    weekSchedule: {7: courses},
    semesterCourses: courses,
    weekCourseCount: courses.length,
    hasCoursesToday: added,
    hasCoursesTomorrow: false,
    totalCourses: courses.length,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final separateServices in [false, true]) {
    test(
      'late empty read cannot replace newly added Sunday course ($separateServices)',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final bridge = RecordingBridge();
        final oldRead = Completer<WidgetScheduleData>();
        final newRead = Completer<WidgetScheduleData>();
        final service = DelayedReadService(
          prefs,
          bridge,
          separateServices
              ? [oldRead.future]
              : [oldRead.future, newRead.future],
        );
        final newerService =
            separateServices
                ? DelayedReadService(prefs, bridge, [newRead.future])
                : service;
        final oldRefresh = service.updateWidgetData();
        await Future<void>.delayed(Duration.zero);
        final savedCourseRefresh = newerService.updateWidgetData();
        newRead.complete(snapshot(added: true));
        await Future<void>.delayed(Duration.zero);
        oldRead.complete(snapshot(added: false));
        expect(await oldRefresh, isTrue);
        expect(await savedCourseRefresh, isTrue);
        expect(bridge.lastSnapshot!.todayCourses.map((c) => c.id), [
          'sunday-added',
        ]);
      },
    );
  }
  test('a failed native update does not prevent the next refresh', () async {
    final prefs = await SharedPreferences.getInstance();
    final bridge = RecordingBridge()..failNext = true;
    final service = DelayedReadService(prefs, bridge, [
      Future.value(snapshot(added: false)),
      Future.value(snapshot(added: true)),
    ]);
    expect(await service.updateWidgetData(), isFalse);
    expect(await service.updateWidgetData(), isTrue);
    expect(bridge.lastSnapshot!.hasCoursesToday, isTrue);
  });
}
