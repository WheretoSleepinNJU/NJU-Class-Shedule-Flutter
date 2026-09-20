import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../Utils/ColorUtil.dart';

/// 单门课的取色弹窗：上半部分是当前配色方案的预设色块（点一下就选中），
/// 下半部分是自由 HSV 色轮，两种方式选出来的都是一个 hex 颜色字符串。
/// 返回值：选中并点击"确定"后，`Navigator.pop` 出去的 hex 字符串
/// （形如 `#RRGGBB`）；取消则 pop `null`，调用方不应该改动原颜色。
Future<String?> showCourseColorPickerSheet({
  required BuildContext context,
  required String initialColor,
  required List<String> presetColors,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ColorPickerSheetBody(
      initialColor: initialColor,
      presetColors: presetColors,
    ),
  );
}

class _ColorPickerSheetBody extends StatefulWidget {
  final String initialColor;
  final List<String> presetColors;

  const _ColorPickerSheetBody({
    required this.initialColor,
    required this.presetColors,
  });

  @override
  State<_ColorPickerSheetBody> createState() => _ColorPickerSheetBodyState();
}

class _ColorPickerSheetBodyState extends State<_ColorPickerSheetBody> {
  late Color _current;

  @override
  void initState() {
    super.initState();
    _current = HexColor(widget.initialColor);
  }

  String get _currentHex =>
      '#${_current.value.toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('预设色块', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.presetColors.map((hex) {
                  final swatchColor = HexColor(hex);
                  final selected =
                      swatchColor.value == _current.value;
                  return GestureDetector(
                    onTap: () => setState(() => _current = swatchColor),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: swatchColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('自由取色', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ColorPicker(
                // 点预设色块之后要让色轮跟着"跳"到那个颜色，但
                // flutter_colorpicker 的 pickerColor 只在首次构建时生效，
                // 不会跟随外部状态变化自动挪动选中点——所以用 key 强制
                // 它在颜色变化时整个重建一次，用新颜色重新初始化。
                key: ValueKey(_currentHex),
                pickerColor: _current,
                onColorChanged: (c) => setState(() => _current = c),
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hsv,
                pickerAreaHeightPercent: 0.7,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_currentHex),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
