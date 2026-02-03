import 'class_period.dart';

/// 学校时间模板（多学校支持）
class SchoolTimeTemplate {
  final String schoolId;              // 学校唯一标识
  final String schoolName;            // 学校名称
  final String schoolNameEn;          // 学校英文名称
  final List<ClassPeriod> periods;    // 上课时间段
  
  SchoolTimeTemplate({
    required this.schoolId,
    required this.schoolName,
    required this.schoolNameEn,
    required this.periods,
  });

  // 获取指定节次的时间段
  ClassPeriod? getPeriod(int periodNumber) {
    if (periodNumber <= 0 || periodNumber > periods.length) return null;
    return periods[periodNumber - 1]; // 1-based to 0-based
  }

  // 获取连续多节的时间段
  ClassPeriod? getPeriodRange(int startPeriod, int periodCount) {
    if (startPeriod <= 0 || startPeriod > periods.length) return null;
    final endPeriod = startPeriod + periodCount - 1;
    if (endPeriod > periods.length) return null;
    
    return ClassPeriod(
      startTime: periods[startPeriod - 1].startTime,
      endTime: periods[endPeriod - 1].endTime,
    );
  }

  // JSON 序列化
  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'schoolName': schoolName,
    'schoolNameEn': schoolNameEn,
    'periods': periods.map((p) => p.toJson()).toList(),
  };

  // JSON 反序列化
  factory SchoolTimeTemplate.fromJson(Map<String, dynamic> json) => SchoolTimeTemplate(
    schoolId: json['schoolId'],
    schoolName: json['schoolName'],
    schoolNameEn: json['schoolNameEn'],
    periods: (json['periods'] as List)
        .map((p) => ClassPeriod.fromJson(p))
        .toList(),
  );

  // 预定义模板 - 南京大学
  static SchoolTimeTemplate get nanjingUniversity => SchoolTimeTemplate(
    schoolId: 'nju',
    schoolName: '南京大学',
    schoolNameEn: 'Nanjing University',
    periods: [
      ClassPeriod(startTime: '08:00', endTime: '08:50'),
      ClassPeriod(startTime: '09:00', endTime: '09:50'),
      ClassPeriod(startTime: '10:10', endTime: '11:00'),
      ClassPeriod(startTime: '11:10', endTime: '12:00'),
      ClassPeriod(startTime: '14:00', endTime: '14:50'),
      ClassPeriod(startTime: '15:00', endTime: '15:50'),
      ClassPeriod(startTime: '16:10', endTime: '17:00'),
      ClassPeriod(startTime: '17:10', endTime: '18:00'),
      ClassPeriod(startTime: '18:30', endTime: '19:20'),
      ClassPeriod(startTime: '19:30', endTime: '20:20'),
      ClassPeriod(startTime: '20:30', endTime: '21:20'),
      ClassPeriod(startTime: '21:30', endTime: '22:20'),
      ClassPeriod(startTime: '22:30', endTime: '23:59'),
    ],
  );

  // 预定义模板 - 东南大学
  static SchoolTimeTemplate get southeastUniversity => SchoolTimeTemplate(
    schoolId: 'seu',
    schoolName: '东南大学',
    schoolNameEn: 'Southeast University',
    periods: [
      ClassPeriod(startTime: '08:00', endTime: '08:45'),
      ClassPeriod(startTime: '08:50', endTime: '09:35'),
      ClassPeriod(startTime: '09:50', endTime: '10:35'),
      ClassPeriod(startTime: '10:40', endTime: '11:25'),
      ClassPeriod(startTime: '11:30', endTime: '12:15'),
      ClassPeriod(startTime: '14:00', endTime: '14:45'),
      ClassPeriod(startTime: '14:50', endTime: '15:35'),
      ClassPeriod(startTime: '15:50', endTime: '16:35'),
      ClassPeriod(startTime: '16:40', endTime: '17:25'),
      ClassPeriod(startTime: '17:30', endTime: '18:15'),
      ClassPeriod(startTime: '19:00', endTime: '19:45'),
      ClassPeriod(startTime: '19:50', endTime: '20:35'),
      ClassPeriod(startTime: '20:40', endTime: '21:25'),
    ],
  );

  // 获取所有预定义模板
  static List<SchoolTimeTemplate> get predefinedTemplates => [
    nanjingUniversity,
    southeastUniversity,
    // 后续可添加更多学校
  ];

  @override
  String toString() => 'SchoolTimeTemplate($schoolId: $schoolName, ${periods.length} periods)';
}