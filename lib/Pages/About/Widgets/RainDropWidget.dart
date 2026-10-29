import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../Resources/Colors.dart';
import '../../../Utils/ColorUtil.dart';

/// Original expanding colored rings, isolated to the paint layer. Timers and
/// tickers pause together while the route or application is not visible.
class RainDropWidget extends StatefulWidget {
  const RainDropWidget({super.key, this.width = 300, this.height = 300});
  final double width, height;
  @override
  State<RainDropWidget> createState() => _RainDropState();
}

class _RainDropState extends State<RainDropWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _drops = <_Drop>[];
  final _clock = Stopwatch();
  final _random = Random();
  late final AnimationController _animation;
  Timer? _timer;
  bool _visible = false, _running = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          _drops.removeWhere(
            (drop) => drop.radius(_clock.elapsedMilliseconds) >= 100,
          );
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        !MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();
  void _sync() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final next =
        _visible &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed);
    if (next == _running) return;
    _running = next;
    if (!next) {
      _timer?.cancel();
      _timer = null;
      _animation.stop();
      _clock.stop();
    } else {
      _clock.start();
      _spawn();
      _animation.repeat();
      _timer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _spawn(),
      );
    }
  }

  void _spawn() => _drops.add(
    _Drop(
      _random.nextDouble(),
      _random.nextDouble(),
      colorList[_random.nextInt(colorList.length)],
      _clock.elapsedMilliseconds,
    ),
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _animation.dispose();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: IgnorePointer(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _RainPainter(
            _drops,
            () => _clock.elapsedMilliseconds,
            _animation,
          ),
        ),
      ),
    ),
  );
}

class _Drop {
  const _Drop(this.x, this.y, this.color, this.birth);
  final double x, y;
  final String color;
  final int birth;
  double radius(int now) => 5 + (now - birth) * .03;
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.drops, this.elapsed, Listenable repaint)
    : super(repaint: repaint);
  final List<_Drop> drops;
  final int Function() elapsed;
  final _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  @override
  void paint(Canvas canvas, Size size) {
    final now = elapsed();
    for (final drop in drops) {
      final radius = drop.radius(now);
      if (radius >= 100) continue;
      _paint.color = HexColor(
        drop.color,
      ).withValues(alpha: ((100 - radius) / 100).clamp(0, 1));
      canvas.drawCircle(
        Offset(drop.x * size.width, drop.y * size.height),
        radius,
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) =>
      !identical(drops, oldDelegate.drops);
}
