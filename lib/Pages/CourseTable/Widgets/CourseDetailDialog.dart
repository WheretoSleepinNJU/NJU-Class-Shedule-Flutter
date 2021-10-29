import 'dart:convert';
import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../Components/Dialog.dart';

class CourseDetailDialog extends StatelessWidget {
  final onPressed;
  final Course course;
  final bool isActive;

  CourseDetailDialog(this.course, this.isActive, this.onPressed);

  String _getWeekListString(BuildContext context) {
    bool flag = true;
    List weekList = json.decode(course.weeks!);
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
    if (flag) if (weekList[0] % 2 == 0)
      return base + " " + S.of(context).double_week;
    else
      return base + " " + S.of(context).single_week;
    else
      return course.weeks!;
  }

  @override
  Widget build(BuildContext context) {
    String weekString = Constant.WEEK_WITH_BIAS[course.weekTime!] +
        ' ' +
        S.of(context).class_duration(course.startTime.toString(),
            (course.startTime! + course.timeCount!).toString());
    if (course.startTime == 0 && course.timeCount == 0)
      weekString = S.of(context).free_time;

    String weekListString = _getWeekListString(context);

    return mDialog(
      (isActive ? '' : S.of(context).not_this_week) + course.name!,
      new SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: [
            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(
                child: Text(course.classroom == ""
                    ? S.of(context).unknown_place
                    : course.classroom ?? S.of(context).unknown_place)),
          ]),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(children: [
            Icon(Icons.account_circle, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: Text(course.teacher ?? '')),
          ]),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(children: [
            Icon(Icons.access_time, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: Text(weekString)),
          ]),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.event, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: Text(weekListString)),
          ]),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(children: [
            Icon(Icons.settings_suggest, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(
                child: Text(course.importType == Constant.ADD_BY_IMPORT
                    ? S.of(context).import_auto
                    : S.of(context).import_manually)),
          ]),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.description, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(
              child: SelectableLinkify(
                onOpen: (link) async {
                  String url = link.url.replaceAll(RegExp('[^\x00-\xff]'), '');
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $link';
                  }
                },
                text: course.info == ""
                    ? S.of(context).unknown_info
                    : course.info ?? S.of(context).unknown_info,
                style: TextStyle(fontSize: 16),
                linkStyle: TextStyle(color: Theme.of(context).primaryColor),
                options: LinkifyOptions(humanize: false),
              ),
            ),
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
