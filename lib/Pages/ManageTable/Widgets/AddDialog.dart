import '../../../generated/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';
import '../../../Resources/Config.dart';

class AddDialog extends StatefulWidget {
  AddDialog() : super();

  @override
  _AddDialogState createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  TextEditingController _controller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).add_class_table_dialog_title),
      content: new Row(
        children: <Widget>[
          new Expanded(
              child: new TextField(
                autofocus: true,
                controller: _controller
              ))
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop('');
          },
        ),
        FlatButton(
          child: Text(S.of(context).ok),
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
        ),
      ],
    );
  }
}