import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Models/CourseModel.dart';
import '../../../Models/CourseTableModel.dart';
import '../../../Models/ScheduleModel.dart';
import '../../../Utils/ColorUtil.dart';
import '../models/widget_course.dart';
import '../models/widget_schedule_data.dart';
import '../models/school_time_template.dart';

/// Widget 数据构建器
/// 负责从 SQLite 读取课程数据并构建 Widget 所需的数据结构
class WidgetDataBuilder {
  final SharedPreferences preferences;
  final CourseProvider _courseProvider = CourseProvider();
  final CourseTableProvider _courseTableProvider = CourseTableProvider();

  WidgetDataBuilder({required this.preferences});

  /// 构建完整的 Widget 数据
  Future<WidgetScheduleData> buildWidgetData() async {
    // 1. 获取当前课程表 ID 和周次
    final tableId = preferences.getInt('tableId') ?? 0;
    final currentWeek = preferences.getInt('weekIndex') ?? 1;

    // 2. 获取学校信息和时间模板
    final schoolId = preferences.getString('school_id') ?? 'nju';
    final schoolName = await _getSchoolName(schoolId);
    final timeTemplate = _getTimeTemplate(schoolId);

    // 3. 获取学期名称
    final courseTable = await _courseTableProvider.getCourseTable(tableId);
    final semesterName = courseTable?.name ?? '当前学期';

    // 4. 获取所有课程
    final allCoursesMap = await _courseProvider.getAllCourses(tableId);
    final allCourses = allCoursesMap
        .map((map) => Course.fromMap(map as Map<String, dynamic>))
        .toList();

    // 5. 使用 ScheduleModel 分类课程
    final scheduleModel = ScheduleModel(allCourses, currentWeek);
    scheduleModel.init();

    // 6. 获取今日和明日的课程
    final now = DateTime.now();
    final currentWeekDay = now.weekday; // 1-7 (Monday-Sunday)

    final todayCourses = _getCoursesForWeekDay(
      scheduleModel.activeCourses,
      currentWeekDay,
      currentWeek,
    );

    // 计算明天的星期几和周次
    final tomorrowWeekDay = currentWeekDay == 7 ? 1 : currentWeekDay + 1;
    // 如果今天是周日，明天（周一）应该是下一周
    final tomorrowWeek = currentWeekDay == 7 ? currentWeek + 1 : currentWeek;
    
    // 获取明天的课程
    final List<Course> tomorrowCourses;
    if (tomorrowWeek == currentWeek) {
      // 明天还是本周，直接使用当前的 activeCourses
      tomorrowCourses = _getCoursesForWeekDay(
        scheduleModel.activeCourses,
        tomorrowWeekDay,
        tomorrowWeek,
      );
    } else {
      // 明天是下周，需要重新创建 ScheduleModel 来获取下周的活动课程
      final nextWeekSchedule = ScheduleModel(allCourses, tomorrowWeek);
      nextWeekSchedule.init();
      tomorrowCourses = _getCoursesForWeekDay(
        nextWeekSchedule.activeCourses,
        tomorrowWeekDay,
        tomorrowWeek,
      );
    }

    // 7. 计算当前课程和下一节课
    final currentCourse = _getCurrentCourse(todayCourses, timeTemplate);
    final nextCourse = _getNextCourse(todayCourses, timeTemplate);

    // 8. 构建周课表
    final weekSchedule = _buildWeekSchedule(
      scheduleModel.activeCourses,
      currentWeek,
    );

    // 9. 转换为 Widget 课程格式
    final widgetTodayCourses = todayCourses
        .map((c) => _convertToWidgetCourse(c, schoolId))
        .toList();

    final widgetTomorrowCourses = tomorrowCourses
        .map((c) => _convertToWidgetCourse(c, schoolId))
        .toList();

    final widgetCurrentCourse = currentCourse != null
        ? _convertToWidgetCourse(currentCourse, schoolId)
        : null;

    final widgetNextCourse = nextCourse != null
        ? _convertToWidgetCourse(nextCourse, schoolId)
        : null;

    // 10. 构建 WidgetScheduleData
    return WidgetScheduleData(
      version: '1.0',
      timestamp: now,
      schoolId: schoolId,
      schoolName: schoolName,
      timeTemplate: timeTemplate,
      currentWeek: currentWeek,
      currentWeekDay: currentWeekDay,
      semesterName: semesterName,
      todayCourses: widgetTodayCourses,
      tomorrowCourses: widgetTomorrowCourses,
      nextCourse: widgetNextCourse,
      currentCourse: widgetCurrentCourse,
      weekSchedule: weekSchedule,
      todayCourseCount: widgetTodayCourses.length,
      tomorrowCourseCount: widgetTomorrowCourses.length,
      weekCourseCount: allCourses.length,
      hasCoursesToday: widgetTodayCourses.isNotEmpty,
      hasCoursesTomorrow: widgetTomorrowCourses.isNotEmpty,
      dataSource: 'sqlite',
      totalCourses: allCourses.length,
      lastUpdateTime: now,
    );
  }

  /// 获取指定星期几的课程
  /// 注意：activeCourses 已经通过 ScheduleModel.classify() 按周过滤过了
  /// 这里只需要按星期几过滤，确保与主应用的逻辑完全一致
  List<Course> _getCoursesForWeekDay(
    List<Course> activeCourses,
    int weekDay,
    int currentWeek,
  ) {
    final courses = activeCourses.where((course) {
      // 只过滤指定星期几的课程，周过滤已由 ScheduleModel.classify() 完成
      return course.weekTime == weekDay;
    }).toList();

    // 按上课时间排序
    courses.sort((a, b) => a.startTime!.compareTo(b.startTime!));
    return courses;
  }

  /// 获取当前正在上的课程
  Course? _getCurrentCourse(List<Course> todayCourses, SchoolTimeTemplate template) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute; // 转换为分钟数

    for (final course in todayCourses) {
      final period = template.getPeriodRange(
        course.startTime!,
        course.timeCount!,
      );

      if (period == null) continue;

      final startMinutes = _timeToMinutes(period.startTime);
      final endMinutes = _timeToMinutes(period.endTime);

      if (currentTime >= startMinutes && currentTime <= endMinutes) {
        return course;
      }
    }

    return null;
  }

  /// 获取下一节课
  Course? _getNextCourse(List<Course> todayCourses, SchoolTimeTemplate template) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;

    for (final course in todayCourses) {
      final period = template.getPeriodRange(
        course.startTime!,
        course.timeCount!,
      );

      if (period == null) continue;

      final startMinutes = _timeToMinutes(period.startTime);

      if (currentTime < startMinutes) {
        return course;
      }
    }

    return null;
  }

  /// 将时间字符串转换为分钟数
  int _timeToMinutes(String timeString) {
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  /// 构建整周课表
  Map<int, List<WidgetCourse>> _buildWeekSchedule(
    List<Course> activeCourses,
    int currentWeek,
  ) {
    final weekSchedule = <int, List<WidgetCourse>>{};
    final schoolId = preferences.getString('school_id') ?? 'nju';

    for (int weekDay = 1; weekDay <= 7; weekDay++) {
      final courses = _getCoursesForWeekDay(activeCourses, weekDay, currentWeek);
      weekSchedule[weekDay] = courses
          .map((c) => _convertToWidgetCourse(c, schoolId))
          .toList();
    }

    return weekSchedule;
  }

  /// 转换为 Widget 课程格式
  WidgetCourse _convertToWidgetCourse(Course course, String schoolId) {
    // 解析 weeks 字段
    List<int> weeks = [];
    try {
      final weeksJson = json.decode(course.weeks!);
      weeks = (weeksJson as List).map((e) => e as int).toList();
    } catch (e) {
      weeks = [];
    }

    return WidgetCourse(
      id: course.id?.toString() ?? course.courseId?.toString() ?? '0',
      name: course.name ?? '未命名课程',
      classroom: course.classroom,
      teacher: course.teacher,
      startPeriod: course.startTime ?? 1,
      periodCount: course.timeCount ?? 1,
      weekDay: course.weekTime ?? 1,
      color: course.color,
      schoolId: schoolId,
      weeks: weeks,
      courseType: null,
      notes: course.info,
    );
  }

  /// 获取学校名称
  Future<String> _getSchoolName(String schoolId) async {
    // 可以从配置或数据库读取
    switch (schoolId) {
      case 'nju':
        return '南京大学';
      case 'seu':
        return '东南大学';
      case 'sjtu':
        return '上海交通大学';
      case 'ruc':
        return '中国人民大学';
      default:
        return '未知学校';
    }
  }

  /// 获取学校时间模板
  SchoolTimeTemplate _getTimeTemplate(String schoolId) {
    switch (schoolId) {
      case 'seu':
        return SchoolTimeTemplate.southeastUniversity;
      case 'nju':
      default:
        return SchoolTimeTemplate.nanjingUniversity;
    }
  }
}
