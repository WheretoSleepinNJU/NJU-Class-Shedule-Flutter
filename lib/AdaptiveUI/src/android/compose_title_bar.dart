import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The framework owns page registration; this backend owns the Compose bridge.
AndroidToolbarBackend createComposeTitleBarBackend() {
  final height = ValueNotifier<double>(52);
  return AndroidToolbarBackend(
    height: height,
    supports: (bar) =>
        bar.appBar == null &&
        bar.leading == null &&
        bar.titleWidget == null &&
        (bar.actions ?? const []).every(
          (action) =>
              !action.hasMenu &&
              action.iconWidget == null &&
              (action.title == null &&
                  action.icon?.fontFamily == 'MaterialIcons' &&
                  action.icon?.fontPackage == null),
        ),
    builder: (context, registry) => ComposeTitleBarHost(
      registry: registry,
      onHeight: (value) => height.value = value,
    ),
  );
}

class ComposeTitleBarHost extends StatefulWidget {
  const ComposeTitleBarHost({
    super.key,
    required this.registry,
    required this.onHeight,
  });
  final ToolbarRegistry registry;
  final ValueChanged<double> onHeight;
  @override
  State<ComposeTitleBarHost> createState() => _ComposeTitleBarHostState();
}

class _ComposeTitleBarHostState extends State<ComposeTitleBarHost>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('nju/compose-titlebar');
  ToolbarEntry? _entry;
  final Set<Animation<double>> _animations = {};
  int _owner = 0;
  String? _lastState;
  bool _resumed = true, _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    widget.registry.addListener(_scheduleSync);
    _channel.setMethodCallHandler(_onNativeCall);
  }

  Future<void> _onNativeCall(MethodCall call) async {
    if (!mounted) return;
    final data = call.arguments is Map ? call.arguments as Map : const {};
    if (call.method == 'metrics') {
      if (data['owner'] != _owner) return;
      final height = (data['height'] as num?)?.toDouble();
      if (height != null && height.isFinite && height >= 48 && height <= 240) {
        widget.onHeight(height);
      }
      return;
    }
    final entry = _entry;
    if (entry == null ||
        !entry.isActive ||
        data['owner'] != _owner ||
        !_interactive(entry)) {
      return;
    }
    if (call.method == 'back') {
      await entry.navigator?.maybePop();
    } else if (call.method == 'action') {
      final index = data['index'];
      final actions = entry.appBar?.actions ?? const <AdaptiveAppBarAction>[];
      if (index is int && index >= 0 && index < actions.length) {
        actions[index].onPressed();
      }
    }
  }

  bool _interactive(ToolbarEntry entry) =>
      (entry.route?.animation?.status ?? AnimationStatus.completed) ==
          AnimationStatus.completed &&
      (entry.route?.secondaryAnimation?.status ?? AnimationStatus.dismissed) ==
          AnimationStatus.dismissed &&
      !(entry.navigator?.userGestureInProgress ?? false);

  void _watch(ToolbarEntry? next) {
    if (_entry?.id == next?.id) {
      _entry = next;
      return;
    }
    for (final animation in _animations) {
      animation.removeStatusListener(_statusChanged);
    }
    _animations.clear();
    _entry = next;
    _owner++;
    if (next != null) {
      for (final route in [next.route, ...next.enclosingRoutes]) {
        if (route?.animation != null) {
          _animations.add(route!.animation!);
        }
        if (route?.secondaryAnimation != null) {
          _animations.add(route!.secondaryAnimation!);
        }
      }
      for (final animation in _animations) {
        animation.addStatusListener(_statusChanged);
      }
    }
  }

  void _statusChanged(AnimationStatus _) => _scheduleSync();
  void _scheduleSync() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) unawaited(_sync());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final candidate = widget.registry.active;
    _watch(candidate?.androidNativeToolbar == true ? candidate : null);
    final entry = _entry;
    final visible = entry != null && _resumed;
    final colors = Theme.of(context).colorScheme;
    final actions = entry?.appBar?.actions ?? const <AdaptiveAppBarAction>[];
    final state = <String, Object?>{
      'visible': visible,
      'owner': _owner,
      'title': entry?.appBar?.title ?? '',
      'subtitle': entry?.appBar?.subtitle ?? '',
      'canBack':
          entry != null &&
          !entry.hasTabBar &&
          (entry.navigator?.canPop() ?? false),
      'interactive': entry != null && _interactive(entry),
      'backLabel': MaterialLocalizations.of(context).backButtonTooltip,
      'scrollOffset': entry?.scrollOffset ?? 0,
      'dark': Theme.of(context).brightness == Brightness.dark,
      'primary': colors.primary.toARGB32(),
      'surface': colors.surface.toARGB32(),
      'onSurface': colors.onSurface.toARGB32(),
      'fontScale': MediaQuery.textScalerOf(context).scale(16) / 16,
      'rtl': Directionality.of(context) == TextDirection.rtl,
      'actions': [
        for (var i = 0; i < actions.length; i++)
          {
            'index': i,
            'label':
                actions[i].effectiveLabel ?? actions[i].title ?? '操作 ${i + 1}',
            'title': actions[i].title,
            'codePoint': actions[i].icon?.codePoint,
            'mirror': actions[i].icon?.matchTextDirection ?? false,
          },
      ],
    };
    final signature = state.toString();
    if (signature == _lastState) return;
    _lastState = signature;
    try {
      await _channel.invokeMethod<void>('update', state);
    } on PlatformException {
      _lastState = null;
    } on MissingPluginException {
      _lastState = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleSync();
  }

  @override
  void didUpdateWidget(ComposeTitleBarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.registry != oldWidget.registry) {
      oldWidget.registry.removeListener(_scheduleSync);
      widget.registry.addListener(_scheduleSync);
      _watch(null);
    }
    _scheduleSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _scheduleSync();
  }

  @override
  void dispose() {
    widget.registry.removeListener(_scheduleSync);
    for (final animation in _animations) {
      animation.removeStatusListener(_statusChanged);
    }
    WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    unawaited(_channel.invokeMethod<void>('hide').catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleSync();
    return const SizedBox.shrink();
  }
}
