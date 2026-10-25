import 'dart:convert';
import '../../Models/CourseModel.dart';
import '../../Resources/Constant.dart';
import '../../core/widget_data/utils/widget_refresh_helper.dart';
import 'CourseMeetingInput.dart';

class EditCoursePresenter {
  final CourseProvider provider;
  final Future<void> Function() refreshWidgets;
  final Future<void> Function() _refreshAfterDeletion;

  EditCoursePresenter({
    CourseProvider? provider,
    Future<void> Function()? refreshWidgets,
  }) : provider = provider ?? CourseProvider(),
       refreshWidgets =
           refreshWidgets ?? WidgetRefreshHelper.refreshAfterCourseUpdated,
       _refreshAfterDeletion =
           refreshWidgets ?? WidgetRefreshHelper.refreshAfterCourseDeleted;

  Future<bool> saveMeetings({
    required List<Course> originals,
    required int tableId,
    required String name,
    required String info,
    required List<CourseMeetingInput> meetings,
    bool updateInfo = true,
  }) async {
    if (name.trim().isEmpty ||
        meetings.isEmpty ||
        meetings.any((m) => !m.isValid)) {
      return false;
    }
    final originalIds = originals.map((c) => c.id).toSet();
    if (originals.any((c) => c.id == null) ||
        meetings.any(
          (m) => m.original != null && !originalIds.contains(m.original!.id),
        )) {
      return false;
    }
    final template = originals.isEmpty ? null : originals.first;
    final updated =
        meetings.map((meeting) {
          final source = meeting.original ?? template;
          final course =
              source == null
                  ? Course(tableId, name, '[]', 1, 1, 0, Constant.ADD_MANUALLY)
                  : Course.fromMap(source.toMap());
          final weeks = meeting.weeks.toSet().toList()..sort();
          return course
            ..id = meeting.original?.id
            ..tableId = tableId
            ..name = name.trim()
            ..teacher =
                meeting.teacher.trim().isEmpty ? null : meeting.teacher.trim()
            ..classroom =
                meeting.classroom.trim().isEmpty
                    ? null
                    : meeting.classroom.trim()
            ..info =
                updateInfo || meeting.original == null
                    ? info.trim()
                    : meeting.original!.info
            ..weeks = jsonEncode(weeks)
            ..weekTime = meeting.timePending ? 0 : meeting.weekTime
            ..startTime = meeting.timePending ? 0 : meeting.startTime
            ..timeCount =
                meeting.timePending ? 0 : meeting.endTime - meeting.startTime;
        }).toList();
    if (!await provider.saveMeetingGroup(originals, updated)) return false;
    await refreshWidgets();
    return true;
  }

  Future<bool> delete(List<Course> originals) async {
    if (!await provider.deleteMeetingGroup(originals)) return false;
    await _refreshAfterDeletion();
    return true;
  }

  Future<bool> save(
    Course original, {
    required String name,
    required String teacher,
    required String classroom,
    required String info,
    required List<int> weeks,
    required int weekTime,
    required int startTime,
    required int endTime,
    required bool timePending,
  }) => saveMeetings(
    originals: [original],
    tableId: original.tableId!,
    name: name,
    info: info,
    meetings: [
      CourseMeetingInput(
        original: original,
        weeks: weeks,
        weekTime: weekTime,
        startTime: startTime,
        endTime: endTime,
        teacher: teacher,
        classroom: classroom,
        timePending: timePending,
      ),
    ],
  );
}
