import '../../Models/CourseModel.dart';

class CourseMeetingInput {
  final Course? original;
  final List<int> weeks;
  final int weekTime, startTime, endTime;
  final String teacher, classroom;
  final bool timePending;

  const CourseMeetingInput({
    this.original,
    required this.weeks,
    required this.weekTime,
    required this.startTime,
    required this.endTime,
    required this.teacher,
    required this.classroom,
    this.timePending = false,
  });

  bool get isValid =>
      weeks.isNotEmpty &&
      weeks.every((w) => w > 0) &&
      (timePending ||
          (weekTime >= 1 &&
              weekTime <= 7 &&
              startTime > 0 &&
              endTime >= startTime));
}
