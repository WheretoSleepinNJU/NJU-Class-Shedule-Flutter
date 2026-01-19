import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_swiper_null_safety_flutter3/flutter_swiper_null_safety_flutter3.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../Models/CourseTableModel.dart';
import '../../generated/l10n.dart';
import '../../Models/CourseModel.dart';
import '../../Models/ScheduleModel.dart';
import '../../Resources/Config.dart';
import '../../Resources/Url.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Utils/WeekUtil.dart';
import '../../Components/Dialog.dart';
import '../../Components/Toast.dart';
import '../../Components/TransBgTextButton.dart';

import 'Widgets/CourseDetailDialog.dart';
import 'Widgets/HideFreeCourseDialog.dart';
import 'Widgets/CourseDeleteDialog.dart';
import 'Widgets/CourseWidget.dart';

class CourseTablePresenter {
  CourseProvider courseProvider = CourseProvider();
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];
  List<List<Course>> multiCourses = [];
  List<Course> freeCourses = [];

  refreshClasses(int tableId, int nowWeek) async {
    List allCoursesMap = await courseProvider.getAllCourses(tableId);
    List<Course> allCourses = [];
    for (Map<String, dynamic> courseMap in allCoursesMap) {
      allCourses.add(Course.fromMap(courseMap));
    }
    ScheduleModel scheduleModel = ScheduleModel(allCourses, nowWeek);
    scheduleModel.init();

    activeCourses = scheduleModel.activeCourses;
    hideCourses = scheduleModel.hideCourses;
    multiCourses = scheduleModel.multiCourses;
    freeCourses = scheduleModel.freeCourses;
  }

  Future<List<Widget>?> getClassesWidgetList(
      BuildContext context, double height, double width, int nowWeek) async {
    List colorPool = await ColorPool.getColorPool();
    List<Widget> result = List.generate(
            hideCourses.length,
            (int i) => CourseWidget(
                  hideCourses[i],
                  Config.HIDE_CLASS_COLOR,
                  height,
                  width,
                  false,
                  false,
                  () => showClassDialog(context, hideCourses[i], false),
                  () => showDeleteDialog(
                    context,
                    hideCourses[i],
                  ),
                )) +
        List.generate(
            activeCourses.length,
            (int i) => CourseWidget(
                  activeCourses[i],
                  activeCourses[i].getColor(colorPool)!,
                  height,
                  width,
                  true,
                  false,
                  () => showClassDialog(context, activeCourses[i], true),
                  () => showDeleteDialog(context, activeCourses[i]),
                )) +
        List.generate(
            multiCourses.length,
            (int i) => CourseWidget(
                multiCourses[i][0],
                multiCourses[i][0].getColor(colorPool)!,
                height,
                width,
                isThisWeek(multiCourses[i][0], nowWeek),
                true,
                () => showMultiClassDialog(context, i, nowWeek),
                () => showDeleteDialog(context, multiCourses[i][0])));
    return result;
  }

  Future<bool> showAfterImport(BuildContext context) async {
    Dio dio = Dio();
    String url = Url.UPDATE_ROOT + '/complete.json';
    Response response = await dio.get(url);
    String welcomeTitle = '';
    String welcomeContent = '';
    int delaySeconds = Config.DONATE_DIALOG_DELAY_SECONDS;
    if (response.statusCode == HttpStatus.ok) {
      welcomeTitle = response.data['title'];
      welcomeContent = response.data['content_html'];
      delaySeconds = response.data['delay'];
      String semesterStartMonday = response.data['semester_start_monday'];
      int index = await ScopedModel.of<MainStateModel>(context).getClassTable();
      CourseTableProvider courseTableProvider = CourseTableProvider();
      String tmpSemesterStartMonday =
          await courseTableProvider.getSemesterStartMonday(index);
      if (tmpSemesterStartMonday != "") {
        semesterStartMonday = tmpSemesterStartMonday;
      }
      bool isSameWeek = await WeekUtil.isSameWeek(semesterStartMonday, 1);
      if (!isSameWeek) {
        await changeWeek(context, semesterStartMonday);
      }
    } else {
      welcomeTitle = S.of(context).welcome_title;
      welcomeContent = S.of(context).welcome_content_html;
    }
    Timer(Duration(seconds: delaySeconds), () {
      showDonateDialog(context, welcomeTitle, welcomeContent);
    });
    return true;
  }

  void showDonateDialog(
      BuildContext context, String welcomeTitle, String welcomeContent) async {
    UmengCommonSdk.onEvent("import_dialog", {"action": "show"});
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MDialog(
              welcomeTitle,
              SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                    Html(data: welcomeContent),
                    Container(
                        alignment: Alignment.centerRight,
                        child: TransBgTextButton(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                            child: Text(S.of(context).love_and_donate),
                            onPressed: () async {
                              UmengCommonSdk.onEvent(
                                  "import_dialog", {"action": "donate"});
                              if (Platform.isIOS) {
                                _launchURL(Url.URL_APPLE);
                              } else if (Platform.isAndroid) {
                                _launchURL(Url.URL_ANDROID);
                              } else if (Platform.operatingSystem == 'ohos') {
                                _launchURL(Url.URL_OHOS);
                              }
                              Navigator.of(context).pop();
                            })),
                    Container(
                        alignment: Alignment.centerRight,
                        child: TransBgTextButton(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                            child: Text(S.of(context).bug_and_report),
                            onPressed: () {
                              UmengCommonSdk.onEvent(
                                  "import_dialog", {"action": "bug"});
                              if (Platform.isIOS) {
                                _launchURL(Url.QQ_GROUP_APPLE_URL);
                              } else if (Platform.isAndroid) {
                                _launchURL(Url.QQ_GROUP_ANDROID_URL);
                              } else if (Platform.operatingSystem == 'ohos') {
                                _launchURL(Url.URL_OHOS);
                              }
                              Navigator.of(context).pop();
                            })),
                    Container(
                        alignment: Alignment.centerRight,
                        child: TransBgTextButton(
                            color: Colors.grey,
                            child: Text(S.of(context).love_but_no_money,
                                style: const TextStyle(color: Colors.grey)),
                            onPressed: () async {
                              UmengCommonSdk.onEvent(
                                  "import_dialog", {"action": "noMoney"});
                              Navigator.of(context).pop();
                            })),
                  ])),
              overrideActions: const [],
            ));
  }

  Future<bool> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> changeWeek(
      BuildContext context, String semesterStartMonday) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MDialog(S.of(context).fix_week_dialog_title,
          Text(S.of(context).fix_week_dialog_content), widgetCancelAction: () {
        Navigator.of(context).pop();
      }, widgetOKAction: () async {
        await WeekUtil.initWeek(semesterStartMonday, 1);
        ScopedModel.of<MainStateModel>(context).refresh();
        Toast.showToast(S.of(context).fix_week_toast_success, context);
        Navigator.of(context).pop(true);
      }),
    );
    return true;
  }

  showClassDialog(BuildContext context, Course course, bool isActive) {
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          UmengCommonSdk.onEvent("class_click", {"type": "single"});
          return CourseDetailDialog(course, isActive, () {
            Navigator.of(context).pop();
          });
        });
  }

  showMultiClassDialog(BuildContext context, int i, int nowWeek) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          // 设计失误，其实应该把是不是当前周传进来的
          UmengCommonSdk.onEvent("class_click", {"type": "multi"});
          return Swiper(
            itemBuilder: (BuildContext context, int index) {
              return CourseDetailDialog(
                  multiCourses[i][index],
                  isThisWeek(multiCourses[i][index], nowWeek),
                  () => Navigator.of(context).pop());
            },
            itemCount: multiCourses[i].length,
            pagination: SwiperPagination(
                margin: const EdgeInsets.only(bottom: 100),
                builder: DotSwiperPaginationBuilder(
                    color: Colors.grey,
                    activeColor: Theme.of(context).primaryColor)),
            viewportFraction: 1,
            scale: 1,
          );
        });
  }

  showFreeClassDialog(BuildContext context, int nowWeek) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          UmengCommonSdk.onEvent("class_click", {"type": "free"});
          return Swiper(
            itemBuilder: (BuildContext context, int index) {
              return CourseDetailDialog(
                  freeCourses[index],
                  isThisWeek(freeCourses[index], nowWeek),
                  () => Navigator.of(context).pop());
            },
            itemCount: freeCourses.length,
            pagination: SwiperPagination(
                margin: const EdgeInsets.only(bottom: 100),
                builder: DotSwiperPaginationBuilder(
                    color: Colors.grey,
                    activeColor: Theme.of(context).primaryColor)),
            loop: freeCourses.length > 1,
            viewportFraction: 1,
            scale: 1,
          );
        });
  }

  showDeleteDialog(BuildContext context, Course course) {
    UmengCommonSdk.onEvent("class_delete", {"action": "show"});
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return CourseDeleteDialog(course);
      },
    ).then((val) => ScopedModel.of<MainStateModel>(context).refresh());
  }

  showHideFreeCourseDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const HideFreeCourseDialog();
      },
    ).then((val) => ScopedModel.of<MainStateModel>(context).refresh());
  }

  bool isThisWeek(Course course, int nowWeek) {
    List weeks = json.decode(course.weeks!);
    return weeks.contains(nowWeek);
  }

//TEST: 测试用函数
//  Future insertMockData() async {
//    await courseProvider.insert(new Course(
//        0, "微积分", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
//        color: '#8AD297', classroom: 'QAQ'));
//    await courseProvider.insert(new Course(
//        0, "线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
//        color: '#F9A883', classroom: '仙林校区不知道哪个教室'));
//    await courseProvider.insert(new Course(
//        1, "并不是线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
//        color: '#F9A883', classroom: 'QAQ'));
//  }
}
