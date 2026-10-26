import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';
export 'package:flutter_miuix/miuix.dart';

/// Scope the experiment to settings, following the application's theme mode.
class SettingsTheme extends StatelessWidget {
  const SettingsTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final app = Theme.of(context);
    final dark = app.brightness == Brightness.dark;
    final defaults = defaultTextStyles();
    TextStyle font(TextStyle style) => style.copyWith(
      fontFamily: app.textTheme.bodyMedium?.fontFamily,
      fontFamilyFallback: app.textTheme.bodyMedium?.fontFamilyFallback,
    );
    return MiuixTheme(
      data: MiuixThemeData.of(app.brightness).copyWith(
        textStyles: defaults.copy(
          main: font(defaults.main),
          paragraph: font(defaults.paragraph),
          body1: font(defaults.body1),
          body2: font(defaults.body2),
          button: font(defaults.button),
          footnote1: font(defaults.footnote1),
          footnote2: font(defaults.footnote2),
          headline1: font(defaults.headline1),
          headline2: font(defaults.headline2),
          subtitle: font(defaults.subtitle),
          title1: font(defaults.title1),
          title2: font(defaults.title2),
          title3: font(defaults.title3),
          title4: font(defaults.title4),
        ),
        colors: miuixColorsFromSeed(seed: app.colorScheme.primary, dark: dark),
        fontWeightAdjustment: MediaQuery.boldTextOf(context) ? 100 : 0,
      ),
      child: DefaultTextStyle(
        style: app.textTheme.bodyMedium!.copyWith(
          decoration: TextDecoration.none,
        ),
        child: IconTheme(
          data: IconThemeData(color: app.colorScheme.onSurface),
          child: child,
        ),
      ),
    );
  }
}

class SettingsScaffold extends StatefulWidget {
  const SettingsScaffold({super.key, required this.title, required this.body});
  final String title;
  final Widget body;
  @override
  State<SettingsScaffold> createState() => _SettingsScaffoldState();
}

class _SettingsScaffoldState extends State<SettingsScaffold> {
  late final _scrollBehavior = miuixScrollBehavior();
  @override
  void dispose() {
    _scrollBehavior.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsTheme(
    child: Builder(
      builder: (context) => MiuixScaffold(
        containerColor: MiuixTheme.of(context).colors.background,
        // The upstream expanding title clips at large accessibility text sizes.
        topBar: MediaQuery.textScalerOf(context).scale(32) > 40
            ? MiuixSmallTopAppBar(
                title: widget.title,
                color: MiuixTheme.of(context).colors.background,
                navigationIcon: Navigator.of(context).canPop()
                    ? MiuixIconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.arrow_back_rounded),
                      )
                    : null,
              )
            : MiuixTopAppBar(
                title: widget.title,
                color: MiuixTheme.of(context).colors.background,
                scrollBehavior: _scrollBehavior,
                navigationIcon: Navigator.of(context).canPop()
                    ? MiuixIconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.arrow_back_rounded),
                      )
                    : null,
              ),
        content: (padding) => Padding(
          padding: padding,
          child: MiuixScrollBehaviorListener(
            behavior: _scrollBehavior,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  child: widget.body,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Widget slots retain asynchronous summaries and existing localized labels.
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
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    return GestureDetector(
      onLongPress: enabled ? onLongPress : null,
      child: MiuixBasicComponent(
        enabled: enabled,
        onClick: onTap,
        insideMargin: contentPadding ?? const EdgeInsets.all(16),
        startAction: leading,
        endActions: trailing != null
            ? [trailing!]
            : onTap != null
            ? [const Icon(Icons.chevron_right_rounded)]
            : null,
        content: [
          DefaultTextStyle(
            style: theme.textStyles.headline1.copyWith(
              color: enabled
                  ? theme.colors.onBackground
                  : theme.colors.disabledOnSecondaryVariant,
              fontWeight: FontWeight.w500,
            ),
            child: title,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DefaultTextStyle(
                style: theme.textStyles.body2.copyWith(
                  color: theme.colors.onSurfaceVariantSummary,
                ),
                child: subtitle!,
              ),
            ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => MiuixSwitch(
    value: value,
    enabled: onChanged != null,
    onChanged: onChanged ?? (_) {},
  );
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
  final Text title;
  final Text? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  @override
  Widget build(BuildContext context) => MiuixSwitchPreference(
    title: title.data ?? '',
    summary: subtitle?.data,
    value: value,
    enabled: onChanged != null,
    onChanged: onChanged ?? (_) {},
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
    // BasicComponent's end-action row measures non-flex children unbounded.
    // Give the nested dropdown a finite width before it builds its own row.
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width * .36).clamp(96.0, 168.0),
      child: MiuixOverlayDropdownMenu(
        title: selected == null ? '—' : _label(selected.child),
        insideMargin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        enabled: onChanged != null,
        entry: MiuixDropdownEntry(
          items: items
              .map(
                (item) => MiuixDropdownItem(
                  text: _label(item.child),
                  selected: item.value == value,
                  onClick: () => onChanged?.call(item.value),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Dialog routes retain Navigator results while MIUIX owns panel and actions.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });
  final Text title;
  final Widget content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => SettingsTheme(
    child: MiuixScaffold(
      containerColor: Colors.transparent,
      content: (_) => MiuixOverlayDialog(
        show: true,
        title: title.data,
        enableWindowDim: false,
        renderInRootScaffold: false,
        onDismissRequest: () => Navigator.of(context).pop(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    ),
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
      MiuixButton(
        onPressed: widgetCancelAction,
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      MiuixButton(
        onPressed: widgetOKAction,
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
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
  Widget build(BuildContext context) => MiuixButton(
    onPressed: onPressed,
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
