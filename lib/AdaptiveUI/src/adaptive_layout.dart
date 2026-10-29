import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'adaptive_content.dart';
import 'adaptive_controls.dart';

/// Shared page rhythm; renderer choices and platform geometry stay in AdaptiveUI.
abstract final class AdaptiveLayout {
  static const maxContentWidth = 760.0;
  static const pagePadding = EdgeInsets.all(16);
  static const sectionGap = 16.0;
  static double cardRadiusOf(BuildContext context) =>
      platform.PlatformInfo.isIOS ? 16 : 20;
}

class AdaptivePageList extends StatelessWidget {
  const AdaptivePageList({
    super.key,
    required this.children,
    this.padding = AdaptiveLayout.pagePadding,
    this.controller,
    this.physics,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AdaptiveLayout.maxContentWidth,
      ),
      child: AdaptiveListView(
        padding: padding,
        controller: controller,
        physics: physics,
        keyboardDismissBehavior: keyboardDismissBehavior,
        children: children,
      ),
    ),
  );
}

class AdaptivePageScroll extends StatelessWidget {
  const AdaptivePageScroll({
    super.key,
    required this.child,
    this.padding = AdaptiveLayout.pagePadding,
    this.controller,
    this.physics,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AdaptiveLayout.maxContentWidth,
      ),
      child: AdaptiveScrollView(
        padding: padding,
        controller: controller,
        physics: physics,
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

/// A semantic section contains related controls, rather than a card per row.
class AdaptiveSection extends StatelessWidget {
  const AdaptiveSection({
    super.key,
    required this.children,
    this.title,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.only(bottom: AdaptiveLayout.sectionGap),
    this.separated = true,
    this.color,
  });
  final List<Widget> children;
  final Widget? title;
  final EdgeInsetsGeometry padding, margin;
  final bool separated;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final child in children) {
      if (items.isNotEmpty && separated && platform.PlatformInfo.isIOS) {
        items.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Divider(
              height: .5,
              thickness: .5,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .55),
            ),
          ),
        );
      }
      items.add(child);
    }
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 10),
              child: Semantics(
                header: true,
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: title!,
                ),
              ),
            ),
          AdaptiveCard(
            color: color,
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

/// Width policy for custom slivers, indexed lists and other scroll containers.
class AdaptivePageFrame extends StatelessWidget {
  const AdaptivePageFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AdaptiveLayout.maxContentWidth,
      ),
      child: child,
    ),
  );
}
