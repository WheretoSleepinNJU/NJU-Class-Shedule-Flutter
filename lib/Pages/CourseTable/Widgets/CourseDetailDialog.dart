import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../Components/Dialog.dart';

class CourseDetailDialog extends StatelessWidget {
  final onPressed;
  final Course course;
  final bool isActive;

  CourseDetailDialog(this.course, this.isActive, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return mDialog(
      (isActive ? '' : S.of(context).not_this_week) + course.name!,
      new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: [
            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(
                child: Text(course.classroom ?? S.of(context).unknown_place)),
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
            Flexible(
                child: Text(Constant.WEEK_WITH_BIAS[course.weekTime!] +
                    course.startTime.toString() +
                    '-' +
                    (course.startTime! + course.timeCount!).toString() +
                    '节')),
          ]),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.event, color: Theme.of(context).primaryColor),
            Padding(padding: EdgeInsets.only(left: 5)),
            Flexible(child: Text(course.weeks!)),
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
            Flexible(child: Text(course.info ?? S.of(context).unknown_info)),
          ]),
        ],
      ),
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
