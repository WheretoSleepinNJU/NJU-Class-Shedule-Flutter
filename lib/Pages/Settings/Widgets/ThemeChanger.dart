import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/Utils/ColorUtil.dart';
import 'package:wheretosleepinnju/Utils/ThemeUtil.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Resources/Themes.dart';
import './ThemeCustomDialog.dart';

class ThemeChanger extends StatelessWidget {
  const ThemeChanger({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = MainStateModel.of(context);
    final selectedIndex = model.themeIndex ?? 0;

    final bool useM3Light = ThemeRuntimeConfig.material3Light;
    final bool useM3Dark = ThemeRuntimeConfig.material3Dark;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '选择强调色',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 6, right: 6, bottom: 4),
            child: Row(
              children: [
                ...List<Widget>.generate(themeDataList.length, (int i) {
                  final seedHex = AppThemes.presetHexColors[i];
                  final seedColor = HexColor(seedHex);

                  final lightPrimary = themeDataList[i].colorScheme.primary;
                  final darkPrimary = darkThemeDataList[i].colorScheme.primary;

                  return _ThemeDot(
                    seed: seedColor,
                    lightPrimary: lightPrimary,
                    darkPrimary: darkPrimary,
                    // 策略：哪个模式关闭 M3，就把对应小圆画成空心
                    lightOutlined: !useM3Light,
                    darkOutlined: !useM3Dark,
                    isSelected: i == selectedIndex,
                    onTap: () {
                      UmengCommonSdk.onEvent("theme_change", {"type": i});
                      MainStateModel.of(context).changeTheme(i);
                    },
                  );
                }),
                _CustomDot(
                  onTap: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => const ThemeCustomDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  final Color seed;
  final Color lightPrimary;
  final Color darkPrimary;

  final bool lightOutlined;
  final bool darkOutlined;

  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeDot({
    required this.seed,
    required this.lightPrimary,
    required this.darkPrimary,
    required this.lightOutlined,
    required this.darkOutlined,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double big = 32;   // 更紧凑
    const double small = 14; // 更紧凑

    final scheme = Theme.of(context).colorScheme;
    final outline = scheme.outlineVariant;

    final onSeed = ThemeData.estimateBrightnessForColor(seed) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 大圆：始终有 border；选中时 border 更粗
            Container(
              width: big,
              height: big,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seed,
                border: Border.all(
                  color: isSelected ? scheme.primary : outline,
                  width: isSelected ? 2.0 : 1.2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: onSeed,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniDot(
                  color: lightPrimary,
                  size: small,
                  outlined: lightOutlined,
                ),
                const SizedBox(width: 6),
                _MiniDot(
                  color: darkPrimary,
                  size: small,
                  outlined: darkOutlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool outlined;

  const _MiniDot({
    required this.color,
    required this.size,
    required this.outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outline = scheme.outlineVariant;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outlined ? Colors.transparent : color,
        border: Border.all(
          color: outlined ? color : outline,
          width: 1.2,
        ),
      ),
    );
  }
}

class _CustomDot extends StatelessWidget {
  final VoidCallback onTap;

  const _CustomDot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const double big = 30;
    const double small = 14;

    final scheme = Theme.of(context).colorScheme;
    final outline = scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: big,
              height: big,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
                border: Border.all(color: outline, width: 1.2),
              ),
              child: Icon(
                Icons.add,
                size: 18,
                color: scheme.onSurface.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 6),
            // 透明占位，保证高度一致
            SizedBox(
              height: small,
              width: small * 2 + 8,
            ),
          ],
        ),
      ),
    );
  }
}