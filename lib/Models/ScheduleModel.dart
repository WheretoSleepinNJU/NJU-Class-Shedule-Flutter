import 'CourseModel.dart';
import 'dart:convert';

class ScheduleModel {
  int nowWeek;
  List<Course> courses;
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];
  List<List<Course>> multiCourses = [];

  //TODO: multiCourses
//  List<List<Course>> multiCourses = [
//    [
//      new Course(0, "微积分", "[1,2,3,4,5,6,7]", 1, 7, 2, 0,
//          color: '#8AD297', classroom: 'QAQ'),
//      new Course(0, "还是微积分", "[1,2,3,4,5,6,7]", 1, 7, 2, 0,
//          color: '#F9A883', classroom: 'QAQ'),
//      new Course(0, "又是微积分", "[1,2,3,4,5,6,7]", 1, 7, 2, 0,
//          color: '#F9A883', classroom: 'QAQ')
//    ]
//  ];

  ScheduleModel(this.courses, this.nowWeek);

  init() {
    classify();
    deduplicate();
  }

  void classify() {
    for (Course course in courses) {
      List weeks = json.decode(course.weeks!);
      if (weeks.contains(nowWeek))
        activeCourses.add(course);
      else
        hideCourses.add(course);
    }
  }

//  void deduplication(List<Course> courses, int nowWeek) {
  void deduplicate() {
    List<Course> deduplicateResult = [];
    List<Course> needToDelete = [];
    bool isOverlapped = false;
    // 分开检查的目的是保证 multiCourse 的每一个第一项有最大可能是 active 的
    for (Course course in activeCourses) {
      isOverlapped = false;
      for (List<Course> checked in multiCourses) {
        if (_checkIfOverlapping(course, checked[0])) {
          checked.add(course);
          _checkMultiCousesElement(checked);
          isOverlapped = true;
        }
      }
      if (isOverlapped) continue;
      for (Course checked in deduplicateResult) {
        if (_checkIfOverlapping(course, checked)) {
          multiCourses.add([course, checked]);
          _checkMultiCousesElement(multiCourses.last);
          deduplicateResult.remove(checked);
          needToDelete.add(checked);
          needToDelete.add(course);
          isOverlapped = true;
          break;
        }
      }
      if (!isOverlapped) deduplicateResult.add(course);
    }
    for (Course item in needToDelete) activeCourses.remove(item);
    needToDelete.clear();
    for (Course course in hideCourses) {
      isOverlapped = false;
      for (List<Course> checked in multiCourses) {
        if (_checkIfOverlapping(course, checked[0])) {
          checked.add(course);
          _checkMultiCousesElement(checked);
          isOverlapped = true;
          break;
        }
      }
      if (isOverlapped) continue;
      for (Course checked in deduplicateResult) {
        if (_checkIfOverlapping(course, checked)) {
          multiCourses.add([course, checked]);
          _checkMultiCousesElement(multiCourses.last);
          deduplicateResult.remove(checked);
          needToDelete.add(checked);
          needToDelete.add(course);
          isOverlapped = true;
          break;
        }
      }
      if (!isOverlapped) deduplicateResult.add(course);
    }
    for (Course item in needToDelete) {
      if (hideCourses.contains(item))
        activeCourses.remove(item);
      else
        activeCourses.remove(item);
    }
  }

  bool _checkIfOverlapping(Course a, Course b) {
    bool result = a.weekTime == b.weekTime &&
        ((a.startTime! >= b.startTime! &&
                a.startTime! <= b.startTime! + b.timeCount!) ||
            (b.startTime! >= a.startTime! &&
                b.startTime! <= a.startTime! + a.timeCount!));
//    print(result);
    return result;
  }

  // TODO: Shit codes, may have bugs here.
  void _checkMultiCousesElement(List<Course> multiCoursesElement) {
    int max_count = 0;
    int max_index = 0;
    for (int i = 0; i < multiCoursesElement.length; i++) {
      List weeks = json.decode(multiCoursesElement[i].weeks!);
      if (multiCoursesElement[i].timeCount! > max_count &&
          weeks.contains(nowWeek)) {
        max_count = multiCoursesElement[i].timeCount!;
        max_index = i;
      }
    }
    if (max_index != 0) {
      Course tmp = multiCoursesElement[max_index];
      multiCoursesElement[max_index] = multiCoursesElement[0];
      multiCoursesElement[0] = tmp;
    }
  }
}
