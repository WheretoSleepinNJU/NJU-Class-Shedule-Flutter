import '../../../generated/i18n.dart';
import 'package:flutter/material.dart';
import '../../../Models/CourseModel.dart';
import '../../../Utils/ColorUtil.dart';

class CourseWidget extends StatelessWidget {
  final Course course;
  final String color;
  final double height;
  final double width;
  final String preText;
  final onTap;
  final onLongPress;

  CourseWidget(this.course, this.color, this.height, this.width, this.onTap,
      this.onLongPress,
      {this.preText = null});

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: EdgeInsets.only(
          top: (course.startTime - 1) * height,
          left: (course.weekTime - 1) * width),
      padding: EdgeInsets.all(0.5),
      height: (course.timeCount + 1) * height,
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: HexColor(color).withOpacity(0.9),
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          highlightColor: Colors.black,
          onLongPress: onLongPress,
          onTap: onTap,
          child: Text(
              (preText ?? '') +
                  course.name +
                  S.of(context).at +
                  (course.classroom ?? S.of(context).unknown_place),
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
