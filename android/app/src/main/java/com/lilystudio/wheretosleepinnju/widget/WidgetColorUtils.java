package com.lilystudio.wheretosleepinnju.widget;

import android.graphics.Color;

/**
 * 课程配色工具。
 *
 * 对标 iOS 端 {@code ios/ScheduleWidget/Extensions/ColorExtensions.swift}：
 * 支持 3 / 6 / 8 位 hex 解析，并提供同样的"提升饱和度"处理，
 * 让课程色块在桌面背景上更醒目。
 */
public final class WidgetColorUtils {

    /** 与 iOS 端一致的兜底色（蓝色）。 */
    private static final int FALLBACK_COLOR = 0xFF2196F3;

    /** 课程卡片背景的透明度，对标 iOS 的 opacity(0.12)。 */
    private static final int CARD_BACKGROUND_ALPHA = (int) (0.12f * 255);

    /** 紧凑卡片背景透明度，对标 iOS 的 opacity(0.08)。 */
    private static final int COMPACT_BACKGROUND_ALPHA = (int) (0.08f * 255);

    private WidgetColorUtils() {
    }

    /**
     * 解析 hex 颜色串，兼容 "#RRGGBB" / "0xRRGGBB" / "RGB" / "AARRGGBB" 等写法。
     * 解析失败时返回兜底色，绝不抛异常——小组件里崩一次就会长期显示"无法加载"。
     */
    public static int parseColor(String hex) {
        if (hex == null) {
            return FALLBACK_COLOR;
        }

        String clean = hex.trim();
        if (clean.startsWith("0x") || clean.startsWith("0X")) {
            clean = clean.substring(2);
        } else if (clean.startsWith("#")) {
            clean = clean.substring(1);
        }

        // 去掉非十六进制字符
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < clean.length(); i++) {
            char c = clean.charAt(i);
            boolean isHexChar = (c >= '0' && c <= '9')
                    || (c >= 'a' && c <= 'f')
                    || (c >= 'A' && c <= 'F');
            if (isHexChar) {
                builder.append(c);
            }
        }
        clean = builder.toString();

        try {
            switch (clean.length()) {
                case 3: {
                    // RGB (12-bit)，每位扩展为两位
                    int value = (int) Long.parseLong(clean, 16);
                    int r = ((value >> 8) & 0xF) * 17;
                    int g = ((value >> 4) & 0xF) * 17;
                    int b = (value & 0xF) * 17;
                    return Color.argb(255, r, g, b);
                }
                case 6: {
                    int value = (int) Long.parseLong(clean, 16);
                    return Color.argb(255,
                            (value >> 16) & 0xFF,
                            (value >> 8) & 0xFF,
                            value & 0xFF);
                }
                case 8: {
                    long value = Long.parseLong(clean, 16);
                    return Color.argb(
                            (int) ((value >> 24) & 0xFF),
                            (int) ((value >> 16) & 0xFF),
                            (int) ((value >> 8) & 0xFF),
                            (int) (value & 0xFF));
                }
                default:
                    return FALLBACK_COLOR;
            }
        } catch (NumberFormatException e) {
            return FALLBACK_COLOR;
        }
    }

    /**
     * 提升饱和度供小组件显示，对标 iOS 端 {@code enhancedForWidget()}：
     * 饱和度 ×1.4（上限 0.9），亮度不低于 0.5。
     */
    public static int enhanceForWidget(int color) {
        float[] hsv = new float[3];
        Color.colorToHSV(color, hsv);
        hsv[1] = Math.min(hsv[1] * 1.4f, 0.9f);
        hsv[2] = Math.max(hsv[2], 0.5f);
        return Color.HSVToColor(Color.alpha(color), hsv);
    }

    /** 课程色：解析 + 增强，一步到位。 */
    public static int courseColor(WidgetCourse course) {
        if (course == null || course.color == null) {
            return enhanceForWidget(FALLBACK_COLOR);
        }
        return enhanceForWidget(parseColor(course.color));
    }

    /** 课程卡片背景色（12% 透明度）。 */
    public static int cardBackgroundColor(int courseColor) {
        return withAlpha(courseColor, CARD_BACKGROUND_ALPHA);
    }

    /** 紧凑课程卡片背景色（8% 透明度）。 */
    public static int compactBackgroundColor(int courseColor) {
        return withAlpha(courseColor, COMPACT_BACKGROUND_ALPHA);
    }

    public static int withAlpha(int color, int alpha) {
        return Color.argb(
                Math.max(0, Math.min(255, alpha)),
                Color.red(color),
                Color.green(color),
                Color.blue(color));
    }

    public static int withAlphaFraction(int color, float fraction) {
        return withAlpha(color, (int) (fraction * 255));
    }
}
