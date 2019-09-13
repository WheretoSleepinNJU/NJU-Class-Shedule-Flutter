import '../../generated/i18n.dart';
import 'package:flutter/material.dart';
import '../../Models/CourseModel.dart';
import '../../Models/ScheduleModel.dart';
import '../../Resources/Config.dart';
import '../../Utils/ColorUtil.dart';
import 'package:flutter_swiper/flutter_swiper.dart';

import 'Widgets/CourseDetailDialog.dart';
import 'Widgets/CourseDeleteDialog.dart';
import 'Widgets/CourseWidget.dart';

class CourseTablePresenter {
  CourseProvider courseProvider = new CourseProvider();
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];
  List<List<Course>> multiCourses = [];

  refreshClasses(int tableId, int nowWeek) async {
    List<Map> allCoursesMap = await courseProvider.getAllCourses(tableId);
    List<Course> allCourses = [];
    for (Map courseMap in allCoursesMap) {
      allCourses.add(new Course.fromMap(courseMap));
    }
    ScheduleModel scheduleModel = new ScheduleModel(allCourses, nowWeek);
    activeCourses = scheduleModel.activeCourses;
    hideCourses = scheduleModel.hideCourses;
    multiCourses = scheduleModel.multiCourses;
  }

  Future<List<Widget>> getClassesWidgetList(
      BuildContext context, double height, double width) async {
    List colorPool = await ColorPool.getColorPool();
    return List.generate(
            hideCourses.length,
            (int i) => CourseWidget(
                  hideCourses[i],
                  Config.HIDE_CLASS_COLOR,
                  height,
                  width,
                  () => showClassDialog(context, hideCourses[i]),
                  () => showDeleteDialog(
                    context,
                    hideCourses[i],
                  ),
                  preText: S.of(context).not_this_week,
                )) +
        List.generate(
            activeCourses.length,
            (int i) => CourseWidget(
                  activeCourses[i],
                  activeCourses[i].getColor(colorPool),
                  height,
                  width,
                  () => showClassDialog(context, activeCourses[i]),
                  () => showDeleteDialog(context, activeCourses[i]),
                )) +
        List.generate(
            multiCourses.length,
            (int i) => CourseWidget(
                multiCourses[i][0],
                multiCourses[i][0].getColor(colorPool),
                height,
                width,
                () => showMultiClassDialog(context, i),
                () => showDeleteDialog(context, multiCourses[i][0])));
  }

  showClassDialog(BuildContext context, Course course) {
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return CourseDetailDialog(course, () {
            Navigator.of(context).pop();
          });
        });
  }

  showMultiClassDialog(BuildContext context, int i) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return Swiper(
            itemBuilder: (BuildContext context, int index) {
              return CourseDetailDialog(
                  multiCourses[i][index], () => Navigator.of(context).pop());
            },
            itemCount: multiCourses[i].length,
            pagination: new SwiperPagination(
                margin: new EdgeInsets.only(bottom: 100),
                builder: new DotSwiperPaginationBuilder(
                    color: Colors.grey,
                    activeColor: Theme.of(context).primaryColor)),
            loop: false,
            viewportFraction: 0.8,
            scale: 0.9,
          );
        });
  }

  showDeleteDialog(BuildContext context, Course course) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return CourseDeleteDialog(course);
      },
    );
  }

  //TEST: 测试用函数
  Future insertMockData() async {
    await courseProvider.insert(new Course(
        0, "微积分", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
        color: '#8AD297', classroom: 'QAQ'));
    await courseProvider.insert(new Course(
        0, "线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
        color: '#F9A883', classroom: '仙林校区不知道哪个教室'));
    await courseProvider.insert(new Course(
        1, "并不是线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
        color: '#F9A883', classroom: 'QAQ'));
  }
}
