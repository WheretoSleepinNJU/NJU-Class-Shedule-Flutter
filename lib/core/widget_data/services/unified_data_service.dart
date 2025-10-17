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
import '../../../Models/ScheduleModel.dart';

/// 统一数据服务
/// 为 Widget 和 Live Activity 提供数据支持
/// 这是一个简化版本，具体实现需要根据实际数据源集成
class UnifiedDataService {
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
  Future<bool> updateWidgetData() async {
    try {
      print('[UnifiedDataService] 开始更新 Widget 数据...');
      final data = await getWidgetData();
      print('[UnifiedDataService] Widget 数据构建成功: ${data.todayCourseCount} 门今日课程, ${data.tomorrowCourseCount} 门明日课程');
      print('[UnifiedDataService] 当前课程: ${data.currentCourse?.name ?? "无"}');
      print('[UnifiedDataService] 下节课程: ${data.nextCourse?.name ?? "无"}');

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
  /// 数据处理逻辑复用课表前端的渲染逻辑（CourseTablePresenter + ScheduleModel）：
  /// 1. 使用 ScheduleModel.init() 分类课程为 activeCourses, hideCourses, multiCourses, freeCourses
  /// 2. Widget 使用本周课程：activeCourses + multiCourses[0]（不包含 hideCourses）
  /// 3. 从本周课程中筛选今日/明日课程
  Future<WidgetScheduleData> _buildWidgetScheduleData() async {
    try {
      // 1. 获取当前课程表ID
      var currentTableId = _preferences.getInt('tableId') ?? 0;
      print('[UnifiedDataService] 📊 SharedPreferences中的课程表ID: $currentTableId');

      // 2. 获取当前周次（使用现有逻辑）
      final currentWeek = _preferences.getInt('weekIndex') ?? 1;

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

      // 5. 使用现有逻辑分类课程
      final scheduleModel = ScheduleModel(allCourses, currentWeek);
      scheduleModel.init();

      print('[UnifiedDataService] 📊 activeCourses 数量: ${scheduleModel.activeCourses.length}');
      for (var course in scheduleModel.activeCourses) {
        print('[UnifiedDataService]    - ${course.name} (周${course.weekTime}, 节${course.startTime})');
      }

      print('[UnifiedDataService] 📊 multiCourses 数量: ${scheduleModel.multiCourses.length}');
      for (var courseList in scheduleModel.multiCourses) {
        print('[UnifiedDataService]    - 冲突组: ${courseList.map((c) => '${c.name}(周${c.weekTime})').join(', ')}');
      }

      print('[UnifiedDataService] 📊 freeCourses 数量: ${scheduleModel.freeCourses.length}');
      for (var course in scheduleModel.freeCourses) {
        print('[UnifiedDataService]    - ${course.name} (周${course.weekTime}, 节${course.startTime})');
      }

      print('[UnifiedDataService] 📊 hideCourses 数量: ${scheduleModel.hideCourses.length}');
      for (var course in scheduleModel.hideCourses) {
        print('[UnifiedDataService]    - ${course.name} (周${course.weekTime}, 节${course.startTime}, weeks=${course.weeks})');
      }

      // 6. 复用课表前端的渲染逻辑：activeCourses + multiCourses[0]
      // 注意：课表前端虽然也渲染 hideCourses（灰色显示），但那是非本周课程
      // Widget 只需要显示本周的课程，所以只使用 activeCourses + multiCourses
      final activeCoursesForWidget = [
        ...scheduleModel.activeCourses,
        ...scheduleModel.multiCourses.map((list) => list[0]),
      ];

      print('[UnifiedDataService] 📊 Widget 使用的本周课程总数: ${activeCoursesForWidget.length}');

      // 7. 计算今日课程（从本周课程中筛选）
      final currentWeekDay = DateTime.now().weekday;
      print('[UnifiedDataService] 📊 当前星期: $currentWeekDay');
      final todayCourses = _filterCoursesForDay(activeCoursesForWidget, currentWeekDay);
      print('[UnifiedDataService] 📊 今日课程数: ${todayCourses.length}');

      // 8. 计算明日课程
      final tomorrowWeekDay = currentWeekDay == 7 ? 1 : currentWeekDay + 1;
      final tomorrowWeek = currentWeekDay == 7 ? currentWeek + 1 : currentWeek;
      final tomorrowCourses = _filterCoursesForTomorrow(allCourses, tomorrowWeek, tomorrowWeekDay);

      // 9. 计算当前课程和下一节课
      final now = DateTime.now();
      final currentCourse = _getCurrentCourse(todayCourses, now, timeTemplate);
      final nextCourse = _getNextCourse(todayCourses, now, timeTemplate);

      // 10. 构建周课表（使用本周课程）
      final weekSchedule = _buildWeekSchedule(activeCoursesForWidget);
      
      // 10. 转换为 Widget 格式（使用课表名称作为标识）
      final widgetTodayCourses = todayCourses.map((c) => _convertToWidgetCourse(c, scheduleName)).toList();
      final widgetTomorrowCourses = tomorrowCourses.map((c) => _convertToWidgetCourse(c, scheduleName)).toList();
      final widgetCurrentCourse = currentCourse != null ? _convertToWidgetCourse(currentCourse, scheduleName) : null;
      final widgetNextCourse = nextCourse != null ? _convertToWidgetCourse(nextCourse, scheduleName) : null;

      // 11. 读取 Widget 配置选项
      final approachingMinutes = _preferences.getInt('widgetApproachingMinutes') ?? 15;
      final tomorrowPreviewHour = _preferences.getInt('widgetTomorrowPreviewHour') ?? 21;

      return WidgetScheduleData(
        version: '1.0',
        timestamp: DateTime.now(),
        schoolId: timeTemplate.schoolId,  // 使用时间模板中的 schoolId
        schoolName: timeTemplate.schoolName,  // 使用时间模板中的 schoolName
        timeTemplate: timeTemplate,
        currentWeek: currentWeek,
        currentWeekDay: currentWeekDay,
        semesterName: '${DateTime.now().year}学年',
        todayCourses: widgetTodayCourses,
        tomorrowCourses: widgetTomorrowCourses,
        nextCourse: widgetNextCourse,
        currentCourse: widgetCurrentCourse,
        weekSchedule: _convertWeekScheduleToWidget(weekSchedule, scheduleName),
        todayCourseCount: widgetTodayCourses.length,
        tomorrowCourseCount: widgetTomorrowCourses.length,
        weekCourseCount: scheduleModel.activeCourses.length,
        hasCoursesToday: widgetTodayCourses.isNotEmpty,
        hasCoursesTomorrow: widgetTomorrowCourses.isNotEmpty,
        dataSource: 'sqlite',
        totalCourses: allCourses.length,
        lastUpdateTime: DateTime.now(),
        approachingMinutes: approachingMinutes,
        tomorrowPreviewHour: tomorrowPreviewHour,
      );
    } catch (e, stackTrace) {
      print('Error building widget data: $e');
      print('StackTrace: $stackTrace');
      return _createEmptyData();
    }
  }
  
  /// 筛选今日课程
  /// 复用课表前端逻辑：从本周课程（activeCourses + multiCourses[0]）中筛选今日课程
  List<Course> _filterCoursesForDay(List<Course> activeCoursesForWidget, int weekDay) {
    final filtered = activeCoursesForWidget.where((course) => course.weekTime == weekDay).toList();
    // 按开始时间排序
    filtered.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    return filtered;
  }
  
  /// 筛选明日课程（需要重新计算周次）
  List<Course> _filterCoursesForTomorrow(List<Course> allCourses, int tomorrowWeek, int tomorrowWeekDay) {
    final filtered = allCourses.where((course) {
      if (course.weekTime != tomorrowWeekDay) return false;
      
      // 检查明日周次是否包含在课程周次中
      if (course.weeks == null) return false;
      
      try {
        final weeks = json.decode(course.weeks!);
        return weeks.contains(tomorrowWeek);
      } catch (e) {
        return false;
      }
    }).toList();
    
    filtered.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    return filtered;
  }
  
  /// 获取当前正在上的课程
  Course? _getCurrentCourse(List<Course> todayCourses, DateTime now, SchoolTimeTemplate timeTemplate) {
    final currentPeriod = _getCurrentPeriod(now, timeTemplate);
    if (currentPeriod == 0) return null;
    
    for (final course in todayCourses) {
      final startPeriod = course.startTime ?? 0;
      final endPeriod = startPeriod + (course.timeCount ?? 1) - 1;
      
      if (currentPeriod >= startPeriod && currentPeriod <= endPeriod) {
        return course;
      }
    }
    
    return null;
  }
  
  /// 获取下一节课
  Course? _getNextCourse(List<Course> todayCourses, DateTime now, SchoolTimeTemplate timeTemplate) {
    final currentPeriod = _getCurrentPeriod(now, timeTemplate);
    
    for (final course in todayCourses) {
      final startPeriod = course.startTime ?? 0;
      if (startPeriod > currentPeriod) {
        return course;
      }
    }
    
    return null;
  }
  
  /// 获取当前节次（基于时间模板）
  int _getCurrentPeriod(DateTime now, SchoolTimeTemplate timeTemplate) {
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;
    
    for (int i = 0; i < timeTemplate.periods.length; i++) {
      final period = timeTemplate.periods[i];
      final startMinutes = _parseTimeToMinutes(period.startTime);
      final endMinutes = _parseTimeToMinutes(period.endTime);
      
      if (totalMinutes >= startMinutes && totalMinutes <= endMinutes) {
        return i + 1;
      }
    }
    
    return 0; // 非上课时间
  }
  
  /// 解析时间为分钟数
  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return hour * 60 + minute;
      }
    } catch (e) {
      // ignore
    }
    return 0;
  }
  
  /// 构建周课表
  /// 复用课表前端逻辑：使用本周课程（activeCourses + multiCourses[0]）
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
  WidgetCourse _convertToWidgetCourse(Course course, String schoolId) {
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
      color: course.color,
      schoolId: schoolId,
      weeks: weeksList,
      courseType: course.importType == 1 ? 'import' : 'manual',
      notes: course.info,
    );
  }
  
  /// 转换周课表格式
  Map<int, List<WidgetCourse>> _convertWeekScheduleToWidget(
    Map<int, List<Course>> schedule,
    String schoolId,
  ) {
    final widgetSchedule = <int, List<WidgetCourse>>{};
    
    for (final entry in schedule.entries) {
      final widgetCourses = entry.value
          .map((c) => _convertToWidgetCourse(c, schoolId))
          .toList();
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
      version: '1.0',
      timestamp: DateTime.now(),
      schoolId: defaultTemplate.schoolId,
      schoolName: defaultTemplate.schoolName,
      timeTemplate: defaultTemplate,
      currentWeek: 1,
      currentWeekDay: DateTime.now().weekday,
      semesterName: '${DateTime.now().year}学年',
      todayCourses: [],
      tomorrowCourses: [],
      nextCourse: null,
      currentCourse: null,
      weekSchedule: {},
      todayCourseCount: 0,
      tomorrowCourseCount: 0,
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
