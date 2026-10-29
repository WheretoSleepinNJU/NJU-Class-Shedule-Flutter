import '../../../AdaptiveUI/adaptive_ui.dart' as ui;
import 'package:flutter/material.dart';

/// Product-facing names delegate renderer selection to AdaptiveUI.
/// Keep settings persistence and navigation independent of the selected library.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });
  final String title;
  final Widget body;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    return ui.AdaptiveScaffold(
      appBar: ui.AdaptiveTopAppBar(title: Text(title), actions: actions),
      scrollUnderAppBar: true,
      body: ui.AdaptivePageFrame(child: body),
    );
  }
}

/// Put the native toolbar clearance inside the scrollable, so content can pass below glass.
class SettingsListView extends StatelessWidget {
  const SettingsListView({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) => ui.AdaptivePageList(
    children: children,
    padding: padding ?? ui.AdaptiveLayout.pagePadding,
  );
}

class SettingsSurface extends StatelessWidget {
  const SettingsSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ui.AdaptiveCard(
    margin: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.contentPadding,
  });
  final Widget title;
  final Widget? subtitle, leading, trailing;
  final VoidCallback? onTap, onLongPress;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  @override
  Widget build(BuildContext context) => ui.AdaptiveListTile(
    title: title,
    subtitle: subtitle,
    leading: leading,
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    enabled: enabled,
    onTap: enabled ? onTap : null,
    onLongPress: enabled ? onLongPress : null,
    padding: contentPadding,
  );
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) =>
      ui.AdaptiveSwitch(value: value, onChanged: onChanged);
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.contentPadding,
  });
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  @override
  Widget build(BuildContext context) => SettingsTile(
    title: title,
    subtitle: subtitle,
    enabled: onChanged != null,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    contentPadding: contentPadding,
    trailing: SettingsSwitch(value: value, onChanged: onChanged),
  );
}

class SettingsOption<T> extends ui.AdaptiveOption<T> {
  const SettingsOption({required super.value, required super.child});
}

class SettingsDropdown<T> extends ui.AdaptiveDropdown<T> {
  const SettingsDropdown({
    super.key,
    required super.value,
    required super.items,
    required super.onChanged,
  });
}

/// Form and Navigator state stay in Flutter; AdaptiveUI owns the surface.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => ui.AdaptiveDialog(
    platformAdaptive: true,
    title: title,
    content: SingleChildScrollView(child: content),
    actions: actions,
  );
}

class SettingsActionDialog extends StatelessWidget {
  const SettingsActionDialog(
    this.title,
    this.content, {
    super.key,
    required this.widgetCancelAction,
    required this.widgetOKAction,
  });
  final String title;
  final Widget content;
  final VoidCallback widgetCancelAction, widgetOKAction;
  @override
  Widget build(BuildContext context) => SettingsDialog(
    title: Text(title),
    content: content,
    actions: [
      SettingsButton(
        onPressed: widgetCancelAction,
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      SettingsButton(
        onPressed: widgetOKAction,
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.onPressed,
    required this.child,
  });
  final VoidCallback? onPressed;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ui.AdaptiveButton.text(onPressed: onPressed, child: child);
  }
}

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });
  final VoidCallback? onPressed;
  final Widget icon, label;
  @override
  Widget build(BuildContext context) => ui.AdaptiveButton.icon(
    onPressed: onPressed,
    icon: icon,
    label: label,
    variant: ui.AdaptiveButtonVariant.outlined,
  );
}

class SettingsIconAction extends StatelessWidget {
  const SettingsIconAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) => ui.AdaptiveButton.text(
    onPressed: onPressed,

    style: TextButton.styleFrom(
      backgroundColor: backgroundColor,
      minimumSize: const Size(44, 44),
    ),
    child: child,
  );
}

class SettingsPressable extends StatelessWidget {
  const SettingsPressable({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final BorderRadius? borderRadius;
  @override
  Widget build(BuildContext context) => ui.AdaptiveButton.text(
    onPressed: onPressed,

    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      shape: borderRadius == null
          ? null
          : RoundedRectangleBorder(borderRadius: borderRadius!),
    ),
    child: child,
  );
}

class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    this.controller,
    this.autofocus = false,
    this.singleLine = true,
    this.label = '',
    this.leadingIcon,
    this.trailingIcon,
  });
  final TextEditingController? controller;
  final bool autofocus, singleLine;
  final String label;
  final Widget? leadingIcon, trailingIcon;
  @override
  Widget build(BuildContext context) => ui.AdaptiveTextField(
    controller: controller,
    autofocus: autofocus,
    placeholder: label,
    prefixIcon: leadingIcon,
    suffixIcon: trailingIcon,
    maxLines: singleLine ? 1 : null,
  );
}

class SettingsNumberPicker extends ui.AdaptiveNumberPicker {
  const SettingsNumberPicker({
    super.key,
    required super.value,
    required super.onValueChanged,
    super.min,
    super.max,
    super.label,
  });
}

class SettingsRadioPreference extends StatelessWidget {
  const SettingsRadioPreference({
    super.key,
    required this.title,
    required this.selected,
    required this.onClick,
  });
  final String title;
  final bool selected;
  final VoidCallback onClick;
  @override
  Widget build(BuildContext context) => SettingsTile(
    title: Text(title),
    onTap: onClick,
    trailing: ui.AdaptiveRadio<bool>(
      value: true,
      groupValue: selected,
      onChanged: (_) => onClick(),
    ),
  );
}

class SettingsCircularProgressIndicator extends StatelessWidget {
  const SettingsCircularProgressIndicator({super.key});
  @override
  Widget build(BuildContext context) => const ui.AdaptiveProgressIndicator();
}

class SettingsLinearProgressIndicator extends StatelessWidget {
  const SettingsLinearProgressIndicator({super.key});
  @override
  Widget build(BuildContext context) =>
      const ui.AdaptiveProgressIndicator(linear: true);
}

class SettingsHorizontalDivider extends StatelessWidget {
  const SettingsHorizontalDivider({super.key});
  @override
  Widget build(BuildContext context) => const ui.AdaptiveDivider();
}
