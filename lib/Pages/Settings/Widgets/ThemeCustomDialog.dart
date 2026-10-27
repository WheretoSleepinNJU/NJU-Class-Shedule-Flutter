import 'PlatformSettings.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

import '../../../Utils/ColorUtil.dart';
import '../../../Utils/States/MainState.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';

const String defaultColor = '#0095F9';

class ThemeCustomDialog extends StatefulWidget {
  const ThemeCustomDialog({Key? key}) : super(key: key);

  @override
  _ThemeCustomDialogState createState() => _ThemeCustomDialogState();
}

class _ThemeCustomDialogState extends State<ThemeCustomDialog> {
  final TextEditingController _controller = TextEditingController();
  String _hex = defaultColor; // always "#RRGGBB"

  @override
  void initState() {
    super.initState();
    // 默认留空也能预览 defaultColor
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final raw = _controller.text.trim();
    setState(() {
      _hex = raw.isEmpty ? defaultColor : '#$raw';
    });
  }

  bool get _isValid6 {
    final raw = _controller.text.trim();
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(raw);
  }

  Color get _seedColor {
    try {
      return HexColor(_hex);
    } catch (_) {
      return HexColor(defaultColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ScopedModel.of<MainStateModel>(
      context,
      rebuildOnChange: true,
    );

    final bool useM3Light = (model.material3ColorForLight == true);
    final bool useM3Dark = (model.material3ColorForDark == true);

    final seed = _seedColor;

    // 预览：如果 M3 开关开 -> 用 fromSeed primary；关 -> 直接用 seed（更鲜艳）
    final lightPrimary = useM3Light
        ? ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.light,
          ).primary
        : seed;
    final darkPrimary = useM3Dark
        ? ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.dark,
          ).primary
        : seed;

    return SettingsActionDialog(
      '自定义主题颜色',
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '输入颜色代码，即可预览浅色与深色的强调色效果',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          _HexInputRow(
            controller: _controller,
            onClear: () {
              _controller.clear();
              FocusScope.of(context).requestFocus(FocusNode());
            },
            previewColor: seed,
            isValid: _isValid6 || _controller.text.isEmpty,
          ),

          const SizedBox(height: 14),

          // 现代化预览卡：Seed / Light / Dark
          _PreviewCard(
            seed: seed,
            light: lightPrimary,
            dark: darkPrimary,
            lightOutlined: !useM3Light,
            darkOutlined: !useM3Dark,
          ),
        ],
      ),
      widgetCancelAction: () {
        UmengCommonSdk.onEvent("theme_change", {
          "type": "theme_change",
          "action": "cancel",
        });
        Navigator.of(context).pop('');
      },
      widgetOKAction: () {
        if (_controller.text.trim().isNotEmpty && !_isValid6) return;
        final finalHex = _controller.text.trim().isEmpty
            ? defaultColor
            : '#${_controller.text.trim().toUpperCase()}';

        UmengCommonSdk.onEvent("theme_change", {
          "type": "theme_change",
          "color": finalHex,
        });
        ScopedModel.of<MainStateModel>(context).changeCustomTheme(finalHex);
        ScopedModel.of<MainStateModel>(
          context,
        ).changeTheme(themeDataList.length);
        Navigator.of(context).pop(_controller.text);
      },
    );
  }
}

class _HexInputRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final Color previewColor;
  final bool isValid;

  const _HexInputRow({
    required this.controller,
    required this.onClear,
    required this.previewColor,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsTextField(
          controller: controller,
          autofocus: true,
          singleLine: true,
          label: '#RRGGBB',
          leadingIcon: Icon(Icons.palette, color: previewColor),
          trailingIcon: SettingsIconAction(
            onPressed: onClear,
            child: const Icon(Icons.close_rounded),
          ),
        ),
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('请输入 6 位十六进制', style: TextStyle(color: scheme.error)),
          ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Color seed;
  final Color light;
  final Color dark;
  final bool lightOutlined;
  final bool darkOutlined;

  const _PreviewCard({
    required this.seed,
    required this.light,
    required this.dark,
    required this.lightOutlined,
    required this.darkOutlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwatchBlock(
              title: '种子色',
              color: seed,
              outlined: false,
              icon: Icons.palette_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SwatchBlock(
              title: '浅色预览',
              color: light,
              outlined: lightOutlined,
              icon: Icons.wb_sunny_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SwatchBlock(
              title: '深色预览',
              color: dark,
              outlined: darkOutlined,
              icon: Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwatchBlock extends StatelessWidget {
  final String title;
  final Color color;
  final bool outlined;
  final IconData icon;

  const _SwatchBlock({
    required this.title,
    required this.color,
    required this.outlined,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outline = scheme.outlineVariant;

    final on = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 大色块：用圆角矩形，更“现代”
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: outlined ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.circle,
                size: 12,
                color: outlined ? color : on.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
