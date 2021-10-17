import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Models/CourseModel.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Components/Dialog.dart';

class HideFreeCourseDialog extends StatelessWidget {

  HideFreeCourseDialog();

  @override
  Widget build(BuildContext context) {
    return mDialog(
      S.of(context).hide_free_class_dialog_title,
      Text(S.of(context).hide_free_class_dialog_content),
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
            ScopedModel.of<MainStateModel>(context).setShowFreeClass(false);
            // ScopedModel.of<MainStateModel>(context).refresh();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
