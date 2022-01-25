import 'package:flutter/material.dart';
import '../../Utils/States/MainState.dart';
import '../../Models/CourseModel.dart';
import '../../Resources/Constant.dart';

class AddCoursePresenter {
  Future<bool> addCourse(BuildContext context, String name, String teacher,
      List<Map> nodes) async {
    int tableId = await MainStateModel.of(context).getClassTable();
    // initialize
    if(tableId == 0) {
      tableId = 1;
      await MainStateModel.of(context).changeclassTable(1);
    }
    for (Map node in nodes) {
      Course course = Course(
          tableId,
          name,
          _generateWeekSeries(
              node['startWeek'] + 1, node['endWeek'] + 1, node['weekType']),
          node['weekTime'] + 1,
          node['startTime'] + 1,
          node['endTime'] - node['startTime'],
          Constant.ADD_MANUALLY,
          classroom: node['classroom'] == '' ? null : node['classroom'],
          teacher: teacher == '' ? null : teacher);
      CourseProvider courseProvider = CourseProvider();
      course = await courseProvider.insert(course);
      if (course.id == null) return false;
    }
    return true;
  }

  String _generateWeekSeries(int start, int end, int weekType) {
    if (weekType == Constant.FULL_WEEKS) {
      return _getWeekSeries(start, end);
    } else if (weekType == Constant.SINGLE_WEEKS) {
      return _getSingleWeekSeries(start, end);
    } else if (weekType == Constant.DOUBLE_WEEKS) {
      return _getDoubleWeekSeries(start, end);
    } else {
      return '';
    }
  }

  String _getWeekSeries(int start, int end) {
    List<int> list = [for (int i = start; i <= end; i += 1) i];
//    print (list.toString());
    return list.toString();
  }

  String _getSingleWeekSeries(int start, int end) {
    if (start % 2 == 0) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }

  String _getDoubleWeekSeries(int start, int end) {
    if (start % 2 == 1) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }
}
