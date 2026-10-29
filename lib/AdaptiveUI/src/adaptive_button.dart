import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'adaptive_ui_controller.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

enum AdaptiveButtonVariant { text, filled, outlined, elevated }

/// Pages supply content and callbacks; this boundary selects the library and
/// retains the complete original control for advanced interaction contracts.
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.loading = false,
  }) : variant = AdaptiveButtonVariant.text,
       icon = null;
  const AdaptiveButton.filled({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.loading = false,
  }) : variant = AdaptiveButtonVariant.filled,
       icon = null;
  const AdaptiveButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.loading = false,
  }) : variant = AdaptiveButtonVariant.outlined,
       icon = null;
  const AdaptiveButton.elevated({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.loading = false,
  }) : variant = AdaptiveButtonVariant.elevated,
       icon = null;
  const AdaptiveButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.variant = AdaptiveButtonVariant.filled,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.loading = false,
  }) : child = label;

  final VoidCallback? onPressed, onLongPress;
  final ValueChanged<bool>? onHover, onFocusChange;
  final FocusNode? focusNode;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final AdaptiveButtonVariant variant;
  final bool autofocus, loading;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final contents = icon == null && !loading
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (icon != null)
                icon!,
              const SizedBox(width: 8),
              Flexible(child: child),
            ],
          );
    final original =
        AdaptiveUIScope.maybeOf(context)?.useOriginalComponents ?? true;
    final callback = enabled ? onPressed : null;
    final ButtonStyleButton material = switch (variant) {
      AdaptiveButtonVariant.text => TextButton(
        onPressed: callback,
        onLongPress: loading ? null : onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        style: style,
        child: contents,
      ),
      AdaptiveButtonVariant.filled => FilledButton(
        onPressed: callback,
        onLongPress: loading ? null : onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        style: style,
        child: contents,
      ),
      AdaptiveButtonVariant.outlined => OutlinedButton(
        onPressed: callback,
        onLongPress: loading ? null : onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        style: style,
        child: contents,
      ),
      AdaptiveButtonVariant.elevated => ElevatedButton(
        onPressed: callback,
        onLongPress: loading ? null : onLongPress,
        onHover: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        style: style,
        child: contents,
      ),
    };
    final themeStyle = switch (variant) {
      AdaptiveButtonVariant.text => TextButtonTheme.of(context).style,
      AdaptiveButtonVariant.filled => FilledButtonTheme.of(context).style,
      AdaptiveButtonVariant.outlined => OutlinedButtonTheme.of(context).style,
      AdaptiveButtonVariant.elevated => ElevatedButtonTheme.of(context).style,
    };
    final resolved = themeStyle?.merge(style) ?? style;
    final states = <WidgetState>{if (!enabled) WidgetState.disabled};
    // Legacy Material TextButtonTheme paints every text button blue/white.
    // Adaptive plain buttons use semantic colors; explicit per-button colors
    // (destructive actions, banners) still take precedence.
    final foreground =
        style?.foregroundColor?.resolve(states) ??
        (variant == AdaptiveButtonVariant.text
            ? Theme.of(context).colorScheme.primary
            : resolved?.foregroundColor?.resolve(states));
    final fill =
        style?.backgroundColor?.resolve(states) ??
        (variant == AdaptiveButtonVariant.text
            ? Colors.transparent
            : resolved?.backgroundColor?.resolve(states));
    final textStyle = resolved?.textStyle?.resolve(states);
    if (AdaptiveUIScope.usesMiuix(context) &&
        onLongPress == null &&
        onHover == null &&
        onFocusChange == null &&
        focusNode == null &&
        !autofocus) {
      final primary =
          variant == AdaptiveButtonVariant.filled ||
          variant == AdaptiveButtonVariant.elevated;
      final defaults = miuix.MiuixButtonDefaults.buttonColors(context);
      final colors = miuix.MiuixTheme.of(context).colors;
      final fg = foreground ?? (primary ? colors.onPrimary : colors.primary);
      final bg =
          fill ??
          (variant == AdaptiveButtonVariant.text
              ? Colors.transparent
              : primary
              ? colors.primary
              : defaults.color);
      return miuix.MiuixButton(
        onPressed: callback,
        enabled: enabled,
        minHeight: resolved?.minimumSize?.resolve(states)?.height ?? 48,
        minWidth: (resolved?.minimumSize?.resolve(states)?.width ?? 48).isFinite
            ? (resolved?.minimumSize?.resolve(states)?.width ?? 48)
            : 0,
        insideMargin:
            resolved?.padding?.resolve(states) ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        colors: miuix.MiuixButtonColors(
          color: bg,
          disabledColor: variant == AdaptiveButtonVariant.text
              ? Colors.transparent
              : defaults.disabledColor,
          contentColor: fg,
          disabledContentColor: defaults.disabledContentColor,
        ),
        child: DefaultTextStyle.merge(
          style: (textStyle ?? Theme.of(context).textTheme.labelLarge)
              ?.copyWith(color: enabled ? fg : defaults.disabledContentColor),
          child: IconTheme.merge(
            data: IconThemeData(
              color: enabled ? fg : defaults.disabledContentColor,
            ),
            child: contents,
          ),
        ),
      );
    }
    // Advanced interactions keep their complete Flutter control contract.
    if (!original &&
        platform.PlatformInfo.isIOS &&
        onLongPress == null &&
        onHover == null &&
        onFocusChange == null &&
        focusNode == null &&
        !autofocus) {
      final buttonStyle = switch (variant) {
        AdaptiveButtonVariant.text => platform.AdaptiveButtonStyle.plain,
        AdaptiveButtonVariant.outlined => platform.AdaptiveButtonStyle.bordered,
        _ => platform.AdaptiveButtonStyle.filled,
      };
      final minimum = resolved?.minimumSize?.resolve(states);
      final padding =
          resolved?.padding
              ?.resolve(states)
              ?.resolve(Directionality.of(context)) ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      final font = textStyle ?? Theme.of(context).textTheme.labelLarge;
      final height = math.max(
        minimum?.height ?? 48,
        MediaQuery.textScalerOf(context).scale(font?.fontSize ?? 14) *
                (font?.height ?? 1.25) +
            padding.vertical,
      );
      // The upstream child mode supports arbitrary Flutter contents over UIKit.
      return Theme(
        data: Theme.of(context).copyWith(
          textButtonTheme: const TextButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            ),
          ),
        ),
        child: platform.AdaptiveButton.child(
          onPressed: callback,
          enabled: enabled,
          style: buttonStyle,
          color: variant == AdaptiveButtonVariant.text ? foreground : fill,
          padding: padding,
          minSize: Size(minimum?.width ?? 0, height),
          child: DefaultTextStyle.merge(
            style:
                font?.copyWith(color: foreground) ??
                TextStyle(color: foreground),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground),
              child: contents,
            ),
          ),
        ),
      );
    }
    return material;
  }
}

/// Top-bar metadata can still recognize this as an IconButton; page callers do
/// not decide between UIKit, Flutter MIUIX or the original icon button.
class AdaptiveIconButton extends IconButton {
  const AdaptiveIconButton({
    super.key,
    required super.icon,
    required super.onPressed,
    super.tooltip,
    super.color,
    super.iconSize,
    super.style,
    super.padding,
    super.constraints,
    super.alignment,
    super.visualDensity,
    super.splashRadius,
    super.focusNode,
    super.autofocus,
    super.onHover,
  });
  @override
  Widget build(BuildContext context) {
    if (focusNode != null || autofocus || onHover != null) {
      return super.build(context);
    }
    Widget? control;
    if (AdaptiveUIScope.usesMiuix(context)) {
      control = miuix.MiuixIconButton(
        onPressed: onPressed,
        enabled: onPressed != null,
        minWidth: 48,
        minHeight: 48,
        child: IconTheme.merge(
          data: IconThemeData(size: iconSize ?? 24, color: color),
          child: icon,
        ),
      );
    } else if (!(AdaptiveUIScope.maybeOf(context)?.useOriginalComponents ??
            true) &&
        platform.PlatformInfo.isIOS) {
      control = platform.AdaptiveButton.child(
        onPressed: onPressed,
        enabled: onPressed != null,
        minSize: const Size(48, 48),
        style: platform.AdaptiveButtonStyle.plain,
        child: icon,
      );
    }
    if (control == null) return super.build(context);
    return Semantics(
      button: true,
      label: tooltip,
      enabled: onPressed != null,
      child: tooltip == null
          ? control
          : Tooltip(message: tooltip!, child: control),
    );
  }
}
