import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'adaptive_ui_controller.dart';
import 'adaptive_miuix_theme.dart';
import 'android/compose_title_bar.dart';
import 'ohos/hds_chrome.dart';

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
  late final _toolbar = isHarmonyOS
      ? createHdsToolbarBackend(
          onUnavailable: () {
            if (mounted) setState(() => _nativeSupported = false);
          },
        )
      : createComposeTitleBarBackend();
  static const _hdsChannel = MethodChannel('nju/hds-chrome');
  final _hdsInsets = ValueNotifier<EdgeInsets>(EdgeInsets.zero);
  bool _nativeSupported = false;
  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller.restore().catchError((Object _) {});
    }
    if (isHarmonyOS) {
      _hdsChannel.setMethodCallHandler((call) async {
        if (call.method == 'insets' && call.arguments is Map) {
          _receiveHdsInsets(call.arguments as Map);
        }
      });
      _hdsChannel
          .invokeMapMethod<String, Object?>('capabilities')
          .then((capabilities) {
            if (mounted) {
              if (capabilities != null) _receiveHdsInsets(capabilities);
              setState(
                () => _nativeSupported =
                    capabilities?['protocolVersion'] == 1 &&
                    capabilities?['supported'] == true,
              );
            }
          })
          .catchError((Object _) {});
    } else if (!kIsWeb && Platform.isAndroid) {
      const MethodChannel('nju/compose-support')
          .invokeMethod<bool>('supportsTitleBar')
          .then((supported) {
            if (mounted) setState(() => _nativeSupported = supported == true);
          })
          .catchError((Object _) {});
    }
  }

  void _receiveHdsInsets(Map data) {
    if (!mounted) return;
    final top = data['topInset'], bottom = data['bottomInset'];
    if (top is! num ||
        bottom is! num ||
        !top.isFinite ||
        !bottom.isFinite ||
        top < 0 ||
        bottom < 0 ||
        top > 512 ||
        bottom > 512) {
      return;
    }
    _hdsInsets.value = EdgeInsets.only(
      top: top.toDouble(),
      bottom: bottom.toDouble(),
    );
  }

  @override
  void dispose() {
    if (isHarmonyOS) _hdsChannel.setMethodCallHandler(null);
    _hdsInsets.dispose();
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
          final themed = AdaptiveMiuixTheme(child: contents);
          if (!isHarmonyOS) return themed;
          return ValueListenableBuilder<EdgeInsets>(
            valueListenable: _hdsInsets,
            child: themed,
            builder: (context, insets, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  viewPadding: media.viewPadding.copyWith(
                    top: math.max(media.viewPadding.top, insets.top),
                    bottom: math.max(media.viewPadding.bottom, insets.bottom),
                  ),
                  padding: media.padding.copyWith(
                    top: math.max(media.padding.top, insets.top),
                    bottom: media.viewInsets.bottom > 0
                        ? media.padding.bottom
                        : math.max(media.padding.bottom, insets.bottom),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    ),
  );
}
