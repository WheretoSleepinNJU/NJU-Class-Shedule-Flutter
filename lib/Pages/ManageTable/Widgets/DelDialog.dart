import '../../../generated/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Components/Dialog.dart';

class DelDialog extends StatefulWidget {
  DelDialog() : super();

  @override
  _DelDialogState createState() => _DelDialogState();
}

class _DelDialogState extends State<DelDialog> {

  @override
  Widget build(BuildContext context) {
    return mDialog(
      "确认删除",
      Text("此操作无法恢复，这将删除该课程表下的所有课程。"),
      <Widget>[
        FlatButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop('false');
          },
        ),
        FlatButton(
          child: Text(S.of(context).ok),
          onPressed: () {
            Navigator.of(context).pop('true');
          },
        ),
      ],
    );
  }
}
