import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../widgets/adaptive_app_bar.dart';
import 'toolbar_registry.dart';

/// App-owned Android chrome installed once above the navigator.
/// Unsupported app bars keep the standard Material implementation.
class AndroidToolbarBackend {
  const AndroidToolbarBackend({
    required this.builder,
    required this.height,
    required this.supports,
  });
  final Widget Function(BuildContext context, ToolbarRegistry registry) builder;
  final ValueListenable<double> height;
  final bool Function(AdaptiveAppBar appBar) supports;
}

class AndroidToolbarScope extends InheritedWidget {
  const AndroidToolbarScope({
    super.key,
    required this.backend,
    required super.child,
  });
  final AndroidToolbarBackend? backend;
  static AndroidToolbarBackend? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AndroidToolbarScope>()
      ?.backend;
  @override
  bool updateShouldNotify(AndroidToolbarScope oldWidget) =>
      backend != oldWidget.backend;
}

/// Padding for scrollable content that extends behind native Android chrome.
/// Put this inside the scrollable's content padding, so it scrolls under the bar.
class AndroidToolbarBodyScope extends InheritedWidget {
  const AndroidToolbarBodyScope({
    super.key,
    required this.topInset,
    required super.child,
  });
  final double topInset;
  static double topInsetOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AndroidToolbarBodyScope>()
          ?.topInset ??
      0;
  @override
  bool updateShouldNotify(AndroidToolbarBodyScope oldWidget) =>
      topInset != oldWidget.topInset;
}
