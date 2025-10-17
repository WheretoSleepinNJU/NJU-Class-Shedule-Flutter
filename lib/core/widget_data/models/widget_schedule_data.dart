/// Widget 通用课表数据
import 'widget_course.dart';
import 'school_time_template.dart';

class WidgetScheduleData {
  final String version;                    // 数据版本
  final DateTime timestamp;                // 生成时间戳
  final String schoolId;                   // 学校ID
  final String schoolName;                 // 学校名称
  final SchoolTimeTemplate timeTemplate;   // 时间模板
  final int currentWeek;                   // 当前周数
  final int currentWeekDay;                // 当前星期几
  final String semesterName;               // 学期名称
  
  // 核心课程数据
  final List<WidgetCourse> todayCourses;     // 今日课程（已排序）
  final List<WidgetCourse> tomorrowCourses;  // 明日课程（已排序）
  final WidgetCourse? nextCourse;            // 下一节课
  final WidgetCourse? currentCourse;         // 当前课程（如果正在上课）
  
  // 本周课表
  final Map<int, List<WidgetCourse>> weekSchedule; // 本周每天课程
  
  // 统计信息
  final int todayCourseCount;
  final int tomorrowCourseCount;
  final int weekCourseCount;
  final bool hasCoursesToday;
  final bool hasCoursesTomorrow;
  
  // 元信息
  final String dataSource;                 // 数据来源
  final int totalCourses;                  // 总课程数
  final DateTime? lastUpdateTime;          // 最后更新时间

  // Widget 配置选项
  final int? approachingMinutes;           // 即将上课提前时间（分钟），默认15
  final int? tomorrowPreviewHour;          // 明日预览开始时间（小时），默认21

  WidgetScheduleData({
    this.version = '1.0',
    required this.timestamp,
    required this.schoolId,
    required this.schoolName,
    required this.timeTemplate,
    required this.currentWeek,
    required this.currentWeekDay,
    required this.semesterName,
    required this.todayCourses,
    required this.tomorrowCourses,
    this.nextCourse,
    this.currentCourse,
    required this.weekSchedule,
    required this.todayCourseCount,
    required this.tomorrowCourseCount,
    required this.weekCourseCount,
    required this.hasCoursesToday,
    required this.hasCoursesTomorrow,
    this.dataSource = 'local',
    required this.totalCourses,
    this.lastUpdateTime,
    this.approachingMinutes,
    this.tomorrowPreviewHour,
  });

  // JSON 序列化
  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'schoolId': schoolId,
    'schoolName': schoolName,
    'timeTemplate': timeTemplate.toJson(),
    'currentWeek': currentWeek,
    'currentWeekDay': currentWeekDay,
    'semesterName': semesterName,
    'todayCourses': todayCourses.map((c) => c.toJson()).toList(),
    'tomorrowCourses': tomorrowCourses.map((c) => c.toJson()).toList(),
    'nextCourse': nextCourse?.toJson(),
    'currentCourse': currentCourse?.toJson(),
    'weekSchedule': weekSchedule.map((k, v) => 
      MapEntry(k.toString(), v.map((c) => c.toJson()).toList())
    ),
    'todayCourseCount': todayCourseCount,
    'tomorrowCourseCount': tomorrowCourseCount,
    'weekCourseCount': weekCourseCount,
    'hasCoursesToday': hasCoursesToday,
    'hasCoursesTomorrow': hasCoursesTomorrow,
    'dataSource': dataSource,
    'totalCourses': totalCourses,
    'lastUpdateTime': lastUpdateTime?.toIso8601String(),
    'approachingMinutes': approachingMinutes,
    'tomorrowPreviewHour': tomorrowPreviewHour,
  };

  // JSON 反序列化
  factory WidgetScheduleData.fromJson(Map<String, dynamic> json) => WidgetScheduleData(
    version: json['version'] ?? '1.0',
    timestamp: DateTime.parse(json['timestamp']),
    schoolId: json['schoolId'],
    schoolName: json['schoolName'],
    timeTemplate: SchoolTimeTemplate.fromJson(json['timeTemplate']),
    currentWeek: json['currentWeek'],
    currentWeekDay: json['currentWeekDay'],
    semesterName: json['semesterName'],
    todayCourses: (json['todayCourses'] as List)
        .map((c) => WidgetCourse.fromJson(c))
        .toList(),
    tomorrowCourses: (json['tomorrowCourses'] as List)
        .map((c) => WidgetCourse.fromJson(c))
        .toList(),
    nextCourse: json['nextCourse'] != null 
        ? WidgetCourse.fromJson(json['nextCourse']) 
        : null,
    currentCourse: json['currentCourse'] != null 
        ? WidgetCourse.fromJson(json['currentCourse']) 
        : null,
    weekSchedule: (json['weekSchedule'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(
            int.parse(k), 
            (v as List).map((c) => WidgetCourse.fromJson(c)).toList()
        )),
    todayCourseCount: json['todayCourseCount'],
    tomorrowCourseCount: json['tomorrowCourseCount'],
    weekCourseCount: json['weekCourseCount'],
    hasCoursesToday: json['hasCoursesToday'],
    hasCoursesTomorrow: json['hasCoursesTomorrow'],
    dataSource: json['dataSource'] ?? 'local',
    totalCourses: json['totalCourses'],
    lastUpdateTime: json['lastUpdateTime'] != null
        ? DateTime.parse(json['lastUpdateTime'])
        : null,
    approachingMinutes: json['approachingMinutes'],
    tomorrowPreviewHour: json['tomorrowPreviewHour'],
  );

  /// 获取今日课程时间文本
  String getTodayScheduleText() {
    if (!hasCoursesToday) return '今天没有课程';
    
    final buffer = StringBuffer();
    buffer.writeln('今天有 $todayCourseCount 节课：');
    
    for (final course in todayCourses) {
      final timeRange = timeTemplate.getPeriodRange(course.startPeriod, course.periodCount);
      final timeText = timeRange != null ? '${timeRange.startTime}-${timeRange.endTime}' : '第${course.startPeriod}节';
      buffer.writeln('${course.name} ($timeText)');
      if (course.classroom != null) {
        buffer.writeln('  📍 ${course.classroom}');
      }
    }
    
    return buffer.toString();
  }

  /// 获取下一节课信息
  String? getNextCourseInfo() {
    if (nextCourse == null) return null;
    
    final course = nextCourse!;
    final timeRange = timeTemplate.getPeriodRange(course.startPeriod, course.periodCount);
    final timeText = timeRange != null ? '${timeRange.startTime}-${timeRange.endTime}' : '第${course.startPeriod}节';
    
    return '${course.name}\n⏰ $timeText\n📍 ${course.classroom ?? '待定'}';
  }

  @override
  String toString() => 'WidgetScheduleData($schoolId: $schoolName, week $currentWeek, $todayCourseCount today courses)';
}