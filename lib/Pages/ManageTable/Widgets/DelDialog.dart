import '../../../generated/l10n.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';
import '../../../Components/Dialog.dart';

class DelDialog extends StatefulWidget {
  const DelDialog({Key? key}) : super(key: key);

  @override
  _DelDialogState createState() => _DelDialogState();
}

class _DelDialogState extends State<DelDialog> {

  @override
  Widget build(BuildContext context) {
    return MDialog(
      S.of(context).del_class_table_dialog_title,
      Text(S.of(context).del_class_table_dialog_content),
      <Widget>[
        FlatButton(
          textColor: Colors.grey,
          child: Text(S.of(context).cancel),
          onPressed: () {
            UmengCommonSdk.onEvent(
                "schedule_manage", {"type": "del", "action": "cancel"});
            Navigator.of(context).pop('false');
          },
        ),
        FlatButton(
          textColor: Theme.of(context).primaryColor,
          child: Text(S.of(context).ok),
          onPressed: () {
            UmengCommonSdk.onEvent(
                "schedule_manage", {"type": "del", "action": "accept"});
            Navigator.of(context).pop('true');
          },
        ),
      ],
    );
  }
}
