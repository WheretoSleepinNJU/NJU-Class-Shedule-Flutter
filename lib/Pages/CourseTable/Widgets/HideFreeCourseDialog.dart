import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Components/Dialog.dart';

class HideFreeCourseDialog extends StatelessWidget {
  const HideFreeCourseDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MDialog(
      S.of(context).hide_free_class_dialog_title,
      Text(S.of(context).hide_free_class_dialog_content),
      widgetCancelAction: () {
        Navigator.of(context).pop();
      },
      widgetOKAction: () async {
        ScopedModel.of<MainStateModel>(context).setShowFreeClass(false);
        // ScopedModel.of<MainStateModel>(context).refresh();
        Navigator.of(context).pop();
      },
    );
  }
}
