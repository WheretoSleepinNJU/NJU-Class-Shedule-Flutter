import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import '../native_toolbar_host.dart';

/// The framework owns page registration; this backend owns the Compose bridge.
NativeToolbarBackend createComposeTitleBarBackend() {
  final height = ValueNotifier<double>(52);
  return NativeToolbarBackend(
    height: height,
    supports: (bar) =>
        bar.appBar == null &&
        bar.leading == null &&
        bar.titleWidget == null &&
        (bar.actions ?? const []).every(
          (action) =>
              !action.hasMenu &&
              action.iconWidget == null &&
              (action.title != null ||
                  (action.icon?.fontFamily == 'MaterialIcons' &&
                      action.icon?.fontPackage == null)),
        ),
    builder: (context, registry) => NativeToolbarHost(
      registry: registry,
      channelName: 'nju/compose-titlebar',
      onHeight: (value) => height.value = value,
    ),
  );
}
