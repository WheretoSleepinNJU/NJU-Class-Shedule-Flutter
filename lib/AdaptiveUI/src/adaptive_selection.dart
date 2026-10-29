import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter_miuix/miuix.dart' as miuix;
import 'adaptive_ui_controller.dart';

class AdaptiveOption<T> {
  const AdaptiveOption({required this.value, required this.child});
  final T value;
  final Widget child;
}

String _label(Widget widget) => widget is Text
    ? widget.data ?? ''
    : widget is Row
    ? widget.children.whereType<Text>().map((e) => e.data ?? '').join(' ')
    : '';

Widget _menuOption(Widget child) {
  if (child is Text) {
    return Text(_label(child), style: child.style, softWrap: true);
  }
  if (child is Row) {
    return Row(
      textDirection: child.textDirection,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: child.spacing,
      children: [
        for (final item in child.children)
          if (item is Text) Expanded(child: _menuOption(item)) else item,
      ],
    );
  }
  return child;
}

/// One bounded anchor and viewport-sized menu for all renderers. Long options
/// wrap inside the menu; the trailing value never competes with an unbounded row.
class AdaptiveDropdown<T> extends StatefulWidget {
  const AdaptiveDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.expanded = false,
  });
  final T? value;
  final List<AdaptiveOption<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool expanded;
  @override
  State<AdaptiveDropdown<T>> createState() => _AdaptiveDropdownState<T>();
}

class _AdaptiveDropdownState<T> extends State<AdaptiveDropdown<T>>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AdaptiveUIScope.usesMiuix(context)) _open = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _close();
    }
  }

  final _anchorKey = GlobalKey();
  bool _open = false;
  Rect _anchor = Rect.zero;
  void _close() {
    if (mounted && _open) setState(() => _open = false);
  }

  void _show() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() {
      _anchor = box.localToGlobal(Offset.zero) & box.size;
      _open = true;
    });
  }

  double _menuWidth(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = math.max(
      0.0,
      media.size.width - media.viewPadding.horizontal - 24,
    );
    final style = Theme.of(context).textTheme.bodyLarge!;
    var wanted = 224.0;
    for (final item in widget.items) {
      final painter = TextPainter(
        text: TextSpan(text: _label(item.child), style: style),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
      )..layout();
      wanted = math.max(wanted, painter.width + 72);
      painter.dispose();
    }
    return math.min(available, math.min(400, wanted));
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.items
        .where((item) => item.value == widget.value)
        .firstOrNull;
    final label = selected == null ? '—' : _label(selected.child);
    final enabled = widget.onChanged != null;
    final scheme = Theme.of(context).colorScheme;
    final width = _menuWidth(context);
    final anchor = ConstrainedBox(
      key: _anchorKey,
      constraints: BoxConstraints(
        minHeight: 44,
        maxWidth: widget.expanded
            ? double.infinity
            : math.min(240, MediaQuery.sizeOf(context).width * .45),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                softWrap: true,
                textAlign: widget.expanded ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  color: enabled
                      ? scheme.primary
                      : Theme.of(context).disabledColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.unfold_more_rounded,
              size: 20,
              color: enabled ? scheme.primary : Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
    if (platform.PlatformInfo.isIOS) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.expanded
              ? double.infinity
              : MediaQuery.sizeOf(context).width * .45,
        ),
        child: enabled
            ? platform.AdaptivePopupMenuButton.text<T>(
                label: label,
                height: 44,
                shrinkWrap: true,
                items: [
                  for (final item in widget.items)
                    platform.AdaptivePopupMenuItem<T>(
                      label: _label(item.child),
                      value: item.value,
                      selected: item.value == widget.value,
                    ),
                ],
                onSelected: (_, item) => widget.onChanged?.call(item.value),
              )
            : anchor,
      );
    }
    if (AdaptiveUIScope.usesMiuix(context)) {
      return PopScope(
        canPop: !_open,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Semantics(
                button: true,
                enabled: enabled,
                value: label,
                child: InkWell(
                  onTap: enabled ? _show : null,
                  borderRadius: BorderRadius.circular(12),
                  child: anchor,
                ),
              ),
            ),
            miuix.MiuixWindowListPopup(
              show: _open,
              anchorBounds: _anchor,
              minWidth: width,
              alignment: miuix.MiuixPopupAlign.end,
              popupPositionProvider: _SafeDropdownPosition(
                MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom,
              ),
              maxHeight: math.max(
                50,
                (MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom -
                        32) *
                    .6,
              ),
              onDismissRequest: _close,
              onDismissFinished: _close,
              content: SizedBox(
                width: width,
                child: miuix.MiuixListPopupColumn(
                  children: [
                    miuix.MiuixDropdownEntriesPopupContent(
                      entries: [
                        miuix.MiuixDropdownEntry(
                          items: [
                            for (final item in widget.items)
                              miuix.MiuixDropdownItem(
                                text: _label(item.child),
                                selected: item.value == widget.value,
                                onClick: () {},
                              ),
                          ],
                        ),
                      ],
                      dropdownColors:
                          miuix.MiuixDropdownDefaults.dropdownColors(context),
                      onItemClick: (_, index) {
                        _close();
                        widget.onChanged?.call(widget.items[index].value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return PopupMenuButton<T>(
      enabled: enabled,
      constraints: BoxConstraints.tightFor(width: width),
      position: PopupMenuPosition.under,
      onSelected: widget.onChanged,
      itemBuilder: (_) => [
        for (final item in widget.items)
          PopupMenuItem<T>(
            value: item.value,
            height: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _menuOption(item.child),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 20,
                    child: item.value == widget.value
                        ? Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: scheme.primary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
      child: anchor,
    );
  }
}

class AdaptiveDropdownFormField<T> extends FormField<T> {
  AdaptiveDropdownFormField({
    super.key,
    required List<AdaptiveOption<T>> items,
    required ValueChanged<T?>? onChanged,
    super.initialValue,
    super.validator,
    InputDecoration decoration = const InputDecoration(),
    bool enabled = true,
  }) : super(
         enabled: enabled,
         builder: (state) => InputDecorator(
           decoration: decoration.copyWith(
             enabled: enabled,
             errorText: state.errorText,
           ),
           isEmpty: state.value == null,
           child: AdaptiveDropdown<T>(
             value: state.value,
             items: items,
             expanded: true,
             onChanged: !enabled || onChanged == null
                 ? null
                 : (value) {
                     state.didChange(value);
                     onChanged(value);
                   },
           ),
         ),
       );
}

/// Platform choice stays here; pages retain the same bounded value contract.
class AdaptiveNumberPicker extends StatefulWidget {
  const AdaptiveNumberPicker({
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
  State<AdaptiveNumberPicker> createState() => _AdaptiveNumberPickerState();
}

class _AdaptiveNumberPickerState extends State<AdaptiveNumberPicker> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.value.clamp(widget.min, widget.max) - widget.min,
  );
  @override
  void didUpdateWidget(AdaptiveNumberPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value != widget.value ||
            oldWidget.min != widget.min ||
            oldWidget.max != widget.max) &&
        _controller.hasClients) {
      _controller.jumpToItem(
        widget.value.clamp(widget.min, widget.max) - widget.min,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String label(int value) => widget.label?.call(value) ?? '$value';
    if (AdaptiveUIScope.usesMiuix(context)) {
      return miuix.MiuixNumberPicker(
        value: widget.value.clamp(widget.min, widget.max),
        min: widget.min,
        max: widget.max,
        label: label,
        onValueChanged: widget.onValueChanged,
      );
    }
    if (platform.PlatformInfo.isIOS) {
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

class _SafeDropdownPosition implements miuix.MiuixPopupPositionProvider {
  const _SafeDropdownPosition(this.bottom);
  final double bottom;
  @override
  EdgeInsetsGeometry get margins => const EdgeInsets.all(12);
  @override
  Offset calculatePosition({
    required Rect anchorBounds,
    required Rect windowBounds,
    required TextDirection textDirection,
    required Size popupContentSize,
    required EdgeInsets popupMargin,
    required miuix.MiuixPopupAlign alignment,
  }) =>
      miuix.MiuixListPopupDefaults.dropdownPositionProvider(
        horizontalMargin: 12,
      ).calculatePosition(
        anchorBounds: anchorBounds,
        windowBounds: Rect.fromLTRB(
          windowBounds.left,
          windowBounds.top,
          windowBounds.right,
          math.min(windowBounds.bottom, bottom),
        ),
        textDirection: textDirection,
        popupContentSize: popupContentSize,
        popupMargin: popupMargin,
        alignment: alignment,
      );
}
