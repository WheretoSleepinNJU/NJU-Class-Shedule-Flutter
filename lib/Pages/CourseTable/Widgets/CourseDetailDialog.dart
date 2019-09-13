import '../../../generated/i18n.dart';
import 'package:flutter/material.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';

class CourseDetailDialog extends StatelessWidget {
  final onPressed;
  final Course course;

  CourseDetailDialog(this.course, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(course.name),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
//      backgroundColor: Theme.of(context).primaryColor,
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: [
            Icon(Icons.location_on, color: Theme.of(context).primaryColor),
            Flexible(child: Text(course.classroom)),
          ]),
          Row(children: [
            Icon(Icons.account_circle, color: Theme.of(context).primaryColor),
            Flexible(child: Text(course.teacher ?? '')),
          ]),
          Row(children: [
            Icon(Icons.access_time, color: Theme.of(context).primaryColor),
            Flexible(
                child: Text(Constant.WEEK_WITH_BIAS[course.weekTime] +
                    course.startTime.toString() +
                    '-' +
                    (course.startTime + course.timeCount).toString() +
                    '节')),
          ]),
          Row(children: [
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
            Flexible(child: Text(course.weeks)),
          ]),
          Row(children: [
            Icon(Icons.android, color: Theme.of(context).primaryColor),
            Flexible(
                child: Text(course.importType == Constant.ADD_BY_IMPORT
                    ? S.of(context).import_auto
                    : S.of(context).import_manually)),
          ]),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(S.of(context).ok),
          textColor: Theme.of(context).primaryColor,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
