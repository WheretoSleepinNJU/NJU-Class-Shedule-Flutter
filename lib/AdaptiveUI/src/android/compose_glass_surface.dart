import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../theme/deadliner_color_theme.dart';

/// HC separates the GPU page background from Flutter foreground widgets.
/// Only the primary FlutterImageView is sampled by the native shared recorder.
class ComposeGlassSurface extends StatefulWidget {
  const ComposeGlassSurface({
    super.key,
    required this.kind,
    required this.fallback,
    this.properties = const {},
    this.onPressed,
  });
  final String kind;
  final Widget fallback;
  final Map<String, Object?> properties;
  final VoidCallback? onPressed;
  @override
  State<ComposeGlassSurface> createState() => _ComposeGlassSurfaceState();
}

class _ComposeGlassSurfaceState extends State<ComposeGlassSurface> {
  static const _viewType = 'nju/deadliner-glass-surface';
  MethodChannel? _channel;
  bool _failed = false;
  Map<String, Object?> get _configuration {
    final theme = Theme.of(context);
    return {
      'kind': widget.kind,
      'dark': theme.brightness == Brightness.dark,
      'primary': theme.colorScheme.primary.toARGB32(),
      'surface': theme.colorScheme.surface.toARGB32(),
      'onSurface': theme.colorScheme.onSurface.toARGB32(),
      ...DeadlinerColorTheme.of(Theme.of(context)).toNativeMap(),
      'rtl': Directionality.of(context) == TextDirection.rtl,
      'fontScale': MediaQuery.textScalerOf(context).scale(16) / 16,
      ...widget.properties,
    };
  }

  void _update() => _channel
      ?.invokeMethod<void>('update', _configuration)
      .catchError((Object _) => _fail());
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(ComposeGlassSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _fail() {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    final interactive = widget.onPressed != null;
    return ExcludeSemantics(
      child: PlatformViewLink(
        viewType: _viewType,
        surfaceFactory: (context, controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: interactive
              ? {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                }
              : const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: interactive
              ? PlatformViewHitTestBehavior.opaque
              : PlatformViewHitTestBehavior.transparent,
        ),
        onCreatePlatformView: (params) {
          _channel = MethodChannel('nju/glass-surface/${params.id}')
            ..setMethodCallHandler((call) async {
              if (!mounted) return;
              if (call.method == 'press') widget.onPressed?.call();
            });
          final controller = PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: _viewType,
            layoutDirection: Directionality.of(context),
            creationParams: _configuration,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          )..addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
          controller.create().catchError((Object _) => _fail());
          return controller;
        },
      ),
    );
  }
}
