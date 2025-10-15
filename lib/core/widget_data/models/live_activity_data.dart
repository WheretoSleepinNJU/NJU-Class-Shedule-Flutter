/// Live Activity 专用数据模型
import 'widget_course.dart';

class LiveActivityData {
  final String activityId;              // 活动唯一ID
  final String courseId;                // 课程ID
  final String courseName;              // 课程名称
  final String? classroom;              // 教室
  final String? teacher;                // 教师
  final DateTime startTime;             // 开始时间
  final DateTime endTime;               // 结束时间
  final String schoolId;                // 学校ID
  final String schoolName;              // 学校名称
  final String? color;                  // 课程颜色
  final LiveActivityStatus status;      // 活动状态
  final LiveActivityTrigger trigger;    // 触发条件
  
  // 动态内容
  final String? timeRemainingText;      // "还有25分钟"
  final int? minutesUntilStart;         // 剩余分钟数
  final double? progress;               // 进度条 (0.0-1.0)
  final String? statusText;             // 状态文本
  
  // 元数据
  final DateTime createdAt;             // 创建时间
  final DateTime updatedAt;             // 更新时间
  final String? notificationId;         // 关联通知ID

  LiveActivityData({
    required this.activityId,
    required this.courseId,
    required this.courseName,
    this.classroom,
    this.teacher,
    required this.startTime,
    required this.endTime,
    required this.schoolId,
    required this.schoolName,
    this.color,
    required this.status,
    required this.trigger,
    this.timeRemainingText,
    this.minutesUntilStart,
    this.progress,
    this.statusText,
    required this.createdAt,
    required this.updatedAt,
    this.notificationId,
  });

  // 从 WidgetCourse 创建
  factory LiveActivityData.fromCourse({
    required WidgetCourse course,
    required LiveActivityTrigger trigger,
    DateTime? customStartTime,
    required DateTime createdAt,
  }) {
    final startTime = customStartTime ?? DateTime.now();
    final endTime = startTime.add(const Duration(minutes: 50)); // 假设50分钟课程

    final minutesUntilStart = startTime.difference(DateTime.now()).inMinutes;
    final timeText = _formatTimeRemaining(minutesUntilStart);
    final progress = _calculateProgress(minutesUntilStart, trigger);
    
    return LiveActivityData(
      activityId: 'class_${course.id}_${trigger.name}_${startTime.millisecondsSinceEpoch}',
      courseId: course.id,
      courseName: course.name,
      classroom: course.classroom,
      teacher: course.teacher,
      startTime: startTime,
      endTime: endTime,
      schoolId: course.schoolId,
      schoolName: '南京大学', // 可以从模板获取
      color: course.color,
      status: LiveActivityStatus.scheduled,
      trigger: trigger,
      timeRemainingText: timeText,
      minutesUntilStart: minutesUntilStart,
      progress: progress,
      statusText: _getStatusText(trigger, minutesUntilStart),
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  // JSON 序列化
  Map<String, dynamic> toJson() => {
    'activityId': activityId,
    'courseId': courseId,
    'courseName': courseName,
    'classroom': classroom,
    'teacher': teacher,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'schoolId': schoolId,
    'schoolName': schoolName,
    'color': color,
    'status': status.name,
    'trigger': trigger.name,
    'timeRemainingText': timeRemainingText,
    'minutesUntilStart': minutesUntilStart,
    'progress': progress,
    'statusText': statusText,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'notificationId': notificationId,
  };

  // JSON 反序列化
  factory LiveActivityData.fromJson(Map<String, dynamic> json) => LiveActivityData(
    activityId: json['activityId'],
    courseId: json['courseId'],
    courseName: json['courseName'],
    classroom: json['classroom'],
    teacher: json['teacher'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    schoolId: json['schoolId'],
    schoolName: json['schoolName'],
    color: json['color'],
    status: LiveActivityStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => LiveActivityStatus.scheduled,
    ),
    trigger: LiveActivityTrigger.values.firstWhere(
      (t) => t.name == json['trigger'],
      orElse: () => LiveActivityTrigger.manual,
    ),
    timeRemainingText: json['timeRemainingText'],
    minutesUntilStart: json['minutesUntilStart'],
    progress: json['progress']?.toDouble(),
    statusText: json['statusText'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    notificationId: json['notificationId'],
  );

  /// 更新活动数据
  LiveActivityData copyWith({
    LiveActivityStatus? status,
    String? timeRemainingText,
    int? minutesUntilStart,
    double? progress,
    String? statusText,
    DateTime? updatedAt,
  }) {
    return LiveActivityData(
      activityId: activityId,
      courseId: courseId,
      courseName: courseName,
      classroom: classroom,
      teacher: teacher,
      startTime: startTime,
      endTime: endTime,
      schoolId: schoolId,
      schoolName: schoolName,
      color: color,
      status: status ?? this.status,
      trigger: trigger,
      timeRemainingText: timeRemainingText ?? this.timeRemainingText,
      minutesUntilStart: minutesUntilStart ?? this.minutesUntilStart,
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notificationId: notificationId,
    );
  }

  /// 检查是否过期
  bool get isExpired => DateTime.now().isAfter(endTime);
  
  /// 检查是否即将开始（30分钟内）
  bool get isImminent {
    final now = DateTime.now();
    return now.isAfter(startTime.subtract(Duration(minutes: 30))) && now.isBefore(startTime);
  }
  
  /// 检查是否活跃
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// 获取显示标题
  String get displayTitle {
    switch (status) {
      case LiveActivityStatus.scheduled:
        return '即将上课';
      case LiveActivityStatus.active:
        return '正在上课';
      case LiveActivityStatus.ending:
        return '即将结束';
      default:
        return courseName;
    }
  }

  /// 获取显示副标题
  String? get displaySubtitle {
    if (timeRemainingText != null) return timeRemainingText;
    if (classroom != null) return classroom;
    return null;
  }

  @override
  String toString() => 'LiveActivityData($activityId: $courseName, $status, ${trigger.name})';
}

/// 活动状态枚举
enum LiveActivityStatus {
  scheduled,      // 已安排（未开始）
  active,         // 活跃中
  updating,       // 更新中
  ending,         // 即将结束
  ended,          // 已结束
  failed,         // 失败
}

/// 触发条件枚举
enum LiveActivityTrigger {
  before30Min,    // 课前30分钟
  before15Min,    // 课前15分钟
  before5Min,     // 课前5分钟
  classStart,     // 课程开始
  classEnd,       // 课程结束
  manual,         // 手动触发
  system,         // 系统触发
}

/// 格式化剩余时间
String _formatTimeRemaining(int minutes) {
  if (minutes < 1) return '即将开始';
  if (minutes < 60) return '还有 $minutes 分钟';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return '还有 $hours 小时 $remainingMinutes 分钟';
}

/// 计算进度
double _calculateProgress(int minutesUntilStart, LiveActivityTrigger trigger) {
  final triggerMinutes = _getTriggerMinutes(trigger);
  final totalMinutes = triggerMinutes + 30; // 假设30分钟前开始计算
  return (totalMinutes - minutesUntilStart) / totalMinutes;
}

/// 获取触发时间（分钟）
int _getTriggerMinutes(LiveActivityTrigger trigger) {
  switch (trigger) {
    case LiveActivityTrigger.before30Min: return 30;
    case LiveActivityTrigger.before15Min: return 15;
    case LiveActivityTrigger.before5Min: return 5;
    default: return 30;
  }
}

/// 获取状态文本
String _getStatusText(LiveActivityTrigger trigger, int minutesUntilStart) {
  if (minutesUntilStart <= 0) return '即将开始';
  if (minutesUntilStart <= 5) return '马上开始';
  if (minutesUntilStart <= 15) return '即将上课';
  return '还有 $minutesUntilStart 分钟';
}