import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'adaptive_navigation.dart';

/// The bar owns the clearance; scrollables consume it inside their viewport.
/// A consumed scope prevents nested lists from adding a second top inset.
class AdaptiveContentInsets extends InheritedWidget {
  const AdaptiveContentInsets({
    super.key,
    required this.top,
    required super.child,
    this.bottom,
  });
  final double top;
  final double? bottom;
  static double bottomOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AdaptiveContentInsets>()
          ?.bottom ??
      AdaptiveNavigationScope.scrollClearanceOf(context);
  static double topOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AdaptiveContentInsets>()
          ?.top ??
      platform.NativeToolbarBodyScope.topInsetOf(context);
  static EdgeInsets? scrollPaddingOf(
    BuildContext context, [
    EdgeInsetsGeometry? padding,
  ]) {
    final inset = topOf(context);
    final resolved = padding?.resolve(Directionality.of(context));
    final bottom = bottomOf(context);
    if (inset == 0 && bottom == 0) return resolved;
    return (resolved ??
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom))
        .add(EdgeInsets.only(top: inset, bottom: bottom))
        .resolve(Directionality.of(context));
  }

  @override
  bool updateShouldNotify(AdaptiveContentInsets oldWidget) =>
      top != oldWidget.top || bottom != oldWidget.bottom;
}

class AdaptiveListView extends StatelessWidget {
  const AdaptiveListView({
    super.key,
    required this.children,
    this.padding,
    this.controller,
    this.physics,
    this.primary,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool? primary;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  @override
  Widget build(BuildContext context) => AdaptiveContentInsets(
    bottom: scrollDirection == Axis.vertical
        ? 0
        : AdaptiveContentInsets.bottomOf(context),
    top: scrollDirection == Axis.vertical
        ? 0
        : AdaptiveContentInsets.topOf(context),
    child: ListView(
      controller: controller,
      physics: physics,
      primary: primary,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      padding: scrollDirection == Axis.vertical
          ? AdaptiveContentInsets.scrollPaddingOf(context, padding)
          : padding,
      keyboardDismissBehavior: keyboardDismissBehavior,
      children: children,
    ),
  );
}

class AdaptiveScrollView extends StatelessWidget {
  const AdaptiveScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.physics,
    this.primary,
    this.scrollDirection = Axis.vertical,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool? primary;
  final Axis scrollDirection;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  @override
  Widget build(BuildContext context) => AdaptiveContentInsets(
    bottom: scrollDirection == Axis.vertical
        ? 0
        : AdaptiveContentInsets.bottomOf(context),
    top: scrollDirection == Axis.vertical
        ? 0
        : AdaptiveContentInsets.topOf(context),
    child: SingleChildScrollView(
      controller: controller,
      physics: physics,
      primary: primary,
      scrollDirection: scrollDirection,
      padding: scrollDirection == Axis.vertical
          ? AdaptiveContentInsets.scrollPaddingOf(context, padding)
          : padding,
      keyboardDismissBehavior: keyboardDismissBehavior,
      child: child,
    ),
  );
}

/// Keep pull-to-refresh feedback below the controls while the viewport itself
/// reaches the status bar and lets its content scroll underneath.
class AdaptiveRefreshIndicator extends StatelessWidget {
  const AdaptiveRefreshIndicator({
    super.key,
    this.refreshIndicatorKey,
    required this.child,
    required this.onRefresh,
    this.color,
  });
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;
  final Widget child;
  final RefreshCallback onRefresh;
  final Color? color;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    key: refreshIndicatorKey,
    color: color,
    onRefresh: onRefresh,
    edgeOffset: AdaptiveContentInsets.topOf(context),
    child: child,
  );
}
