import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

import '../../../Utils/ColorUtil.dart';
import '../../../Utils/States/MainState.dart';

// import '../../../generated/l10n.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';
import '../../../Components/Dialog.dart';

const String defaultColor = '#0095F9';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ThemeCustomDialog extends StatefulWidget {
  const ThemeCustomDialog({Key? key}) : super(key: key);

  @override
  _ThemeCustomDialogState createState() => _ThemeCustomDialogState();
}

class _ThemeCustomDialogState extends State<ThemeCustomDialog> {
  final TextEditingController _controller = TextEditingController();
  String color = defaultColor;

  @override
  Widget build(BuildContext context) {
    return MDialog(
      '自定义主题颜色',
      Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('请输入对应十六位颜色代码\n系统将会根据该颜色计算适合主题'),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10)),
        Row(
          children: <Widget>[
            const Text('#'),
            Expanded(
                child: TextField(
              autofocus: true,
              decoration: const InputDecoration.collapsed(
                  // hintText: defaultColor.substring(1)
                  hintText: '十六进制颜色代码'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-fA-F0-9]')),
                LengthLimitingTextInputFormatter(6),
                UpperCaseTextFormatter(),
              ],
              controller: _controller,
              onChanged: (text) {
                setState(() {
                  color = '#' + _controller.text;
                  if (_controller.text == '') {
                    color = defaultColor;
                  }
                });
              },
            )),
            Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(left: 15, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: HexColor(color),
                  shape: BoxShape.circle,
                )),
          ],
        )
      ]),
      widgetCancelAction: () {
        UmengCommonSdk.onEvent(
            "theme_change", {"type": "theme_change", "action": "cancel"});
        Navigator.of(context).pop('');
      },
      widgetOKAction: () {
        String color = '#' + _controller.text;
        if (color == '#') {
          color = defaultColor;
        }
        UmengCommonSdk.onEvent("theme_change",
            {"type": "theme_change", "color": color});
        ScopedModel.of<MainStateModel>(context)
            .changeCustomTheme(color);
        ScopedModel.of<MainStateModel>(context)
            .changeTheme(themeDataList.length);
        // ScopedModel.of<MainStateModel>(context).refresh();
        Navigator.of(context).pop(_controller.text);
      },
    );
  }
}
