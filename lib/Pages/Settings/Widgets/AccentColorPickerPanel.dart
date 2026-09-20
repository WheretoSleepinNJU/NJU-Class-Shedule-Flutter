import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import '../../../Resources/Themes.dart';
import '../../../Utils/ColorUtil.dart';
import '../../../Utils/States/MainState.dart';

/// 自定义强调色的取色面板：直接内嵌在"强调色设置"页里，不再需要
/// 额外弹一个对话框——打开设置页、往下滑一点就是色轮，选完点"应用"
/// 才真正切到自定义强调色（避免拖动色轮的过程中来回触发全局换色）。
/// 选出来的颜色直接就是 App 里用到的颜色，没有中间算法二次调色。
class AccentColorPickerPanel extends StatefulWidget {
  final String initialHex;

  const AccentColorPickerPanel({Key? key, required this.initialHex})
      : super(key: key);

  @override
  State<AccentColorPickerPanel> createState() =>
      _AccentColorPickerPanelState();
}

class _AccentColorPickerPanelState extends State<AccentColorPickerPanel> {
  late Color _current;

  @override
  void initState() {
    super.initState();
    _current = HexColor(widget.initialHex);
  }

  String get _currentHex =>
      '#${_current.value.toRadixString(16).substring(2).toUpperCase()}';

  void _apply() {
    final model = MainStateModel.of(context);
    UmengCommonSdk.onEvent(
        "theme_change", {"type": "theme_change", "color": _currentHex});
    model.changeCustomTheme(_currentHex);
    model.changeTheme(themeDataList.length);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onCurrent =
        ThemeData.estimateBrightnessForColor(_current) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自定义强调色',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 8),
          ColorPicker(
            pickerColor: _current,
            onColorChanged: (c) => setState(() => _current = c),
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsv,
            pickerAreaHeightPercent: 0.6,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _current,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Center(
              child: Text(_currentHex,
                  style: TextStyle(color: onCurrent, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // 按钮背景直接用色轮当前选中的颜色，而不是走全局主题的
              // 默认按钮样式——否则按钮长什么样跟点下去会变成什么样
              // 对不上（按钮会一直显示"上一次已应用"的旧强调色）。
              style: ElevatedButton.styleFrom(
                backgroundColor: _current,
                foregroundColor: onCurrent,
              ),
              onPressed: _apply,
              child: const Text('应用为强调色'),
            ),
          ),
        ],
      ),
    );
  }
}
