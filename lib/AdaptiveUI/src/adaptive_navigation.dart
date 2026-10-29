import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'adaptive_ui_controller.dart';
import 'android/compose_navigation.dart';
import 'ohos/hds_chrome.dart';
import 'theme/deadliner_color_theme.dart';

class AdaptiveNavigationItem {
  const AdaptiveNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.iosSymbol,
    required this.iosSelectedSymbol,
    this.androidIcon = 'Months',
  });
  final String label, iosSymbol, iosSelectedSymbol, androidIcon;
  final IconData icon, selectedIcon;
}

/// Only the shell knows the bottom chrome's geometry; pages consume clearance.
class AdaptiveNavigationScope extends InheritedWidget {
  const AdaptiveNavigationScope({
    super.key,
    required this.barHeight,
    required this.onSelect,
    required super.child,
  });
  final double barHeight;
  final ValueChanged<int> onSelect;
  static AdaptiveNavigationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdaptiveNavigationScope>();
  static double heightOf(BuildContext context) =>
      maybeOf(context)?.barHeight ?? 0;
  static double scrollClearanceOf(BuildContext context) {
    final scope = maybeOf(context);
    return scope == null
        ? 0
        : scope.barHeight + MediaQuery.paddingOf(context).bottom;
  }

  @override
  bool updateShouldNotify(AdaptiveNavigationScope oldWidget) =>
      barHeight != oldWidget.barHeight;
}

/// Publishes the page's foreground contrast without choosing a platform.
/// Android navigation uses the opposite surface; other pages retain app colors.
class AdaptiveNavigationAppearance extends StatefulWidget {
  const AdaptiveNavigationAppearance({
    super.key,
    required this.foregroundColor,
    required this.child,
  });
  final Color? foregroundColor;
  final Widget child;
  @override
  State<AdaptiveNavigationAppearance> createState() =>
      _NavigationAppearanceState();
}

class _NavigationAppearanceState extends State<AdaptiveNavigationAppearance> {
  _NavigationPageAppearanceScope? _scope;
  void _publish() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scope?.report(this, widget.foregroundColor);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = context
        .dependOnInheritedWidgetOfExactType<_NavigationPageAppearanceScope>();
    _publish();
  }

  @override
  void didUpdateWidget(AdaptiveNavigationAppearance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foregroundColor != widget.foregroundColor) _publish();
  }

  @override
  void dispose() {
    final scope = _scope;
    WidgetsBinding.instance.addPostFrameCallback((_) => scope?.clear(this));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NavigationPageAppearanceScope extends InheritedWidget {
  const _NavigationPageAppearanceScope({
    required this.report,
    required this.clear,
    required super.child,
  });
  final void Function(Object owner, Color? foreground) report;
  final void Function(Object owner) clear;
  @override
  bool updateShouldNotify(_NavigationPageAppearanceScope oldWidget) => false;
}

/// Suppress a nested page host while retaining its existing content and logic.
class AdaptiveEmbeddedPage extends InheritedWidget {
  const AdaptiveEmbeddedPage({super.key, required super.child});
  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdaptiveEmbeddedPage>() !=
      null;
  @override
  bool updateShouldNotify(AdaptiveEmbeddedPage oldWidget) => false;
}

class AdaptiveNavigationShell extends StatefulWidget {
  const AdaptiveNavigationShell({
    super.key,
    required this.items,
    required this.pages,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(items.length == pages.length);
  final List<AdaptiveNavigationItem> items;
  final List<Widget> pages;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  State<AdaptiveNavigationShell> createState() =>
      _AdaptiveNavigationShellState();
}

class _AdaptiveNavigationShellState extends State<AdaptiveNavigationShell> {
  final _bucket = PageStorageBucket();
  final _pageForegrounds = <int, (Object, Color?)>{};
  void _reportForeground(int index, Object owner, Color? color) {
    if (!mounted) return;
    final previous = _pageForegrounds[index]?.$2;
    _pageForegrounds[index] = (owner, color);
    if (previous != color && index == widget.selectedIndex) setState(() {});
  }

  void _clearForeground(int index, Object owner) {
    if (!mounted || !identical(_pageForegrounds[index]?.$1, owner)) return;
    final previous = _pageForegrounds.remove(index)?.$2;
    if (previous != null && index == widget.selectedIndex) setState(() {});
  }

  double _iosBarHeight = 83;
  late final Set<int> _visited = {widget.selectedIndex};
  @override
  void didUpdateWidget(AdaptiveNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    final ios = platform.PlatformInfo.isIOS;
    final nativeGlass =
        AdaptiveUIScope.supportsNativeGlass(context) &&
        !(AdaptiveUIScope.maybeOf(context)?.useOriginalComponents ?? true);
    final height = ios
        ? (platform.PlatformInfo.isIOS26OrHigher() ? _iosBarHeight : 50.0) +
              24.0
        : nativeGlass
        ? (isHarmonyOS ? HdsNavigation.heightOf(context) + 2 : 56.0)
        : 64.0;
    final onTop = ModalRoute.isCurrentOf(context) ?? true;
    return PopScope(
      canPop: widget.selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onSelected(0);
      },
      child: AdaptiveNavigationScope(
        barHeight: height,
        onSelect: widget.onSelected,
        child: PageStorage(
          bucket: _bucket,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IndexedStack(
                index: widget.selectedIndex,
                children: List.generate(
                  widget.pages.length,
                  (index) => Visibility(
                    visible: widget.selectedIndex == index,
                    maintainState: true,
                    child: _visited.contains(index)
                        ? _NavigationPageAppearanceScope(
                            report: (owner, color) =>
                                _reportForeground(index, owner, color),
                            clear: (owner) => _clearForeground(index, owner),
                            child: widget.pages[index],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Visibility(
                  visible:
                      onTop && MediaQuery.viewInsetsOf(context).bottom == 0,
                  maintainState: true,
                  child: _AdaptiveNavigationBar(
                    items: widget.items,
                    selectedIndex: widget.selectedIndex,
                    onSelected: widget.onSelected,
                    nativeGlass: nativeGlass,
                    contentForeground:
                        _pageForegrounds[widget.selectedIndex]?.$2,
                    onNativeHeightChanged: (height) {
                      if (mounted && (_iosBarHeight - height).abs() > .5) {
                        setState(() => _iosBarHeight = height);
                      }
                    },
                    hidden:
                        !onTop || MediaQuery.viewInsetsOf(context).bottom > 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveNavigationBar extends StatelessWidget {
  const _AdaptiveNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.nativeGlass,
    required this.onNativeHeightChanged,
    this.hidden = false,
    this.contentForeground,
  });
  final List<AdaptiveNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool nativeGlass, hidden;
  final Color? contentForeground;
  final ValueChanged<double> onNativeHeightChanged;
  @override
  Widget build(BuildContext context) {
    final foreground = contentForeground;
    final theme = Theme.of(context);
    if (platform.PlatformInfo.isIOS) return _buildBar(context);
    var effective = theme;
    if (foreground != null) {
      final brightness = foreground.computeLuminance() > .5
          ? Brightness.dark
          : Brightness.light;
      if (theme.brightness != brightness) {
        final source = DeadlinerColorTheme.of(theme);
        final palette = DeadlinerColorTheme.fromSeed(
          seed: source.seed,
          brightness: brightness,
          useMonet: source.useMonet,
        );
        effective = theme.copyWith(
          brightness: brightness,
          colorScheme: palette.material,
          extensions: [
            ...theme.extensions.values.where(
              (extension) => extension is! DeadlinerColorTheme,
            ),
            palette,
          ],
        );
      }
    }
    // Keep the native owner and gesture state mounted across color changes.
    return Theme(
      data: effective,
      child: Builder(builder: _buildBar),
    );
  }

  Widget _buildBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Outside Scaffold.bottomNavigationBar, NavigationBar would otherwise
    // consume the screen's status-bar padding as an extra blank top band.
    Widget material() => MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: NavigationBar(
        height: 64,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
    if (platform.PlatformInfo.isIOS) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: platform.PlatformInfo.isIOS26OrHigher()
              ? platform.IOS26NativeTabBar(
                  onHeightChanged: onNativeHeightChanged,
                  hidden: hidden,
                  selectedIndex: selectedIndex,
                  onTap: onSelected,
                  tint: scheme.primary,
                  destinations: [
                    for (final item in items)
                      platform.AdaptiveNavigationDestination(
                        icon: item.iosSymbol,
                        selectedIcon: item.iosSelectedSymbol,
                        label: item.label,
                      ),
                  ],
                )
              : CupertinoTabBar(
                  currentIndex: selectedIndex,
                  onTap: onSelected,
                  activeColor: scheme.primary,
                  items: [
                    for (final item in items)
                      BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                  ],
                ),
        ),
      );
    }
    if (!nativeGlass) return material();
    if (isHarmonyOS) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: SizedBox(
                width: math.min(
                  math.max(0, constraints.maxWidth - 32),
                  math.min(380, items.length * 80),
                ),
                height: HdsNavigation.heightOf(context),
                child: HdsNavigation(
                  visible: !hidden,
                  items: [
                    for (final item in items)
                      {'label': item.label, 'icon': item.androidIcon},
                  ],
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  fallback: material(),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math
                .min(
                  math.max(0, constraints.maxWidth - 32),
                  math.min(380, items.length * 80),
                )
                .toDouble();
            return Center(
              child: SizedBox(
                width: width,
                height: 54,
                child: ComposeNavigation(
                  visible: !hidden,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                  fallback: material(),
                  items: [
                    for (final item in items)
                      {'label': item.label, 'icon': item.androidIcon},
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
