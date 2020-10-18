import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Models/CourseModel.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Components/Dialog.dart';

class CourseDeleteDialog extends StatelessWidget {
  final Course course;

  CourseDeleteDialog(this.course);

  @override
  Widget build(BuildContext context) {
    return mDialog(
      S.of(context).delete_class_dialog_title,
      Text(S.of(context).delete_class_dialog_content(course.name)),
      <Widget>[
        FlatButton(
          textColor: Colors.grey,
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          textColor: Theme.of(context).primaryColor,
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
