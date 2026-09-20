import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:wheretosleepinnju/Utils/ColorUtil.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Resources/Themes.dart';

/// 预设强调色的点选行。最后一个"自定义"圆点不再弹窗——点一下就是
/// 切到"自定义"这个槽位，具体怎么选颜色交给页面里紧跟着的色轮面板
/// （见 [AccentColorSettingsView]），不需要再多一层弹窗。
///
/// [onColorPreview]：每次点某个圆点（预设或自定义）时，把这个颜色的
/// hex 传出去，供外面的色轮面板同步"锁定"到这个颜色——预设颜色始终
/// 从 [AppThemes.presetHexColors] 读，不写死具体值，以后改预设列表
/// 这里不用跟着改。
class ThemeChanger extends StatelessWidget {
  final ValueChanged<String>? onColorPreview;

  const ThemeChanger({Key? key, this.onColorPreview}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = MainStateModel.of(context);
    final selectedIndex = model.themeIndex ?? 0;
    final customIndex = themeDataList.length;
    final existingCustomHex = model.themeCustomColor as String?;
    final hasCustomColor = existingCustomHex != null && existingCustomHex.isNotEmpty;
    final customHex = hasCustomColor ? existingCustomHex : defaultCustomAccentColor;

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
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 6, right: 6, bottom: 4),
            child: Row(
              children: [
                ...List<Widget>.generate(AppThemes.presetHexColors.length,
                    (int i) {
                  final seedHex = AppThemes.presetHexColors[i];

                  return _ThemeDot(
                    seed: HexColor(seedHex),
                    isSelected: i == selectedIndex,
                    onTap: () {
                      UmengCommonSdk.onEvent("theme_change", {"type": i});
                      MainStateModel.of(context).changeTheme(i);
                      onColorPreview?.call(seedHex);
                    },
                  );
                }),
                _CustomDot(
                  color: HexColor(customHex),
                  isSelected: selectedIndex == customIndex,
                  onTap: () {
                    UmengCommonSdk.onEvent(
                        "theme_change", {"type": "custom_select"});
                    // 只有已经真正设置过自定义色，点这个圆点才切到"自定义"
                    // 这个主题槽位；还没设置过的话，只做预览联动（把色轮
                    // 滚到默认色），不能把 themeIndex 切到一个还没有对应
                    // 颜色数据的槽位——否则 main.dart 里按下标取
                    // themeDataList[themeIndex] 会越界崩溃。
                    if (hasCustomColor) {
                      MainStateModel.of(context).changeTheme(customIndex);
                    }
                    onColorPreview?.call(customHex);
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
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeDot({
    required this.seed,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double big = 36;

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
        child: Container(
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
                    size: 18,
                    color: onSeed,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// "自定义"这个槽位的圆点：还没设置过自定义色时显示默认色 + 一个铅笔
/// 图标提示"这是自定义位"；选中后跟其它预设点一样描边高亮。
class _CustomDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double big = 36;

    final scheme = Theme.of(context).colorScheme;
    final onColor = ThemeData.estimateBrightnessForColor(color) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: big,
          height: big,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2.0 : 1.2,
            ),
          ),
          child: Icon(Icons.edit, size: 16, color: onColor),
        ),
      ),
    );
  }
}
