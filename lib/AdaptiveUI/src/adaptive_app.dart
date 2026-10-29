import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'adaptive_ui_controller.dart';
import 'adaptive_miuix_theme.dart';
import 'android/compose_title_bar.dart';

class AdaptiveUIApp extends StatefulWidget {
  const AdaptiveUIApp({
    super.key,
    required this.home,
    this.controller,
    this.navigatorKey,
    this.title = '',
    this.onGenerateTitle,
    this.materialLightTheme,
    this.materialDarkTheme,
    this.themeMode = ThemeMode.system,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en', 'US')],
    this.builder,
  });
  final Widget home;
  final AdaptiveUIController? controller;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final ThemeData? materialLightTheme, materialDarkTheme;
  final ThemeMode themeMode;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final Iterable<Locale> supportedLocales;
  final TransitionBuilder? builder;

  static Future<void> initializeSystemChrome() async {
    if (kIsWeb || !Platform.isAndroid) return;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  State<AdaptiveUIApp> createState() => _AdaptiveUIAppState();
}

class _AdaptiveUIAppState extends State<AdaptiveUIApp> {
  late final _controller = widget.controller ?? AdaptiveUIController();
  final _toolbar = createComposeTitleBarBackend();
  bool _nativeSupported = false;
  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller.restore().catchError((Object _) {});
    }
    if (!kIsWeb && Platform.isAndroid) {
      const MethodChannel('nju/compose-support')
          .invokeMethod<bool>('supportsTitleBar')
          .then((supported) {
            if (mounted) setState(() => _nativeSupported = supported == true);
          })
          .catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => AdaptiveUIScope(
      controller: _controller,
      nativeGlassSupported: _nativeSupported,
      child: platform.AdaptiveApp(
        navigatorKey: widget.navigatorKey,
        nativeToolbarBackend:
            _nativeSupported && !_controller.useOriginalComponents
            ? _toolbar
            : null,
        title: widget.title,
        onGenerateTitle: widget.onGenerateTitle,
        materialLightTheme: widget.materialLightTheme,
        materialDarkTheme: widget.materialDarkTheme,
        themeMode: widget.themeMode,
        localizationsDelegates: widget.localizationsDelegates,
        supportedLocales: widget.supportedLocales,
        home: widget.home,
        builder: (context, child) {
          final dark =
              widget.themeMode == ThemeMode.dark ||
              (widget.themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          final contents = widget.builder?.call(context, child) ?? child!;
          // Material form content remains valid beneath the Cupertino app root.
          if (platform.PlatformInfo.isIOS) {
            return Theme(
              data:
                  (dark
                      ? widget.materialDarkTheme
                      : widget.materialLightTheme) ??
                  ThemeData(
                    brightness: dark ? Brightness.dark : Brightness.light,
                  ),
              child: ScaffoldMessenger(
                child: AdaptiveMiuixTheme(child: contents),
              ),
            );
          }
          return AdaptiveMiuixTheme(child: contents);
        },
      ),
    ),
  );
}
