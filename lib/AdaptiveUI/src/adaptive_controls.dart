import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'adaptive_ui_controller.dart';
import 'adaptive_layout.dart';
import 'adaptive_typography.dart';
import 'theme/deadliner_color_theme.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;

/// Arbitrary card content stays in Flutter's compositing order so popup routes
/// reliably cover it. Platform-specific press feedback is owned here.
class AdaptivePressable extends StatelessWidget {
  const AdaptivePressable({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(padding: padding, child: child),
    );
    if (AdaptiveUIScope.usesMiuix(context)) {
      return miuix.MiuixPressable(
        onPressed: onPressed,
        enabled: onPressed != null,
        child: content,
      );
    }
    if (platform.PlatformInfo.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 48),
        alignment: AlignmentDirectional.centerStart,
        onPressed: onPressed,
        child: content,
      );
    }
    return InkWell(
      onTap: onPressed,
      borderRadius: borderRadius,
      child: content,
    );
  }
}

class AdaptiveSwitch extends platform.AdaptiveSwitch {
  const AdaptiveSwitch({
    super.key,
    required super.value,
    required super.onChanged,
    super.activeColor,
    super.thumbColor,
  });
  @override
  Widget build(BuildContext context) {
    if (AdaptiveUIScope.usesMiuix(context)) {
      return miuix.MiuixSwitch(
        value: value,
        onChanged: onChanged,
        enabled: onChanged != null,
      );
    }
    if ((AdaptiveUIScope.maybeOf(context)?.useOriginalComponents ?? true) &&
        platform.PlatformInfo.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
        thumbColor: thumbColor,
      );
    }
    return super.build(context);
  }
}

/// A whole-row toggle delegates both presentation and switch rendering here.
class AdaptiveSwitchListTile extends StatelessWidget {
  const AdaptiveSwitchListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.padding,
  });
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: AdaptiveListTile(
      title: title,
      subtitle: subtitle,
      padding: padding,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: AdaptiveSwitch(value: value, onChanged: onChanged),
    ),
  );
}

class AdaptiveRadio<T> extends platform.AdaptiveRadio<T> {
  const AdaptiveRadio({
    super.key,
    required super.value,
    required super.groupValue,
    required super.onChanged,
    super.activeColor,
    super.focusColor,
    super.hoverColor,
    super.toggleable,
  });
  @override
  Widget build(BuildContext context) {
    if (AdaptiveUIScope.usesMiuix(context)) {
      return miuix.MiuixRadioButton(
        selected: value == groupValue,
        enabled: onChanged != null,
        onChanged: onChanged == null
            ? null
            : (_) =>
                  onChanged!(toggleable && value == groupValue ? null : value),
      );
    }
    return super.build(context);
  }
}

class AdaptiveCheckbox extends platform.AdaptiveCheckbox {
  const AdaptiveCheckbox({
    super.key,
    required super.value,
    required super.onChanged,
    super.tristate,
    super.activeColor,
    super.checkColor,
    super.focusColor,
    super.hoverColor,
  });
  @override
  Widget build(BuildContext context) {
    if (AdaptiveUIScope.usesMiuix(context) && !tristate) {
      return miuix.MiuixCheckbox(
        value: value ?? false,
        onChanged: onChanged,
        enabled: onChanged != null,
      );
    }
    return super.build(context);
  }
}

class AdaptiveCard extends platform.AdaptiveCard {
  const AdaptiveCard({
    super.key,
    required super.child,
    super.color,
    super.elevation,
    super.shape,
    super.borderOnForeground,
    super.margin,
    super.clipBehavior,
    super.semanticContainer,
    super.padding,
    super.borderRadius,
    super.borderColor,
    super.borderWidth,
  });
  @override
  Widget build(BuildContext context) {
    if (AdaptiveUIScope.usesMiuix(context)) {
      final colors = miuix.MiuixTheme.of(context).colors;
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: miuix.MiuixCard(
          insideMargin: padding ?? EdgeInsets.zero,
          cornerRadius:
              borderRadius?.topLeft.x ?? AdaptiveLayout.cardRadiusOf(context),
          colors: color == null
              ? null
              : miuix.MiuixCardColors(
                  color: color!,
                  contentColor: colors.onSurface,
                ),
          child: Semantics(
            container: semanticContainer,
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      );
    }
    final radius =
        borderRadius ??
        BorderRadius.circular(AdaptiveLayout.cardRadiusOf(context));
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surfaceContainer,
        elevation: elevation ?? 0,
        shape:
            shape ??
            RoundedRectangleBorder(
              borderRadius: radius,
              side: borderWidth != null && borderWidth! > 0
                  ? BorderSide(
                      color:
                          borderColor ??
                          Theme.of(context).colorScheme.outlineVariant,
                      width: borderWidth!,
                    )
                  : BorderSide.none,
            ),
        clipBehavior: clipBehavior ?? Clip.antiAlias,
        child: Semantics(
          container: semanticContainer,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

class AdaptiveListTile extends platform.AdaptiveListTile {
  const AdaptiveListTile({
    super.key,
    super.title,
    super.subtitle,
    super.leading,
    super.trailing,
    super.onTap,
    super.onLongPress,
    super.enabled,
    super.selected,
    super.hideBottomDivider,
    super.backgroundColor,
    super.separatorColor,
    super.padding,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scheme = Theme.of(context).colorScheme;
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final end = trailing == null
          ? null
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width * .45),
              child: trailing!,
            );
      final titleContent = title == null
          ? null
          : DefaultTextStyle.merge(
              style: AdaptiveTypography.item.copyWith(
                color: enabled
                    ? scheme.onSurface
                    : Theme.of(context).disabledColor,
              ),
              child: title!,
            );
      final subtitleContent = subtitle == null
          ? null
          : DefaultTextStyle.merge(
              style: AdaptiveTypography.caption.copyWith(
                color: enabled
                    ? scheme.onSurfaceVariant
                    : Theme.of(context).disabledColor,
              ),
              child: subtitle!,
            );
      const rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      if (AdaptiveUIScope.usesMiuix(context) &&
          onLongPress == null &&
          !selected &&
          backgroundColor == null) {
        // Custom center content preserves explicit text styles, rich text and
        // asynchronous subtitles instead of discarding them as plain strings.
        return miuix.MiuixBasicComponent(
          content: [
            if (titleContent != null) titleContent,
            if (titleContent != null && subtitleContent != null)
              const SizedBox(height: 2),
            if (subtitleContent != null) subtitleContent,
          ],
          startAction: leading,
          endActions: end == null ? null : [end],
          enabled: enabled,
          insideMargin: padding ?? rowPadding,
          onClick: onTap,
        );
      }
      if (!platform.PlatformInfo.isIOS) {
        return ListTile(
          leading: leading,
          title: titleContent,
          subtitle: subtitleContent,
          trailing: end,
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          enabled: enabled,
          selected: selected,
          tileColor: backgroundColor ?? Colors.transparent,
          selectedTileColor: backgroundColor ?? scheme.primaryContainer,
          titleAlignment: ListTileTitleAlignment.center,
          minLeadingWidth: 0,
          horizontalTitleGap: 12,
          minTileHeight: 56,
          minVerticalPadding: 12,
          // ListTile owns vertical spacing; outer padding would add it twice.
          contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        );
      }
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: platform.AdaptiveListTile(
          leading: leading,
          title: titleContent,
          subtitle: subtitleContent,
          trailing: end,
          onTap: onTap,
          onLongPress: onLongPress,
          enabled: enabled,
          selected: selected,
          backgroundColor:
              backgroundColor ??
              (selected ? scheme.primaryContainer : Colors.transparent),
          hideBottomDivider: true,
          padding: padding ?? rowPadding,
        ),
      );
    },
  );
}

/// A stable editor owner keeps controllers and focus outside the selected
/// MIUIX or platform-default input, including fallback for unsupported hooks.
class AdaptiveTextField extends platform.AdaptiveTextField {
  const AdaptiveTextField({
    super.key,
    super.controller,
    super.focusNode,
    super.placeholder,
    super.keyboardType,
    super.textInputAction,
    super.textCapitalization,
    super.style,
    super.textAlign,
    super.maxLines,
    super.minLines,
    super.maxLength,
    super.obscureText,
    super.autocorrect,
    super.autofocus,
    super.enabled,
    super.readOnly,
    super.prefix,
    super.suffix,
    super.prefixIcon,
    super.suffixIcon,
    super.onChanged,
    super.onSubmitted,
    super.onEditingComplete,
    super.onTap,
    super.inputFormatters,
    super.padding,
    super.decoration,
    super.cupertinoDecoration,
    super.enableSuggestions,
    super.autofillHints,
    super.onTapOutside,
  });
  @override
  Widget build(BuildContext context) => _AdaptiveEditor(field: this);
}

class _AdaptiveEditor extends StatefulWidget {
  const _AdaptiveEditor({required this.field});
  final AdaptiveTextField field;
  @override
  State<_AdaptiveEditor> createState() => _AdaptiveEditorState();
}

class _AdaptiveEditorState extends State<_AdaptiveEditor> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;
  TextEditingController get controller =>
      widget.field.controller ?? (_ownedController ??= TextEditingController());
  FocusNode get focus =>
      widget.field.focusNode ?? (_ownedFocus ??= FocusNode());
  @override
  void didUpdateWidget(_AdaptiveEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.controller != null && widget.field.controller == null) {
      _ownedController?.dispose();
      _ownedController = TextEditingController.fromValue(
        oldWidget.field.controller!.value,
      );
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    // The package lacks formatter, length, autocorrect and editing-complete
    // hooks. Keep the default editor for these explicit contracts.
    final compatible =
        f.inputFormatters == null &&
        f.maxLength == null &&
        f.autocorrect &&
        f.enableSuggestions &&
        f.onEditingComplete == null &&
        f.onTap == null &&
        f.textAlign == TextAlign.start &&
        f.autofillHints == null &&
        f.onTapOutside == null;
    if (AdaptiveUIScope.usesMiuix(context) && compatible) {
      final decoration = f.decoration;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Theme(
            // MIUIX paints its own field surface. Clear the old Material fill
            // so its internal TextField does not paint a second rectangle.
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(filled: false),
            ),
            child: miuix.MiuixTextField(
              colors: miuix.MiuixTextFieldColors(
                backgroundColor: DeadlinerColorTheme.of(
                  Theme.of(context),
                ).textFieldContainer,
                labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                borderColor: Theme.of(context).colorScheme.primary,
              ),
              controller: controller,
              focusNode: focus,
              label:
                  f.placeholder ??
                  decoration?.labelText ??
                  decoration?.hintText ??
                  '',
              useLabelAsPlaceholder: decoration?.labelText == null,
              enabled: f.enabled,
              readOnly: f.readOnly,
              autofocus: f.autofocus,
              textStyle: f.style ?? AdaptiveTypography.item,
              singleLine: f.maxLines == 1,
              minLines: f.minLines,
              maxLines: f.maxLines,
              obscureText: f.obscureText,
              keyboardType: f.keyboardType,
              textInputAction: f.textInputAction,
              textCapitalization: f.textCapitalization,
              onChanged: f.onChanged,
              onSubmitted: f.onSubmitted,
              leadingIcon:
                  f.prefix ??
                  f.prefixIcon ??
                  decoration?.prefixIcon ??
                  decoration?.icon,
              trailingIcon: f.suffix ?? f.suffixIcon ?? decoration?.suffixIcon,
            ),
          ),
          if (decoration?.errorText != null || decoration?.helperText != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Text(
                decoration!.errorText ?? decoration.helperText!,
                style: decoration.errorText != null
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      );
    }
    if (platform.PlatformInfo.isIOS) {
      return platform.AdaptiveTextField(
        controller: controller,
        focusNode: focus,
        placeholder: f.placeholder,
        keyboardType: f.keyboardType,
        textInputAction: f.textInputAction,
        textCapitalization: f.textCapitalization,
        style: f.style ?? AdaptiveTypography.item,
        textAlign: f.textAlign,
        maxLines: f.maxLines,
        minLines: f.minLines,
        maxLength: f.maxLength,
        obscureText: f.obscureText,
        autocorrect: f.autocorrect,
        enableSuggestions: f.enableSuggestions,
        autofillHints: f.autofillHints,
        onTapOutside: f.onTapOutside,
        autofocus: f.autofocus,
        enabled: f.enabled,
        readOnly: f.readOnly,
        prefix: f.prefix,
        suffix: f.suffix,
        prefixIcon: f.prefixIcon,
        suffixIcon: f.suffixIcon,
        onChanged: f.onChanged,
        onSubmitted: f.onSubmitted,
        onEditingComplete: f.onEditingComplete,
        onTap: f.onTap,
        inputFormatters: f.inputFormatters,
        padding: f.padding,
        decoration: f.decoration,
        cupertinoDecoration: f.cupertinoDecoration,
      );
    }
    return TextField(
      controller: controller,
      focusNode: focus,
      keyboardType: f.keyboardType,
      textInputAction: f.textInputAction,
      textCapitalization: f.textCapitalization,
      style: f.style ?? AdaptiveTypography.item,
      textAlign: f.textAlign,
      maxLines: f.maxLines,
      minLines: f.minLines,
      maxLength: f.maxLength,
      obscureText: f.obscureText,
      autocorrect: f.autocorrect,
      enableSuggestions: f.enableSuggestions,
      autofillHints: f.autofillHints,
      onTapOutside: f.onTapOutside,
      autofocus: f.autofocus,
      enabled: f.enabled,
      readOnly: f.readOnly,
      onChanged: f.onChanged,
      onSubmitted: f.onSubmitted,
      onEditingComplete: f.onEditingComplete,
      onTap: f.onTap,
      inputFormatters: f.inputFormatters,
      decoration:
          f.decoration ??
          InputDecoration(
            hintText: f.placeholder,
            prefix: f.prefix,
            suffix: f.suffix,
            prefixIcon: f.prefixIcon,
            suffixIcon: f.suffixIcon,
          ),
    );
  }
}

class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({super.key, this.linear = false});
  final bool linear;
  @override
  Widget build(BuildContext context) {
    if (AdaptiveUIScope.usesMiuix(context)) {
      return linear
          ? const miuix.MiuixLinearProgressIndicator()
          : const miuix.MiuixCircularProgressIndicator();
    }
    return linear && !platform.PlatformInfo.isIOS
        ? const LinearProgressIndicator()
        : const CircularProgressIndicator.adaptive();
  }
}

class AdaptiveDivider extends StatelessWidget {
  const AdaptiveDivider({super.key});
  @override
  Widget build(BuildContext context) => AdaptiveUIScope.usesMiuix(context)
      ? const miuix.MiuixHorizontalDivider()
      : const Divider();
}

/// A plain surface retains Material's ink canvas when arbitrary legacy content
/// is nested among MIUIX controls. It deliberately introduces no extra padding.
class AdaptiveSurface extends StatelessWidget {
  const AdaptiveSurface({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(color: color, child: child);
}

/// Compact multi-select filters share colors while retaining platform feedback.
class AdaptiveFilterChip extends StatelessWidget {
  const AdaptiveFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    if (AdaptiveUIScope.usesMiuix(context)) {
      final colors = miuix.MiuixTheme.of(context).colors;
      return Semantics(
        selected: selected,
        child: miuix.MiuixButton(
          onPressed: onSelected == null ? null : () => onSelected!(!selected),
          cornerRadius: 20,
          insideMargin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          colors: miuix.MiuixButtonColors(
            color: background,
            contentColor: foreground,
            disabledColor: colors.disabledSecondaryVariant,
            disabledContentColor: colors.disabledOnSecondaryVariant,
          ),
          child: DefaultTextStyle.merge(
            style: AdaptiveTypography.action.copyWith(color: foreground),
            child: label,
          ),
        ),
      );
    }
    if (platform.PlatformInfo.isIOS) {
      return Semantics(
        selected: selected,
        child: CupertinoButton(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          borderRadius: BorderRadius.circular(20),
          color: background,
          onPressed: onSelected == null ? null : () => onSelected!(!selected),
          child: DefaultTextStyle.merge(
            style: AdaptiveTypography.action.copyWith(color: foreground),
            child: DefaultTextStyle.merge(
              style: AdaptiveTypography.action.copyWith(color: foreground),
              child: label,
            ),
          ),
        ),
      );
    }
    return FilterChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      labelStyle: AdaptiveTypography.action.copyWith(color: foreground),
      selectedColor: background,
      backgroundColor: background,
      checkmarkColor: foreground,
      side: BorderSide.none,
    );
  }
}
