import '../../../AdaptiveUI/adaptive_ui.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';

// import 'package:flutter_linkify/flutter_linkify.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Models/CourseModel.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Components/Toast.dart';
import '../../CourseTable/Widgets/CourseSummaryTile.dart';
import '../../../Resources/Config.dart';
import '../../../Resources/Url.dart';

//TODO: 全校课程

class CourseCard extends StatefulWidget {
  final Course course;
  final int count;

  const CourseCard({Key? key, required this.course, required this.count})
    : super(key: key);

  @override
  _CourseCardState createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool added = false;
  int count = 0;
  bool collapsed = true;

  @override
  void initState() {
    super.initState();
    count = widget.count;
    checkAdded();
  }

  checkAdded() async {
    widget.course.tableId = await ScopedModel.of<MainStateModel>(
      context,
    ).getClassTable();
    CourseProvider courseProvider = CourseProvider();
    bool rst = await courseProvider.checkHasClassByName(
      widget.course.tableId ?? 0,
      widget.course.name ?? '',
    );
    if (rst && mounted) {
      setState(() {
        added = true;
      });
    }
  }

  addCourse() async {
    int weekInt = json.decode(widget.course.weeks!)[0];
    if (weekInt < 0 || weekInt > Config.MAX_WEEKS) {
      Toast.showToast(S.of(context).lecture_add_fail_toast, context);
      return;
    }
    CourseProvider courseProvider = CourseProvider();
    await courseProvider.insert(widget.course);
    if (!mounted) return;
    MainStateModel.of(context).refresh();
    Dio dio = Dio();
    await dio.get(
      Url.URL_BACKEND + '/addCount',
      queryParameters: {'id': widget.course.courseId},
    );
    // print(response);
    if (!mounted) return;
    Toast.showToast(S.of(context).lecture_add_success_toast, context);
    setState(() {
      added = true;
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CourseSummaryTile(
              meetings: [widget.course],
              expanded: !collapsed,
              onTap: () => setState(() => collapsed = !collapsed),
            ),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.course.info ?? S.of(context).unknown_info,
                      style: AdaptiveTypography.body.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AdaptiveButton.text(
                        onPressed: added
                            ? () => Toast.showToast(
                                S.of(context).lecture_added_toast,
                                context,
                              )
                            : addCourse,
                        child: Text(
                          added
                              ? S.of(context).lecture_added(count)
                              : S.of(context).lecture_add(count),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
