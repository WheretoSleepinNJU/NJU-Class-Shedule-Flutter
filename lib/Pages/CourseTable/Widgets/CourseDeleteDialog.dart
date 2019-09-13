import '../../../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Models/CourseModel.dart';
import '../../../Utils/States/MainState.dart';

class CourseDeleteDialog extends StatelessWidget{

  final Course course;
  CourseDeleteDialog(this.course);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).delete_class_dialog_title),
      content: Text(S.of(context).delete_class_dialog_content(course.name)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      actions: <Widget>[
        FlatButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text(S.of(context).ok),
          onPressed: () async {
            CourseProvider courseProvider = new CourseProvider();
            await courseProvider.delete(course.id);
            ScopedModel.of<MainStateModel>(context).refresh();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}