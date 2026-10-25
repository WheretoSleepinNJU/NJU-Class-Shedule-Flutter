import 'CourseModel.dart';

/// A course can have several rows, each with its own weeks, room and time.
class CourseGroup {
  static bool sameCourse(Course a, Course b) {
    if (a.tableId != b.tableId) return false;
    if (a.id != null && a.id == b.id) return true;
    if ((a.name?.trim().isEmpty ?? true) ||
        a.name?.trim() != b.name?.trim() ||
        a.importType != b.importType) {
      return false;
    }
    final sectionA = a.classNumber?.trim() ?? '';
    final sectionB = b.classNumber?.trim() ?? '';
    if (sectionA.isNotEmpty || sectionB.isNotEmpty) {
      return sectionA.isNotEmpty && sectionA == sectionB;
    }
    if (a.courseId != null && b.courseId != null) {
      return a.courseId == b.courseId;
    }
    return (a.teacher?.trim() ?? '') == (b.teacher?.trim() ?? '');
  }

  static List<List<Course>> collect(Iterable<Course> courses) {
    final groups = <List<Course>>[];
    for (final course in courses) {
      final group =
          groups.where((g) => sameCourse(g.first, course)).firstOrNull;
      if (group == null) {
        groups.add([course]);
      } else {
        group.add(course);
      }
    }
    return groups;
  }
}
