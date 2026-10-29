import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'theme/deadliner_color_theme.dart';

/// Native chrome lives beside Flutter. Flutter only publishes
/// geometry and accessibility; ready native chrome receives physical gestures.
class NativeNavigation extends StatefulWidget {
  const NativeNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.visible,
    required this.onSelected,
    required this.fallback,
    required this.channelName,
    this.jsonTransport = false,
    this.nativeOwnsAccessibility = false,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 3,
    ),
  });
  final List<Map<String, String>> items;
  final String channelName;
  final bool jsonTransport;
  final bool nativeOwnsAccessibility;
  final EdgeInsets contentPadding;
  final int selectedIndex;
  final bool visible;
  final ValueChanged<int> onSelected;
  final Widget fallback;
  @override
  State<NativeNavigation> createState() => _NativeNavigationState();
}

class _NativeNavigationState extends State<NativeNavigation>
    with WidgetsBindingObserver {
  late final channel = MethodChannel(widget.channelName);
  static int _nextOwner = 0;
  static final _handlerOwners = <String, _NativeNavigationState>{};
  late final int _owner = ++_nextOwner;
  final _boundsKey = GlobalKey();
  final _routeAnimations = <Animation<double>>{};
  String? _last;
  bool _scheduled = false, _failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handlerOwners[widget.channelName] = this;
    channel.setMethodCallHandler((call) async {
      if (!mounted ||
          !widget.visible ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      final data = call.arguments as Map?;
      if (call.method == 'select' && data?['owner'] == _owner) {
        final index = data?['index'];
        if (index is int && index >= 0 && index < widget.items.length) {
          widget.onSelected(index);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final animations = <Animation<double>>{
      if (route?.animation != null) route!.animation!,
      if (route?.secondaryAnimation != null) route!.secondaryAnimation!,
    };
    for (final animation in _routeAnimations.difference(animations)) {
      animation.removeListener(_onRouteTick);
    }
    for (final animation in animations.difference(_routeAnimations)) {
      animation.addListener(_onRouteTick);
    }
    _routeAnimations
      ..clear()
      ..addAll(animations);
    _schedule();
  }

  void _onRouteTick() {
    if (widget.visible) _schedule();
  }

  @override
  void didUpdateWidget(NativeNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void didChangeMetrics() => _schedule();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _last = null;
      _schedule();
    }
  }

  void _schedule() {
    if (_scheduled || !mounted || _failed) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || _failed) return;
      _sync();
    });
  }

  Future<void> _sync() async {
    final box = _boundsKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final bounds = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    final theme = Theme.of(context);
    final data = <String, Object?>{
      'owner': _owner,
      'visible': widget.visible,
      'left': bounds.left,
      'top': bounds.top,
      'width': bounds.width,
      'height': bounds.height,
      'selectedIndex': widget.selectedIndex,
      'items': widget.items,
      'dark': theme.brightness == Brightness.dark,
      'rtl': Directionality.of(context) == TextDirection.rtl,
      // JSON endpoints also accept flat semantic colors. Preserve the existing
      // Compose palette contract during the shared-transport migration.
      if (widget.jsonTransport) 'primary': theme.colorScheme.primary.toARGB32(),
      if (widget.jsonTransport)
        'onSurface': theme.colorScheme.onSurface.toARGB32(),
      'fontScale': MediaQuery.textScalerOf(context).scale(16) / 16,
      ...DeadlinerColorTheme.of(theme).toNativeMap(),
    };
    final signature = jsonEncode(data);
    if (_last == signature) return;
    _last = signature;
    try {
      await channel.invokeMethod<void>(
        'update',
        widget.jsonTransport ? {'json': signature} : data,
      );
    } on PlatformException {
      _fail();
    } on MissingPluginException {
      _fail();
    }
  }

  void _fail() {
    channel
        .invokeMethod<void>('hide', {'owner': _owner})
        .catchError((Object _) {});
    if (mounted && !_failed) setState(() => _failed = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final animation in _routeAnimations) {
      animation.removeListener(_onRouteTick);
    }
    if (identical(_handlerOwners[widget.channelName], this)) {
      _handlerOwners.remove(widget.channelName);
      channel.setMethodCallHandler(null);
    }
    channel
        .invokeMethod<void>('hide', {'owner': _owner})
        .catchError((Object _) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    return _NavigationBounds(
      key: _boundsKey,
      onPaint: _schedule,
      child: Padding(
        padding: widget.contentPadding,
        child: ExcludeSemantics(
          excluding: widget.nativeOwnsAccessibility,
          child: AbsorbPointer(
            absorbing: widget.nativeOwnsAccessibility,
            child: Row(
              children: List.generate(
                widget.items.length,
                (index) => Expanded(
                  child: Semantics(
                    container: true,
                    button: true,
                    selected: widget.selectedIndex == index,
                    label: widget.items[index]['label'],
                    onTap: widget.visible
                        ? () => widget.onSelected(index)
                        : null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onTap: widget.visible
                          ? () => widget.onSelected(index)
                          : null,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationBounds extends SingleChildRenderObjectWidget {
  const _NavigationBounds({
    super.key,
    required this.onPaint,
    required super.child,
  });
  final VoidCallback onPaint;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _NavigationBoundsRender(onPaint);
  @override
  void updateRenderObject(
    BuildContext context,
    _NavigationBoundsRender renderObject,
  ) => renderObject.onPaint = onPaint;
}

class _NavigationBoundsRender extends RenderProxyBox {
  _NavigationBoundsRender(this.onPaint);
  VoidCallback onPaint;
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    onPaint();
  }
}
