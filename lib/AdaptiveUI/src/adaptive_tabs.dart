import 'dart:math' as math;
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'adaptive_ui_controller.dart';
import 'adaptive_typography.dart';
import 'android/compose_navigation.dart';
import 'ohos/hds_chrome.dart';

/// Controlled page categories. All platform and original-renderer choices live
/// here; pages retain the same content tree and selection state.
class AdaptiveTabRow extends StatelessWidget {
  const AdaptiveTabRow({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(tabs.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < tabs.length);
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  static double heightOf(BuildContext context) =>
      math.max(42.0, MediaQuery.textScalerOf(context).scale(14) * 1.3 + 12);
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SizedBox(
        width: double.infinity,
        child: Builder(builder: _control),
      ),
    ),
  );

  Widget _control(BuildContext context) {
    final height = heightOf(context);
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        MediaQuery.viewInsetsOf(context).bottom == 0;

    if (AdaptiveHostedTabScope.of(context)) {
      // Native chrome paints the control; retain Flutter accessibility and
      // geometry without creating a second platform view or backdrop.
      return ExcludeSemantics(
        excluding: platform.PlatformInfo.isIOS || isHarmonyOS,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Semantics(
                    label: tabs[i],
                    selected: i == selectedIndex,
                    button: true,
                    enabled: visible,
                    onTap: visible ? () => onSelected(i) : null,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    Widget material() => SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (var i = 0; i < tabs.length; i++)
            ButtonSegment(
              value: i,
              label: Text(tabs[i], textAlign: TextAlign.center),
            ),
        ],
        selected: {selectedIndex},
        onSelectionChanged: (value) => onSelected(value.single),
        style: SegmentedButton.styleFrom(
          textStyle: AdaptiveTypography.body,
          minimumSize: Size(0, height),
          visualDensity: VisualDensity.standard,
        ),
      ),
    );
    if (platform.PlatformInfo.isIOS) {
      // A native page control must not sit above a Flutter popup route.
      return SizedBox(
        height: height,
        child: visible
            ? platform.AdaptiveSegmentedControl(
                labels: tabs,
                selectedIndex: selectedIndex,
                onValueChanged: onSelected,
                height: height,
              )
            : const SizedBox.shrink(),
      );
    }
    final original =
        AdaptiveUIScope.maybeOf(context)?.useOriginalComponents ?? true;
    if (isHarmonyOS ||
        original ||
        !AdaptiveUIScope.supportsNativeGlass(context) ||
        height > 42.5) {
      return material();
    }
    return SizedBox(
      height: height,
      child: ComposeTabRow(
        labels: tabs,
        selectedIndex: selectedIndex,
        visible: visible,
        onSelected: onSelected,
        fallback: material(),
      ),
    );
  }
}

/// Internal bridge for a tab row painted inside the native toolbar container.
class AdaptiveHostedTabScope extends InheritedWidget {
  const AdaptiveHostedTabScope({super.key, required super.child});
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdaptiveHostedTabScope>() !=
      null;
  @override
  bool updateShouldNotify(AdaptiveHostedTabScope oldWidget) => false;
}
