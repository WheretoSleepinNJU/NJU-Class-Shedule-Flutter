import 'CourseModel.dart';
import 'dart:convert';


class ScheduleModel {
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];
  List<List<Course>> multiCourses = [
    [
      new Course(0, "微积分", "[1,2,3,4,5,6,7]", 1, 7, 2, 0, classroom: 'QAQ'),
      new Course(0, "还是微积分", "[1,2,3,4,5,6,7]", 1, 7, 2, 0, classroom: 'QAQ'),
      new Course(0, "又是微积分", "[1,2,3,4,5,6,7]", 1, 7, 2, 0, classroom: 'QAQ')
    ]
  ];

  ScheduleModel(List<Course> courses, int nowWeek) {
    for (Course course in courses) {
      List weeks = json.decode(course.weeks);
      if (weeks.contains(nowWeek))
        activeCourses.add(course);
      else
        hideCourses.add(course);
    }
  }
}
