import 'dart:convert';
import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../Resources/PrototypePalette.dart';
import '../../../Components/Dialog.dart';
import '../../../Components/Toast.dart';

class CourseDetailDialog extends StatelessWidget {
  final VoidCallback? onPressed;
  final Course course;
  final bool isActive;

  const CourseDetailDialog(this.course, this.isActive, this.onPressed,
      {Key? key})
      : super(key: key);

  String _getWeekListString(BuildContext context) {
    bool flag = true;
    List weekList = json.decode(course.weeks!);
    if (weekList.length == 1) return S.of(context).week(weekList[0]);
    String base = S.of(context).week_duration(
        weekList[0].toString(), weekList[weekList.length - 1].toString());
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

  Widget linkifyText(context, String text) {
    return SelectableLinkify(
      onOpen: (link) async {
        final String url = link.url.replaceAll(RegExp('[^\x00-\xff]'), '');
        final Uri? uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          Toast.showToast(S.of(context).network_error_toast, context);
        }
      },
      text: text,
      style: const TextStyle(fontSize: 16),
      linkStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700),
      options: const LinkifyOptions(humanize: false),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, Widget child,
      {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center}) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: DuckPalette.duckYellowSoft,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, size: 18, color: DuckPalette.textMain),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String weekString = Constant.WEEK_WITH_BIAS[course.weekTime!] +
        ' ' +
        S.of(context).class_duration(course.startTime.toString(),
            (course.startTime! + course.timeCount!).toString());
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
      SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _detailRow(
            context,
            Icons.location_on_rounded,
            linkifyText(
                context,
                course.classroom == ""
                    ? S.of(context).unknown_place
                    : course.classroom ?? S.of(context).unknown_place),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.person_rounded,
            linkifyText(context, course.teacher ?? ''),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.schedule_rounded,
            linkifyText(context, weekString),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.calendar_month_rounded,
            linkifyText(context, weekListString),
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.settings_suggest_rounded,
            linkifyText(context, importTypeStr),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            Icons.description_rounded,
            linkifyText(
                context,
                course.info == ""
                    ? S.of(context).unknown_info
                    : course.info ?? S.of(context).unknown_info),
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ],
      )),
      widgetOKAction: onPressed,
    );
  }
}
