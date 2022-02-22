import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import './TransBgTextButton.dart';
// import 'package:auto_size_text/auto_size_text.dart';

class MDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? overrideActions;
  final Widget? widgetOK;
  final VoidCallback? widgetOKAction;
  final Widget? widgetCancel;
  final VoidCallback? widgetCancelAction;

  const MDialog(this.title, this.content,
      // this.actions,
      {this.overrideActions,
      this.widgetOK,
      this.widgetOKAction,
      this.widgetCancel,
      this.widgetCancelAction,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
        title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
                (title.length <= 15) ? title : '${title.substring(0, 15)}...')),
        content: content,
        actions: overrideActions ??
            [
              widgetCancelAction == null
                  ? Container()
                  : TransBgTextButton(
                      // color: Theme.of(context).primaryColor,
                      color: Colors.grey,
                      onPressed: widgetCancelAction,
                      child: widgetCancel ?? Text(S.of(context).cancel)),
              TransBgTextButton(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                  onPressed: widgetOKAction,
                  child: widgetOK ?? Text(S.of(context).ok))
            ]);
  }
}
