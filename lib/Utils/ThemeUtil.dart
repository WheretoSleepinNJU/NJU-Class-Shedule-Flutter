class ThemeRuntimeConfig {
  static bool material3Light = false;
  static bool material3Dark = true;
}

String normalizeThemeColor(String value) {
  final color = value.trim();
  return RegExp(r'^#?[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(color)
      ? color
      : '';
}

int normalizeThemeIndex(int index, int presetCount, String customColor) {
  if (index >= 0 && index < presetCount) return index;
  if (index >= presetCount && normalizeThemeColor(customColor).isNotEmpty) {
    return presetCount;
  }
  return 0;
}

int normalizeThemeModeIndex(int index, int modeCount) =>
    index >= 0 && index < modeCount ? index : 0;
