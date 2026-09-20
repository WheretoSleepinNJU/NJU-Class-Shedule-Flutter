import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Resources/Themes.dart';
import '../../Utils/States/MainState.dart';
import 'Widgets/ThemeChanger.dart';
import 'Widgets/AccentColorPickerPanel.dart';

/// 强调色设置页：从"更多设置"里搬出来的"选择强调色"（含自定义），
/// 跟"课程颜色设置"（那个是给课表里每门课配色）区分开。
class AccentColorSettingsView extends StatefulWidget {
  const AccentColorSettingsView({Key? key}) : super(key: key);

  @override
  State<AccentColorSettingsView> createState() =>
      _AccentColorSettingsViewState();
}

class _AccentColorSettingsViewState extends State<AccentColorSettingsView> {
  String? _previewHex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_previewHex != null) return;
    final model =
        ScopedModel.of<MainStateModel>(context, rebuildOnChange: false);
    final existing = model.themeCustomColor as String?;
    _previewHex = (existing != null && existing.isNotEmpty)
        ? existing
        : defaultCustomAccentColor;
  }

  @override
  Widget build(BuildContext context) {
    final previewHex = _previewHex ?? defaultCustomAccentColor;
    return Scaffold(
      appBar: AppBar(title: const Text('强调色设置')),
      body: SafeArea(
        child: ListView(
          children: [
            ThemeChanger(
              onColorPreview: (hex) => setState(() => _previewHex = hex),
            ),
            const Divider(height: 24),
            AccentColorPickerPanel(
              // 用当前预览颜色当 key：点了预设圆点之后强制这个面板重新
              // 用新颜色初始化色轮，否则色轮内部状态不会跟着外部变化走。
              key: ValueKey(previewHex),
              initialHex: previewHex,
            ),
          ],
        ),
      ),
    );
  }
}
