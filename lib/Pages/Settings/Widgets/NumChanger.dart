import 'MiuixSettings.dart';
import 'package:flutter/material.dart';

class NumberChangerWidget extends StatefulWidget {
  //高度
  final double height;

  //输入框的宽度 总体宽度为自适应
  final double width;

  //按钮的宽度
  final double iconWidth;

  //默认输入框显示的数量
  final String numText;

  //点击加号回调 数量
  final ValueChanged? addValueChanged;

  //点击减号回调 数量
  final ValueChanged? removeValueChanged;

  //点击减号任意一个回调 数量
  final ValueChanged? updateValueChanged;

  const NumberChangerWidget({
    this.height = 30,
    this.width = 40,
    this.iconWidth = 40,
    this.numText = '0',
    this.addValueChanged,
    this.removeValueChanged,
    this.updateValueChanged,
    Key? key,
  }) : super(key: key);

  @override
  _NumberChangerWidgetState createState() => _NumberChangerWidgetState();
}

class _NumberChangerWidgetState extends State<NumberChangerWidget> {
  @override
  Widget build(BuildContext context) => MiuixButton(
    onPressed: () async {
      var selected = (int.tryParse(widget.numText) ?? 0).clamp(0, 500);
      final result = await showDialog<int>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => SettingsActionDialog(
            '课程高度',
            MiuixNumberPicker(
              value: selected,
              min: 0,
              max: 500,
              onValueChanged: (value) => update(() => selected = value),
            ),
            widgetCancelAction: () => Navigator.pop(dialogContext),
            widgetOKAction: () => Navigator.pop(dialogContext, selected),
          ),
        ),
      );
      if (result != null) widget.updateValueChanged?.call(result);
    },
    child: Text(widget.numText),
  );
}
