import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Models/CourseModel.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Components/Dialog.dart';

class CourseDeleteDialog extends StatelessWidget {
  final Course course;

  const CourseDeleteDialog(this.course, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MDialog(
      S.of(context).delete_class_dialog_title,
      Text(S.of(context).delete_class_dialog_content(course.name!)),
      widgetCancelAction: () {
        UmengCommonSdk.onEvent("class_delete", {"action": "cancel"});
        Navigator.of(context).pop();
      },
      widgetOKAction: () async {
        UmengCommonSdk.onEvent("class_delete", {"action": "accept"});
        CourseProvider courseProvider = CourseProvider();
        await courseProvider.delete(course.id!);
        ScopedModel.of<MainStateModel>(context).refresh();
        Navigator.of(context).pop();
      },
    );
  }
}
