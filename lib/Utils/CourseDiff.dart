import '../Models/CourseModel.dart';

/// 课表变更检测的纯函数 diff 引擎。
///
/// 设计假设（启发式，非精确解）：
/// - 课程编号（`classNumber`）、课程名（`name`）、任课教师（`teacher`）在一学期内不会变，
///   用来判断"是不是同一门课"；`classNumber` 缺失时（部分学校的抓取脚本不提供该字段）
///   退回 `name + teacher` 组合。
/// - 教室（`classroom`）、备注（`info`）、上课节次/星期（`weekTime`/`startTime`/`timeCount`/`weeks`）
///   可能因调课而变化，属于要检测和展示的"变更"内容。
/// - 同一门课在一周内可能有多个时间段（例如周一、周三各一条 `Course` 记录），组内按
///   `weekTime`（星期几）优先配对；配不上的按剩余数量尽量配对；仍然配不上的记为该组内的
///   新增/取消时间段。如果调课连星期都换了，可能被误判为"取消+新增"而不是"变更"——
///   这是已知局限，暂不做更复杂的匹配算法。
class CourseSlotChange {
  final Course oldSlot;
  final Course newSlot;

  /// 字段名 -> {old, new}，只包含实际发生变化的字段。
  final Map<String, MapEntry<String?, String?>> changedFields;

  CourseSlotChange(this.oldSlot, this.newSlot, this.changedFields);

  bool get hasChanges => changedFields.isNotEmpty;
}

class CourseDiffResult {
  /// 新出现的课程分组（按 courseGroupKey 分组），值为该组下的所有时间段。
  final Map<String, List<Course>> addedCourses;

  /// 消失的课程分组。
  final Map<String, List<Course>> removedCourses;

  /// 分组仍在，但组内时间段有字段变化。
  final List<CourseSlotChange> changedSlots;

  /// 分组仍在，组内新增的时间段（例如学期中途加了一节课）。
  final List<Course> addedSlots;

  /// 分组仍在，组内消失的时间段。
  final List<Course> removedSlots;

  CourseDiffResult({
    required this.addedCourses,
    required this.removedCourses,
    required this.changedSlots,
    required this.addedSlots,
    required this.removedSlots,
  });

  bool get isEmpty =>
      addedCourses.isEmpty &&
      removedCourses.isEmpty &&
      changedSlots.isEmpty &&
      addedSlots.isEmpty &&
      removedSlots.isEmpty;
}

/// "这是同一门课"的分组键：优先用课程编号，缺失时退回 课程名+教师。
String courseGroupKey(Course c) {
  final classNumber = c.classNumber?.trim() ?? '';
  if (classNumber.isNotEmpty) {
    return 'no:$classNumber';
  }
  return 'nt:${c.name ?? ''}|${c.teacher ?? ''}';
}

/// 组内一个时间段的"位置标识"：星期几。用于组内配对的第一优先级。
int? _weekTimeOf(Course c) => c.weekTime;

CourseDiffResult diffCourseLists(List<Course> oldList, List<Course> newList) {
  final Map<String, List<Course>> oldGroups = _groupBy(oldList);
  final Map<String, List<Course>> newGroups = _groupBy(newList);

  final addedCourses = <String, List<Course>>{};
  final removedCourses = <String, List<Course>>{};
  final changedSlots = <CourseSlotChange>[];
  final addedSlots = <Course>[];
  final removedSlots = <Course>[];

  for (final key in newGroups.keys) {
    if (!oldGroups.containsKey(key)) {
      addedCourses[key] = newGroups[key]!;
    }
  }
  for (final key in oldGroups.keys) {
    if (!newGroups.containsKey(key)) {
      removedCourses[key] = oldGroups[key]!;
    }
  }

  for (final key in newGroups.keys) {
    final oldSlotsForKey = oldGroups[key];
    if (oldSlotsForKey == null) continue; // 已经算作 addedCourses
    final newSlotsForKey = newGroups[key]!;

    final matched = _matchSlots(oldSlotsForKey, newSlotsForKey);
    for (final pair in matched.pairs) {
      final changes = _diffSlotFields(pair.key, pair.value);
      if (changes.isNotEmpty) {
        changedSlots.add(CourseSlotChange(pair.key, pair.value, changes));
      }
    }
    addedSlots.addAll(matched.unmatchedNew);
    removedSlots.addAll(matched.unmatchedOld);
  }

  return CourseDiffResult(
    addedCourses: addedCourses,
    removedCourses: removedCourses,
    changedSlots: changedSlots,
    addedSlots: addedSlots,
    removedSlots: removedSlots,
  );
}

Map<String, List<Course>> _groupBy(List<Course> courses) {
  final Map<String, List<Course>> groups = {};
  for (final c in courses) {
    groups.putIfAbsent(courseGroupKey(c), () => []).add(c);
  }
  return groups;
}

class _SlotMatchResult {
  final List<MapEntry<Course, Course>> pairs;
  final List<Course> unmatchedOld;
  final List<Course> unmatchedNew;

  _SlotMatchResult(this.pairs, this.unmatchedOld, this.unmatchedNew);
}

_SlotMatchResult _matchSlots(List<Course> oldSlots, List<Course> newSlots) {
  final remainingOld = List<Course>.from(oldSlots);
  final remainingNew = List<Course>.from(newSlots);
  final pairs = <MapEntry<Course, Course>>[];

  // 第一优先级：同星期几配对。
  for (final o in List<Course>.from(remainingOld)) {
    final matchIndex = remainingNew.indexWhere(
      (n) => _weekTimeOf(n) != null && _weekTimeOf(n) == _weekTimeOf(o),
    );
    if (matchIndex != -1) {
      pairs.add(MapEntry(o, remainingNew[matchIndex]));
      remainingOld.remove(o);
      remainingNew.removeAt(matchIndex);
    }
  }

  // 第二优先级：剩余的按原顺序尽量配对（数量对齐的最简单情形）。
  while (remainingOld.isNotEmpty && remainingNew.isNotEmpty) {
    pairs.add(MapEntry(remainingOld.removeAt(0), remainingNew.removeAt(0)));
  }

  return _SlotMatchResult(pairs, remainingOld, remainingNew);
}

Map<String, MapEntry<String?, String?>> _diffSlotFields(
    Course oldSlot, Course newSlot) {
  final changes = <String, MapEntry<String?, String?>>{};

  void compare(String field, String? oldValue, String? newValue) {
    if ((oldValue ?? '') != (newValue ?? '')) {
      changes[field] = MapEntry(oldValue, newValue);
    }
  }

  compare('classroom', oldSlot.classroom, newSlot.classroom);
  compare('info', oldSlot.info, newSlot.info);
  compare('weekTime', oldSlot.weekTime?.toString(), newSlot.weekTime?.toString());
  compare(
      'startTime', oldSlot.startTime?.toString(), newSlot.startTime?.toString());
  compare(
      'timeCount', oldSlot.timeCount?.toString(), newSlot.timeCount?.toString());
  compare('weeks', oldSlot.weeks, newSlot.weeks);

  return changes;
}
