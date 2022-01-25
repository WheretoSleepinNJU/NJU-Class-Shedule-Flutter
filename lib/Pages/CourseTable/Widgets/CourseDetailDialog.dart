import 'dart:convert';
import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../Components/Dialog.dart';
import '../../../Components/Toast.dart';

class CourseDetailDialog extends StatelessWidget {
  final onPressed;
  final Course course;
  final bool isActive;

  const CourseDetailDialog(this.course, this.isActive, this.onPressed,
      {Key? key})
      : super(key: key);

  String _getWeekListString(BuildContext context) {
    bool flag = true;
    List weekList = json.decode(course.weeks!);
    if (weekList.length == 1) return S.of(context).week(weekList[0]);
    String base = S.of(context).week_duration(
        weekList[0].toString(), weekList[weekList.length - 1].toString());
    for (int i = 1; i < weekList.length; i++) {
      if (weekList[i] - weekList[0] != i) {
        flag = false;
        break;
      }
    }
    if (flag) return base;
    flag = true;
    for (int i = 1; i < weekList.length; i++) {
      if (weekList[i] - weekList[0] != 2 * i) {
        flag = false;
        break;
      }
    }
    if (flag) {
      if (weekList[0] % 2 == 0) {
        return base + " " + S.of(context).double_week;
      } else {
        return base + " " + S.of(context).single_week;
      }
    } else {
      return course.weeks!;
    }
  }

  Widget linkifyText(context, String text) {
    return SelectableLinkify(
      onOpen: (link) async {
        String url = link.url.replaceAll(RegExp('[^\x00-\xff]'), '');
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          Toast.showToast(S.of(context).network_error_toast, context);
        }
      },
      text: text,
      style: const TextStyle(fontSize: 16),
      linkStyle: TextStyle(color: Theme.of(context).primaryColor),
      options: const LinkifyOptions(humanize: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    String weekString = Constant.WEEK_WITH_BIAS[course.weekTime!] +
        ' ' +
        S.of(context).class_duration(course.startTime.toString(),
            (course.startTime! + course.timeCount!).toString());
    if (course.startTime == 0 && course.timeCount == 0) {
      weekString = S.of(context).free_time;
    }

    String weekListString = _getWeekListString(context);

    String importTypeStr = '';
    switch (course.importType) {
      case Constant.ADD_BY_IMPORT:
        importTypeStr = S.of(context).import_auto;
        break;
      case Constant.ADD_MANUALLY:
        importTypeStr = S.of(context).import_manually;
        break;
      case Constant.ADD_BY_LECTURE:
        importTypeStr = S.of(context).import_from_lecture;
        break;
    }

    return MDialog(
      (isActive ? '' : S.of(context).not_this_week) + course.name!,
      SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: [
            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
            const Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(
                child: linkifyText(
                    context,
                    course.classroom == ""
                        ? S.of(context).unknown_place
                        : course.classroom ?? S.of(context).unknown_place)),
          ]),
          const Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(children: [
            Icon(Icons.account_circle, color: Theme.of(context).primaryColor),
            const Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: linkifyText(context, course.teacher ?? '')),
          ]),
          const Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(children: [
            Icon(Icons.access_time, color: Theme.of(context).primaryColor),
            const Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: linkifyText(context, weekString)),
          ]),
          const Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.event, color: Theme.of(context).primaryColor),
            const Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: linkifyText(context, weekListString)),
          ]),
          const Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(children: [
            Icon(Icons.settings_suggest, color: Theme.of(context).primaryColor),
            const Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: linkifyText(context, importTypeStr)),
          ]),
          const Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.description, color: Theme.of(context).primaryColor),
            const Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(
                child: linkifyText(
                    context,
                    course.info == ""
                        ? S.of(context).unknown_info
                        : course.info ?? S.of(context).unknown_info)),
          ]),
        ],
      )),
      <Widget>[
        FlatButton(
          child: Text(S.of(context).ok),
          textColor: Theme.of(context).primaryColor,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
