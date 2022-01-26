import '../../../generated/l10n.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';
import '../../../Components/Dialog.dart';

class AddDialog extends StatefulWidget {
  const AddDialog({Key? key}) : super(key: key);

  @override
  _AddDialogState createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MDialog(
      S.of(context).add_class_table_dialog_title,
      Row(
        children: <Widget>[
          Expanded(child: TextField(autofocus: true, controller: _controller))
        ],
      ),
      widgetCancelAction: () {
        UmengCommonSdk.onEvent(
            "schedule_manage", {"type": "add", "action": "cancel"});
        Navigator.of(context).pop('');
      },
      widgetOKAction: () {
        UmengCommonSdk.onEvent(
            "schedule_manage", {"type": "add", "action": "accept"});
        Navigator.of(context).pop(_controller.text);
      },
    );
  }
}
