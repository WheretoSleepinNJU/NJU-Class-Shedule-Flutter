import 'package:flutter/widgets.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../generated/l10n.dart';

abstract final class CourseScheduleText {
  static String weeks(BuildContext context, Course meeting) {
    final weeks = meeting.weekNumbers, s = S.of(context);
    if (weeks.isEmpty) return s.weeks_pending;
    if (weeks.length == 1) return s.week(weeks.first);
    final range = s.week_duration(weeks.first, weeks.last);
    if (List.generate(
      weeks.length,
      (i) => weeks[i] == weeks.first + i,
    ).every((v) => v)) {
      return range;
    }
    if (List.generate(
      weeks.length,
      (i) => weeks[i] == weeks.first + 2 * i,
    ).every((v) => v)) {
      return '$range ${weeks.first.isOdd ? s.single_week : s.double_week}';
    }
    return weeks.map((w) => s.week(w)).join('、');
  }

  static String time(
    BuildContext context,
    Course meeting,
    List<Map> classTimeList,
  ) {
    final start = meeting.startTime ?? 0,
        end = start + (meeting.timeCount ?? 0),
        day = meeting.weekTime ?? 0;
    if (day == 0 || start == 0) return S.of(context).free_time;
    final period = start == end
        ? S.of(context).class_single('$start')
        : S.of(context).class_duration('$start', '$end');
    return [
      if (day >= 1 && day <= 7) Constant.WEEK_WITH_BIAS[day],
      period,
      if (start > 0 && end >= start && end <= classTimeList.length)
        '${classTimeList[start - 1]['start']}-${classTimeList[end - 1]['end']}',
    ].join('  |  ');
  }
}
