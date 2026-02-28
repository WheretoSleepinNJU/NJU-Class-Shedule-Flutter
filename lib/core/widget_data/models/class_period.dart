/// 单节课时间段
class ClassPeriod {
  final String startTime;  // "08:00"
  final String endTime;    // "08:50"

  ClassPeriod({
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime,
    'endTime': endTime,
  };

  factory ClassPeriod.fromJson(Map<String, dynamic> json) => ClassPeriod(
    startTime: json['startTime'],
    endTime: json['endTime'],
  );

  @override
  String toString() => '$startTime-$endTime';
}