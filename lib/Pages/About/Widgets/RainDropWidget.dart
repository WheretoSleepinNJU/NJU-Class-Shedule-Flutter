import 'package:flutter/material.dart';
import '../../../Resources/Colors.dart';
import '../../../Utils/ColorUtil.dart';
import 'dart:async';
import 'dart:math';

class RainDropWidget extends StatefulWidget {
  const RainDropWidget({Key? key, this.width = 300, this.height = 300})
      : super(key: key);

  final double width;
  final double height;

  @override
  //TODO: needs to be fixed
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => RainDropState(width, height);
}

class RainDropState extends State<RainDropWidget>
    with TickerProviderStateMixin {
  List<RainDropDrawer>? _rainList;
  AnimationController? _animation;
  double _width = 300;

  double _height = 300;
  Timer? _timer;

  RainDropState(double width, double height) {
    _width = width;
    _height = height;
  }

  @override
  void initState() {
    super.initState();
    _rainList = [];
    _animation = AnimationController(
        // 因为是repeat的，这里的duration其实不care
        duration: const Duration(milliseconds: 200),
        vsync: this)
      ..addListener(() {
        if (_rainList!.isEmpty) {
          _animation!.stop();
        }
        setState(() {});
      });
    Random random = Random();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // print('Rain drop.');
      var rainDrop = RainDropDrawer(
          random.nextDouble() * _width,
          random.nextDouble() * _height,
          colorList[random.nextInt(colorList.length)]);
      _rainList!.add(rainDrop);
      _animation!.repeat();
    });
  }

  @override
  void dispose() {
    _timer!.cancel();
    _animation!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: CustomPaint(
        painter: RainDrop(_rainList!),
      ),
    );
  }
}

class RainDrop extends CustomPainter {
  RainDrop(this.rainList);

  List<RainDropDrawer> rainList = [];
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in rainList) {
      item.drawRainDrop(canvas, _paint);
    }
    rainList.removeWhere((item) {
      return !item.isValid();
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class RainDropDrawer {
  static const double MAX_RADIUS = 100;
  double posX;
  double posY;
  double radius = 5;
  String color;

  RainDropDrawer(this.posX, this.posY, this.color);

  drawRainDrop(Canvas canvas, Paint paint) {
    double opt = (MAX_RADIUS - radius) / MAX_RADIUS;
//    paint.color = Color.fromRGBO(0, 0, 0, opt);
    paint.color = HexColor(color).withOpacity(opt);
    canvas.drawCircle(Offset(posX, posY), radius, paint);
    radius += 0.5;
  }

  bool isValid() {
    return radius < MAX_RADIUS;
  }
}
