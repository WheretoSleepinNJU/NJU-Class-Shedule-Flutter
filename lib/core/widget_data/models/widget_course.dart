import 'dart:convert';
import 'school_time_template.dart';
import 'class_period.dart';

/// Widget 通用课程模型（平台无关）
/// 支持多学校课表系统，使用节次而非具体时间
class WidgetCourse {
  final String id;                    // 课程唯一ID
  final String name;                  // 课程名称
  final String? classroom;            // 教室
  final String? teacher;              // 教师
  final int startPeriod;              // 开始节次（1-based）
  final int periodCount;              // 持续节数
  final int weekDay;                  // 星期几（1-7）
  final String? color;                // 颜色（HEX）
  final String schoolId;              // 学校ID
  final List<int> weeks;              // 上课周数列表
  final String? courseType;           // 课程类型
  final String? notes;                // 备注信息

  WidgetCourse({
    required this.id,
    required this.name,
    this.classroom,
    this.teacher,
    required this.startPeriod,
    required this.periodCount,
    required this.weekDay,
    this.color,
    required this.schoolId,
    required this.weeks,
    this.courseType,
    this.notes,
  });

  // JSON 序列化
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'classroom': classroom,
    'teacher': teacher,
    'startPeriod': startPeriod,
    'periodCount': periodCount,
    'weekDay': weekDay,
    'color': color,
    'schoolId': schoolId,
    'weeks': weeks,
    'courseType': courseType,
    'notes': notes,
  };

  // JSON 反序列化
  factory WidgetCourse.fromJson(Map<String, dynamic> json) => WidgetCourse(
    id: json['id'],
    name: json['name'],
    classroom: json['classroom'],
    teacher: json['teacher'],
    startPeriod: json['startPeriod'],
    periodCount: json['periodCount'],
    weekDay: json['weekDay'],
    color: json['color'],
    schoolId: json['schoolId'],
    weeks: List<int>.from(json['weeks'] ?? []),
    courseType: json['courseType'],
    notes: json['notes'],
  );

  /// 从数据库 Course 模型转换（需要传入学校ID）
  factory WidgetCourse.fromCourse(dynamic course, String schoolId) {
    // course 参数可以是 Course 对象或 Map
    final Map<String, dynamic> courseMap;

    if (course is Map<String, dynamic>) {
      courseMap = course;
    } else {
      // 假设是 Course 对象，需要转换
      courseMap = {
        'id': course.id?.toString() ?? course.courseId?.toString() ?? '',
        'name': course.name ?? '',
        'classroom': course.classroom,
        'teacher': course.teacher,
        'startTime': course.startTime ?? 1,
        'timeCount': course.timeCount ?? 1,
        'weekTime': course.weekTime ?? 1,
        'color': course.color,
        'weeks': course.weeks ?? '[]',
        'importType': course.importType,
        'info': course.info,
      };
    }

    // 解析周数（可能是字符串或数组）
    List<int> weeksList = [];
    final weeksData = courseMap['weeks'];
    if (weeksData is String) {
      try {
        final decoded = jsonDecode(weeksData);
        weeksList = List<int>.from(decoded);
      } catch (e) {
        weeksList = [];
      }
    } else if (weeksData is List) {
      weeksList = List<int>.from(weeksData);
    }

    // 确定课程类型
    String? courseType;
    final importType = courseMap['importType'];
    if (importType == 0) {
      courseType = 'manual';
    } else if (importType == 1) {
      courseType = 'imported';
    } else if (importType == 2) {
      courseType = 'lecture';
    }

    return WidgetCourse(
      id: courseMap['id']?.toString() ?? '',
      name: courseMap['name']?.toString() ?? '',
      classroom: courseMap['classroom']?.toString(),
      teacher: courseMap['teacher']?.toString(),
      startPeriod: courseMap['startTime'] ?? 1,
      periodCount: courseMap['timeCount'] ?? 1,
      weekDay: courseMap['weekTime'] ?? 1,
      color: courseMap['color']?.toString(),
      schoolId: schoolId,
      weeks: weeksList,
      courseType: courseType,
      notes: courseMap['info']?.toString(),
    );
  }

  /// 根据时间模板获取课程的实际时间段
  ClassPeriod? getTimePeriod(SchoolTimeTemplate template) {
    return template.getPeriodRange(startPeriod, periodCount);
  }

  /// 获取课程开始时间字符串（需要时间模板）
  String? getStartTime(SchoolTimeTemplate template) {
    final period = getTimePeriod(template);
    return period?.startTime;
  }

  /// 获取课程结束时间字符串（需要时间模板）
  String? getEndTime(SchoolTimeTemplate template) {
    final period = getTimePeriod(template);
    return period?.endTime;
  }

  @override
  String toString() {
    return 'WidgetCourse(id: $id, name: $name, schoolId: $schoolId, weekDay: $weekDay, startPeriod: $startPeriod)';
  }
}