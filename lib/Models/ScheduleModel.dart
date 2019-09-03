import 'CourseModel.dart';
import 'dart:convert';


class ScheduleModel{
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];

  ScheduleModel(List<Course> courses, int nowWeek){
    for(Course course in courses){
      List weeks  = json.decode(course.weeks);
      if(weeks.contains(nowWeek)) activeCourses.add(course);
      else hideCourses.add(course);
    }
  }
}