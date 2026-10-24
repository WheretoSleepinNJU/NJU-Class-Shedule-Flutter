import 'dart:convert';
import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../Components/Dialog.dart';
import '../../../Components/Toast.dart';

class CourseDetailDialog extends StatelessWidget {
  final VoidCallback? onPressed;
  final Course course;
  final bool isActive;

  const CourseDetailDialog(
    this.course,
    this.isActive,
    this.onPressed, {
    Key? key,
  }) : super(key: key);

  String _getWeekListString(BuildContext context) {
    bool flag = true;
    List weekList = json.decode(course.weeks!);
    if (weekList.length == 1) return S.of(context).week(weekList[0]);
    String base = S
        .of(context)
        .week_duration(
          weekList[0].toString(),
          weekList[weekList.length - 1].toString(),
        );
    for (int i = 1; i < weekList.length; i++) {
      if (weekList[i] - weekList[0] != i) {
        flag = false;
        break;
      }
    }
    if (flag) return base;
    flag = true;
    for (int i = 1; i < weekList.length; i++) {
      if (weekList[i] - weekList[0] != 2 * i) {
        flag = false;
        break;
      }
    }
    if (flag) {
      if (weekList[0] % 2 == 0) {
        return base + " " + S.of(context).double_week;
      } else {
        return base + " " + S.of(context).single_week;
      }
    } else {
      return course.weeks!;
    }
  }

  Widget linkifyText(BuildContext context, String text) {
    return SelectableLinkify(
      onOpen: (link) async {
        String url = link.url.replaceAll(RegExp('[^\x00-\xff]'), '');
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          Toast.showToast(S.of(context).network_error_toast, context);
        }
      },
      text: text,
      // flutter_linkify defaults to 1.0 instead of inheriting MediaQuery.
      textScaleFactor: MediaQuery.textScalerOf(context).scale(16) / 16,
      style: const TextStyle(fontSize: 16, height: 1.4),
      linkStyle: TextStyle(
        color:
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).primaryColor
                : Colors.white,
      ),
      options: const LinkifyOptions(humanize: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    String weekString =
        Constant.WEEK_WITH_BIAS[course.weekTime!] +
        ' ' +
        S
            .of(context)
            .class_duration(
              course.startTime.toString(),
              (course.startTime! + course.timeCount!).toString(),
            );
    if (course.startTime == 0 && course.timeCount == 0) {
      weekString = S.of(context).free_time;
    }

    String weekListString = _getWeekListString(context);

    String importTypeStr = '';
    switch (course.importType) {
      case Constant.ADD_BY_IMPORT:
        importTypeStr = S.of(context).import_auto;
        break;
      case Constant.ADD_MANUALLY:
        importTypeStr = S.of(context).import_manually;
        break;
      case Constant.ADD_BY_LECTURE:
        importTypeStr = S.of(context).import_from_lecture;
        break;
    }

    return MDialog(
      (isActive ? '' : S.of(context).not_this_week) + course.name!,
      Builder(
        builder: (dialogContext) {
          Widget detailRow(IconData icon, String text) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(icon, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(child: linkifyText(dialogContext, text)),
              ],
            ),
          );
          final teacher = course.teacher?.trim() ?? '';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              detailRow(
                Icons.location_on,
                (course.classroom?.isEmpty ?? true)
                    ? S.of(context).unknown_place
                    : course.classroom!,
              ),
              if (teacher.isNotEmpty) detailRow(Icons.account_circle, teacher),
              detailRow(Icons.access_time, weekString),
              detailRow(Icons.event, weekListString),
              detailRow(Icons.settings_suggest, importTypeStr),
              detailRow(
                Icons.description,
                (course.info?.isEmpty ?? true)
                    ? S.of(context).unknown_info
                    : course.info!,
              ),
            ],
          );
        },
      ),
      widgetOKAction: onPressed,
    );
  }
}
