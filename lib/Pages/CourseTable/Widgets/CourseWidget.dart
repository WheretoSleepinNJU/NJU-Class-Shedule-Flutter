import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Config.dart';
import '../../../Utils/ColorUtil.dart';

class CourseWidget extends StatelessWidget {
  final Course course;
  final String color;
  final double height;
  final double width;
  final bool isActive;
  final bool setFlag;
  final onTap;
  final onLongPress;

  const CourseWidget(this.course, this.color, this.height, this.width,
      this.isActive, this.setFlag, this.onTap, this.onLongPress,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          top: (course.startTime! - 1) * height,
          left: (course.weekTime! - 1) * width),
      padding: const EdgeInsets.all(0.5),
      height: (course.timeCount! + 1) * height,
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: HexColor(isActive ? color : Config.HIDE_CLASS_COLOR)
              .withOpacity(0.9),
          // TODO: Needs to be improved
          borderRadius: setFlag
              ? const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7))
              : const BorderRadius.all(Radius.circular(7)),
//          boxShadow: setFlag? [BoxShadow(color: HexColor(Config.HIDE_CLASS_COLOR), offset: Offset(2.0, 2.0))]:[]
        ),
        child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            highlightColor: Colors.black,
            onLongPress: onLongPress,
            onTap: onTap,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.white,
                ),
                children: <TextSpan>[
                  TextSpan(
                      text: (isActive ? '' : S.of(context).not_this_week) +
                          course.name!,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: S.of(context).at +
                          (course.classroom ?? S.of(context).unknown_place)),
                ],
              ),
            )
//          Text(
//              (isActive ? '' : S.of(context).not_this_week) +
//                  course.name +
//                  S.of(context).at +
//                  (course.classroom ?? S.of(context).unknown_place),
//              style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
      ),
    );
  }
}
