import 'dart:math' as math;

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
  final int courseCount;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;

  const CourseWidget(
    this.course,
    this.color,
    this.height,
    this.width,
    this.isActive,
    this.courseCount,
    this.onTap,
    this.onLongPress, {
    Key? key,
  }) : assert(courseCount > 0),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: (course.startTime! - 1) * height,
        left: (course.weekTime! - 1) * width,
      ),
      padding: const EdgeInsets.all(0.5),
      height: (course.timeCount! + 1) * height,
      width: width,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: HexColor(
            isActive ? color : Config.HIDE_CLASS_COLOR,
          ).withOpacity(0.9),
          borderRadius: const BorderRadius.all(Radius.circular(7)),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          highlightColor: Colors.black,
          onLongPress: onLongPress,
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScaler = MediaQuery.textScalerOf(context);
              final lineHeight = textScaler.scale(12) * 1.2;
              const contentPadding = EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              );
              final badgeSize = math.min(
                textScaler.scale(8).clamp(8.0, 10.0) + 4,
                math.min(constraints.maxWidth, constraints.maxHeight) - 4,
              );
              final content = Padding(
                padding: contentPadding,
                child: RichText(
                  textScaler: textScaler,
                  maxLines: math.max(
                    1,
                    ((constraints.maxHeight - contentPadding.vertical) /
                            lineHeight)
                        .floor(),
                  ),
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12.0,
                      height: 1.2,
                      color: Colors.white,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            (isActive ? '' : S.of(context).not_this_week) +
                            course.name!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            S.of(context).at +
                            (course.classroom ?? S.of(context).unknown_place),
                      ),
                    ],
                  ),
                ),
              );
              if (courseCount == 1) return content;
              return Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: badgeSize,
                        height: badgeSize,
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$courseCount',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: textScaler.scale(8).clamp(8.0, 10.0),
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
