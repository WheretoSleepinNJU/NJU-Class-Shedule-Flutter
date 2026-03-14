import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Config.dart';
import '../../../Resources/PrototypePalette.dart';
import '../../../Utils/ColorUtil.dart';

class CourseWidget extends StatelessWidget {
  final Course course;
  final String color;
  final double height;
  final double width;
  final bool isActive;
  final bool setFlag;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  const CourseWidget(this.course, this.color, this.height, this.width,
      this.isActive, this.setFlag, this.onTap, this.onLongPress,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        HexColor(isActive ? color : Config.HIDE_CLASS_COLOR).withValues(
      alpha: isActive ? 0.95 : 0.45,
    );
    return Container(
      margin: EdgeInsets.only(
          top: (course.startTime! - 1) * height,
          left: (course.weekTime! - 1) * width),
      padding: const EdgeInsets.all(2.5),
      height: (course.timeCount! + 1) * height,
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: setFlag
              ? const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18))
              : const BorderRadius.all(Radius.circular(18)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 1.1,
          ),
          boxShadow: DuckPalette.softShadow(0.05),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          highlightColor: Colors.transparent,
          onLongPress: onLongPress,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: RichText(
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 11.5,
                  color: DuckPalette.textMain,
                  height: 1.25,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: (isActive ? '' : S.of(context).not_this_week) +
                        course.name! +
                        '\n',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: course.classroom?.isNotEmpty == true
                        ? course.classroom
                        : S.of(context).unknown_place,
                    style: const TextStyle(
                      color: DuckPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
