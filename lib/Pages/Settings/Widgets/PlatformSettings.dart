import '../../../AdaptiveUI/adaptive_ui.dart' as ui;
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as adaptive;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Product-facing adapters: both platforms are rendered by adaptive_platform_ui.
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      ),
    );
  }
}

/// Put the native toolbar clearance inside the scrollable, so content can pass below glass.
class SettingsListView extends StatelessWidget {
  const SettingsListView({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    final inset = adaptive.AndroidToolbarBodyScope.topInsetOf(context);
    final resolved = padding?.resolve(Directionality.of(context));
    return ListView(
      padding: inset > 0
          ? (resolved ??
                    EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ))
                .add(EdgeInsets.only(top: inset))
          : padding,
      children: children,
    );
  }
}

class SettingsSurface extends StatelessWidget {
  const SettingsSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => adaptive.AdaptiveCard(
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
  Widget build(BuildContext context) => adaptive.AdaptiveListTile(
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
      adaptive.AdaptiveSwitch(value: value, onChanged: onChanged);
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

class SettingsOption<T> {
  const SettingsOption({required this.value, required this.child});
  final T value;
  final Widget child;
}

String _label(Widget widget) => widget is Text
    ? widget.data ?? ''
    : widget is Row
    ? widget.children.whereType<Text>().map((e) => e.data ?? '').join(' ')
    : '';

class SettingsDropdown<T> extends StatelessWidget {
  const SettingsDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T? value;
  final List<SettingsOption<T>> items;
  final ValueChanged<T?>? onChanged;
  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => item.value == value).firstOrNull;
    final label = selected == null ? '—' : _label(selected.child);
    if (onChanged == null) {
      return Text(
        label,
        style: TextStyle(color: Theme.of(context).disabledColor),
      );
    }
    return adaptive.AdaptivePopupMenuButton.text<T>(
      label: label,
      shrinkWrap: true,
      items: items
          .map(
            (item) => adaptive.AdaptivePopupMenuItem<T>(
              label: _label(item.child),
              value: item.value,
              selected: item.value == value,
            ),
          )
          .toList(),
      onSelected: (_, item) => onChanged?.call(item.value),
    );
  }
}

/// The package's native alert API accepts messages, not arbitrary form widgets.
/// Keep form content and Navigator results using Flutter's platform dialog.
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
  Widget build(BuildContext context) => AlertDialog.adaptive(
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
    final theme = Theme.of(context);
    // Adaptive plain buttons supply their own foreground. Clear the legacy
    // filled TextButton background so dialog actions retain readable contrast.
    return Theme(
      data: theme.copyWith(
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
      ),
      child: adaptive.AdaptiveButton.child(
        onPressed: onPressed,
        enabled: onPressed != null,
        style: adaptive.AdaptiveButtonStyle.plain,
        child: child,
      ),
    );
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
  Widget build(BuildContext context) => adaptive.AdaptiveButton.child(
    onPressed: onPressed,
    enabled: onPressed != null,
    style: adaptive.AdaptiveButtonStyle.bordered,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    ),
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
  Widget build(BuildContext context) => adaptive.AdaptiveButton.child(
    onPressed: onPressed,
    enabled: onPressed != null,
    style: adaptive.AdaptiveButtonStyle.plain,
    color: backgroundColor,
    minSize: const Size(44, 44),
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
  Widget build(BuildContext context) => adaptive.AdaptiveButton.child(
    onPressed: onPressed,
    enabled: onPressed != null,
    style: adaptive.AdaptiveButtonStyle.plain,
    padding: EdgeInsets.zero,
    minSize: Size.zero,
    borderRadius: borderRadius,
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
  Widget build(BuildContext context) => adaptive.AdaptiveTextField(
    controller: controller,
    autofocus: autofocus,
    placeholder: label,
    prefixIcon: leadingIcon,
    suffixIcon: trailingIcon,
    maxLines: singleLine ? 1 : null,
  );
}

/// Numeric wheel is not provided by the package. Retain a Cupertino picker on
/// iOS and a Material dropdown on Android, with the same bounded value contract.
class SettingsNumberPicker extends StatefulWidget {
  const SettingsNumberPicker({
    super.key,
    required this.value,
    required this.onValueChanged,
    this.min = 0,
    this.max = 10,
    this.label,
  });
  final int value, min, max;
  final ValueChanged<int> onValueChanged;
  final String Function(int)? label;
  @override
  State<SettingsNumberPicker> createState() => _SettingsNumberPickerState();
}

class _SettingsNumberPickerState extends State<SettingsNumberPicker> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.value.clamp(widget.min, widget.max) - widget.min,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String label(int value) => widget.label?.call(value) ?? '$value';
    if (adaptive.PlatformInfo.isIOS) {
      return SizedBox(
        height: 160,
        child: CupertinoPicker.builder(
          scrollController: _controller,
          itemExtent: 36,
          childCount: widget.max - widget.min + 1,
          onSelectedItemChanged: (index) =>
              widget.onValueChanged(widget.min + index),
          itemBuilder: (_, index) =>
              Center(child: Text(label(widget.min + index))),
        ),
      );
    }
    return SizedBox(
      width: 240,
      child: DropdownButton<int>(
        isExpanded: true,
        menuMaxHeight: 320,
        value: widget.value.clamp(widget.min, widget.max),
        items: [
          for (var value = widget.min; value <= widget.max; value++)
            DropdownMenuItem(value: value, child: Text(label(value))),
        ],
        onChanged: (value) {
          if (value != null) widget.onValueChanged(value);
        },
      ),
    );
  }
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
    trailing: adaptive.AdaptiveRadio<bool>(
      value: true,
      groupValue: selected,
      onChanged: (_) => onClick(),
    ),
  );
}

class SettingsCircularProgressIndicator extends StatelessWidget {
  const SettingsCircularProgressIndicator({super.key});
  @override
  Widget build(BuildContext context) =>
      const CircularProgressIndicator.adaptive();
}

class SettingsLinearProgressIndicator extends StatelessWidget {
  const SettingsLinearProgressIndicator({super.key});
  @override
  Widget build(BuildContext context) => adaptive.PlatformInfo.isIOS
      ? const CupertinoActivityIndicator()
      : const LinearProgressIndicator();
}

class SettingsHorizontalDivider extends StatelessWidget {
  const SettingsHorizontalDivider({super.key});
  @override
  Widget build(BuildContext context) => const Divider();
}
