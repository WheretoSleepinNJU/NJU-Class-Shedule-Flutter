import 'dart:io';
import 'dart:math' as math;
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../native_navigation.dart';
import '../native_toolbar_host.dart';

bool get isHarmonyOS => !kIsWeb && Platform.operatingSystem == 'ohos';

NativeToolbarBackend createHdsToolbarBackend({VoidCallback? onUnavailable}) {
  final height = ValueNotifier<double>(56);
  return NativeToolbarBackend(
    height: height,
    preferredToolbarHeight: 56,
    supports: (bar) =>
        bar.appBar == null &&
        bar.leading == null &&
        bar.titleWidget == null &&
        (bar.actions ?? const []).every(
          (action) => !action.hasMenu && action.iconWidget == null,
        ),
    builder: (context, registry) => NativeToolbarHost(
      registry: registry,
      onHeight: (value) => height.value = value,
      channelName: 'nju/hds-titlebar',
      onUnavailable: onUnavailable,
      jsonTransport: true,
    ),
  );
}

class HdsNavigation extends NativeNavigation {
  static double heightOf(BuildContext context) =>
      math.max(56, MediaQuery.textScalerOf(context).scale(12) + 34);
  const HdsNavigation({
    super.key,
    required super.items,
    required super.selectedIndex,
    required super.visible,
    required super.onSelected,
    required super.fallback,
  }) : super(
         channelName: 'nju/hds-navigation',
         jsonTransport: true,
         nativeOwnsAccessibility: true,
         contentPadding: EdgeInsets.zero,
       );
}
