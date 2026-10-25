import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/widget_schedule_data.dart';
import '../models/live_activity_data.dart';
import '../models/school_time_template.dart';
import '../models/class_period.dart';
import '../models/widget_course.dart';
import '../exporters/unified_exporter.dart';
import '../communication/native_data_bridge.dart';
import '../../../Models/CourseModel.dart';
import '../../../Models/CourseTableModel.dart' as CourseTableDb;
import 'course_selector.dart';
import '../../../Utils/ColorUtil.dart';

/// 统一数据服务
/// 为 Widget 和 Live Activity 提供数据支持
/// 这是一个简化版本，具体实现需要根据实际数据源集成
class UnifiedDataService {
  // Startup and course edits use different service instances. Keep the entire
  // read/send operation ordered across them so an older empty read cannot
  // arrive after the snapshot containing a newly saved course.
  static Future<void> _widgetUpdates = Future<void>.value();
  final SharedPreferences _preferences;
  final NativeDataBridge _bridge;

  /// 缓存机制
  final Map<String, dynamic> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);
  DateTime? _lastCacheUpdate;

  UnifiedDataService({
    required SharedPreferences preferences,
    NativeDataBridge? bridge,
  }) : _preferences = preferences,
       _bridge = bridge ?? NativeDataBridge();

  /// 获取 Widget 显示数据
  /// 注意：这是示例实现，需要根据实际数据源（数据库、状态管理等）进行调整
  Future<WidgetScheduleData> getWidgetData() async {
    const cacheKey = 'widget_data';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as WidgetScheduleData;
    }

    final data = await _buildWidgetScheduleData();
    _cache[cacheKey] = data;
    return data;
  }

  /// 获取 Live Activity 数据
  Future<List<LiveActivityData>> getLiveActivityData() async {
    // 示例实现：返回空列表
    // 实际实现需要根据即将开始的课程生成 LiveActivityData
    return [];
  }

  /// 导出平台特定数据
  Future<Map<String, dynamic>> exportPlatformData({
    required String platform,
  }) async {
    final widgetData = await getWidgetData();
    final liveActivities = await getLiveActivityData();

    return UnifiedDataExporter.exportPlatformData(
      platform: platform,
      widgetData: widgetData,
      liveActivities: liveActivities,
    );
  }

  /// 发送数据到原生端
  Future<bool> sendToNative({
    WidgetScheduleData? widgetData,
    List<LiveActivityData>? liveActivities,
  }) async {
    widgetData ??= await getWidgetData();
    liveActivities ??= await getLiveActivityData();

    return await _bridge.sendUnifiedDataPackage(
      widgetData: widgetData,
      liveActivities: liveActivities,
    );
  }

  /// 更新 Widget 数据
  Future<bool> updateWidgetData() {
    final update = _widgetUpdates.then((_) {
      // Invalidate here, when this queued read starts, rather than before an
      // earlier refresh has finished populating its cache.
      clearCache();
      return _updateWidgetData();
    });
    _widgetUpdates = update.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return update;
  }

  Future<bool> _updateWidgetData() async {
    try {
      print('[UnifiedDataService] 开始更新 Widget 数据...');
      final data = await getWidgetData();
      print('[UnifiedDataService] Widget 数据构建成功: ${data.todayCourses.length} 门今日课程, ${data.tomorrowCourses.length} 门明日课程');

      final result = await _bridge.sendWidgetData(data);
      if (result) {
        print('[UnifiedDataService] ✅ Widget 数据发送成功');
      } else {
        print('[UnifiedDataService] ❌ Widget 数据发送失败');
      }
      return result;
    } catch (e, stackTrace) {
      print('[UnifiedDataService] ❌ 更新 Widget 数据时发生异常: $e');
      print('[UnifiedDataService] StackTrace: $stackTrace');
      return false;
    }
  }

  /// 更新 Live Activity 数据
  Future<bool> updateLiveActivityData() async {
    try {
      final activities = await getLiveActivityData();
      return await _bridge.sendLiveActivityData(activities);
    } catch (e) {
      return false;
    }
  }

  /// 构建 Widget 数据（从真实数据源）
  ///
  /// 从完整学期课程按周次筛选，避免 UI 重叠分组混入非本周课程。
  /// 保留完整源数据，供原生时间线在应用未打开时跨日/跨周推算。
  Future<WidgetScheduleData> _buildWidgetScheduleData() async {
    try {
      // 1. 获取当前课程表ID
      var currentTableId = _preferences.getInt('tableId') ?? 0;
      print('[UnifiedDataService] 📊 SharedPreferences中的课程表ID: $currentTableId');

      // 2. 获取当前周次（使用现有逻辑）
      final now = DateTime.now();
      final currentWeek = widgetWeekAt(now,
          _preferences.getInt('weekIndex') ?? 1,
          _preferences.getString('lastWeekMonday'));

      // 3. 获取课表名称和时间模板（从数据库读取）
      final courseTableProvider = CourseTableDb.CourseTableProvider();
      var courseTable = await courseTableProvider.getCourseTable(currentTableId);

      // 如果当前tableId无效（为0或不存在），尝试获取第一个课表
      if (courseTable == null) {
        print('[UnifiedDataService] ⚠️ 课表ID $currentTableId 无效，尝试获取第一个课表');
        final allTables = await courseTableProvider.getAllCourseTable();
        if (allTables.isNotEmpty) {
          currentTableId = allTables[0][CourseTableDb.columnId] as int;
          courseTable = await courseTableProvider.getCourseTable(currentTableId);
          print('[UnifiedDataService] 📊 使用第一个课表，ID: $currentTableId');
        } else {
          print('[UnifiedDataService] ❌ 数据库中没有任何课表');
          return _createEmptyData();
        }
      }

      final scheduleName = courseTable?.name ?? '我的课表';
      print('[UnifiedDataService] 📊 课表名称: $scheduleName');

      // 从数据库读取时间模板（不再依赖 school_id）
      final timeTemplate = await _getTimeTemplateFromDatabase(currentTableId, scheduleName);
      print('[UnifiedDataService] 📊 学校信息: ${timeTemplate.schoolName} (${timeTemplate.schoolId}), ${timeTemplate.periods.length} 个时间段');
      
      // 4. 获取所有课程数据
      final courseProvider = CourseProvider();
      final allCoursesMaps = await courseProvider.getAllCourses(currentTableId);
      final allCourses = allCoursesMaps.map((map) => Course.fromMap(map)).toList();

      print('[UnifiedDataService] 📊 数据库中总课程数: ${allCourses.length}');
      print('[UnifiedDataService] 📊 当前周次: $currentWeek');

      // All snapshots use the same semester source and explicit week filter.
      final currentWeekDay = now.weekday;
      final activeCourses = selectWidgetCourses(allCourses, currentWeek);
      final todayCourses = selectWidgetCourses(allCourses, currentWeek,
          day: currentWeekDay);
      final tomorrowWeekDay = currentWeekDay == 7 ? 1 : currentWeekDay + 1;
      final tomorrowWeek = currentWeekDay == 7 ? currentWeek + 1 : currentWeek;
      final tomorrowCourses = selectWidgetCourses(allCourses, tomorrowWeek,
          day: tomorrowWeekDay);
      final weekSchedule = _buildWeekSchedule(activeCourses);
      final semesterCourses = await Future.wait(allCourses
          .where((c) => (c.weekTime ?? 0) >= 1 && (c.weekTime ?? 0) <= 7)
          .map((c) => _convertToWidgetCourse(c, scheduleName)));

      // 10. 转换为 Widget 格式（使用课表名称作为标识）
      final widgetTodayCourses = await Future.wait(todayCourses.map((c) => _convertToWidgetCourse(c, scheduleName)));
      final widgetTomorrowCourses = await Future.wait(tomorrowCourses.map((c) => _convertToWidgetCourse(c, scheduleName)));

      // 11. 读取 Widget 配置选项
      final approachingMinutes = _preferences.getInt('widgetApproachingMinutes') ?? 15;
      final tomorrowPreviewHour = _preferences.getInt('widgetTomorrowPreviewHour') ?? 21;

      return WidgetScheduleData(
        version: '2.1',
        timestamp: now,
        schoolId: timeTemplate.schoolId,  // 使用时间模板中的 schoolId
        schoolName: timeTemplate.schoolName,  // 使用时间模板中的 schoolName
        timeTemplate: timeTemplate,
        currentWeek: currentWeek,
        currentWeekDay: currentWeekDay,
        semesterName: '${now.year}学年',
        todayCourses: widgetTodayCourses,
        tomorrowCourses: widgetTomorrowCourses,
        weekSchedule: await _convertWeekScheduleToWidget(weekSchedule, scheduleName),
        weekCourseCount: activeCourses.length,
        semesterCourses: semesterCourses,
        hasCoursesToday: widgetTodayCourses.isNotEmpty,
        hasCoursesTomorrow: widgetTomorrowCourses.isNotEmpty,
        dataSource: 'sqlite',
        totalCourses: allCourses.length,
        lastUpdateTime: now,
        approachingMinutes: approachingMinutes,
        tomorrowPreviewHour: tomorrowPreviewHour,
      );
    } catch (e, stackTrace) {
      print('Error building widget data: $e');
      print('StackTrace: $stackTrace');
      return _createEmptyData();
    }
  }
  
  /// 构建周课表
  /// 将已按当前周筛选的课程分配到星期一至星期日。
  Map<int, List<Course>> _buildWeekSchedule(List<Course> activeCoursesForWidget) {
    final schedule = <int, List<Course>>{};

    // 初始化 1-7
    for (int i = 1; i <= 7; i++) {
      schedule[i] = [];
    }

    // 填充课程
    for (final course in activeCoursesForWidget) {
      if (course.weekTime != null && course.weekTime! >= 1 && course.weekTime! <= 7) {
        schedule[course.weekTime!]?.add(course);
      }
    }

    // 排序
    for (final courses in schedule.values) {
      courses.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    }

    return schedule;
  }
  
  /// 转换为 Widget 课程格式
  Future<WidgetCourse> _convertToWidgetCourse(Course course, String schoolId) async {
    final courseId = 'course_${course.id ?? 0}_${course.weekTime}_${course.startTime}';

    // 解析周次列表
    List<int> weeksList = [];
    if (course.weeks != null) {
      try {
        final weeks = json.decode(course.weeks!);
        weeksList = List<int>.from(weeks);
      } catch (e) {
        // ignore
      }
    }

    // 使用与前端相同的颜色逻辑
    List colorPool = await ColorPool.getColorPool();
    String? courseColor = course.getColor(colorPool);

    // 计算实际节数：timeCount = endTime - startTime，实际节数需要 +1
    // 例如：第3-5节课，startTime=3, endTime=5, timeCount=2, 实际节数=3
    final timeCount = course.timeCount ?? 0;
    final periodCount = timeCount + 1;

    print('[UnifiedDataService] 转换课程: ${course.name} - startTime=${course.startTime}, timeCount=$timeCount -> periodCount=$periodCount');

    return WidgetCourse(
      id: courseId,
      name: course.name ?? '未知课程',
      classroom: course.classroom,
      teacher: course.teacher,
      startPeriod: course.startTime ?? 1,
      periodCount: periodCount,  // 使用修正后的节数
      weekDay: course.weekTime ?? 1,
      color: courseColor,
      schoolId: schoolId,
      weeks: weeksList,
      courseType: course.importType == 1 ? 'import' : 'manual',
      notes: course.info,
    );
  }
  
  /// 转换周课表格式
  Future<Map<int, List<WidgetCourse>>> _convertWeekScheduleToWidget(
    Map<int, List<Course>> schedule,
    String schoolId,
  ) async {
    final widgetSchedule = <int, List<WidgetCourse>>{};
    
    for (final entry in schedule.entries) {
      final widgetCourses = await Future.wait(
        entry.value.map((c) => _convertToWidgetCourse(c, schoolId))
      );
      widgetSchedule[entry.key] = widgetCourses;
    }
    
    return widgetSchedule;
  }
  
  /// 获取学校名称
  String _getSchoolName(String schoolId) {
    switch (schoolId) {
      case 'seu':
        return '东南大学';
      case 'nju':
      default:
        return '南京大学';
    }
  }
  
  /// 创建空数据（当没有课程时使用）
  WidgetScheduleData _createEmptyData() {
    // 使用南京大学作为默认
    final defaultTemplate = SchoolTimeTemplate.nanjingUniversity;

    return WidgetScheduleData(
      version: '2.0',
      timestamp: DateTime.now(),
      schoolId: defaultTemplate.schoolId,
      schoolName: defaultTemplate.schoolName,
      timeTemplate: defaultTemplate,
      currentWeek: 1,
      currentWeekDay: DateTime.now().weekday,
      semesterName: '${DateTime.now().year}学年',
      todayCourses: [],
      tomorrowCourses: [],
      weekSchedule: {},
      weekCourseCount: 0,
      hasCoursesToday: false,
      hasCoursesTomorrow: false,
      dataSource: 'empty',
      totalCourses: 0,
      lastUpdateTime: DateTime.now(),
    );
  }

  /// 从数据库获取学校时间模板
  /// [scheduleName] 课表名称，用于推断学校信息
  Future<SchoolTimeTemplate> _getTimeTemplateFromDatabase(int tableId, String scheduleName) async {
    try {
      // 从数据库读取 classTimeList
      final courseTableProvider = CourseTableDb.CourseTableProvider();
      final classTimeList = await courseTableProvider.getClassTimeList(tableId);

      print('[UnifiedDataService] 📊 从数据库读取 classTimeList: ${classTimeList.length} 个时间段');

      // 根据课表名称或时间段数量推断学校
      final schoolInfo = _inferSchoolInfo(scheduleName, classTimeList);

      // 转换为 ClassPeriod 列表
      final periods = classTimeList.map((timeMap) {
        return ClassPeriod(
          startTime: timeMap['start'] as String,
          endTime: timeMap['end'] as String,
        );
      }).toList();

      // 创建 SchoolTimeTemplate
      return SchoolTimeTemplate(
        schoolId: schoolInfo['id']!,
        schoolName: schoolInfo['name']!,
        schoolNameEn: schoolInfo['nameEn']!,
        periods: periods,
      );
    } catch (e) {
      print('[UnifiedDataService] ⚠️ 读取时间模板失败，使用默认模板: $e');
      // Fallback 到南京大学默认模板
      return SchoolTimeTemplate.nanjingUniversity;
    }
  }

  /// 根据课表名称和时间表推断学校信息
  Map<String, String> _inferSchoolInfo(String scheduleName, List<Map> classTimeList) {
    // 根据课表名称关键词推断
    if (scheduleName.contains('东南')) {
      return {'id': 'seu', 'name': '东南大学', 'nameEn': 'Southeast University'};
    } else if (scheduleName.contains('交大') || scheduleName.contains('上海交通')) {
      return {'id': 'sjtu', 'name': '上海交通大学', 'nameEn': 'Shanghai Jiao Tong University'};
    } else if (scheduleName.contains('人大') || scheduleName.contains('中国人民')) {
      return {'id': 'ruc', 'name': '中国人民大学', 'nameEn': 'Renmin University of China'};
    } else if (scheduleName.contains('南大') || scheduleName.contains('南京大学')) {
      return {'id': 'nju', 'name': '南京大学', 'nameEn': 'Nanjing University'};
    }

    // 根据时间段数量推断（东南大学通常是13个时间段）
    if (classTimeList.length == 13) {
      return {'id': 'seu', 'name': '东南大学', 'nameEn': 'Southeast University'};
    }

    // 默认返回南京大学
    return {'id': 'nju', 'name': '南京大学', 'nameEn': 'Nanjing University'};
  }

  /// 获取学校英文名称（已废弃，由 _inferSchoolInfo 替代）
  String _getSchoolNameEn(String schoolId) {
    switch (schoolId) {
      case 'seu':
        return 'Southeast University';
      case 'sjtu':
        return 'Shanghai Jiao Tong University';
      case 'ruc':
        return 'Renmin University of China';
      case 'nju':
      default:
        return 'Nanjing University';
    }
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    if (_lastCacheUpdate == null) return false;

    final elapsed = DateTime.now().difference(_lastCacheUpdate!);
    return elapsed < _cacheExpiry;
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  /// 清除特定缓存
  void clearCacheKey(String key) {
    _cache.remove(key);
  }
}
