import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Models/CourseModel.dart';
import '../../../Models/LectureModel.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Components/Toast.dart';
import '../../../Components/Dialog.dart';
import '../../../Components/TransBgTextButton.dart';
import '../../../Resources/Config.dart';
import '../../../Resources/Url.dart';

class LectureCard extends StatefulWidget {
  final Lecture lecture;
  final int count;

  const LectureCard({Key? key, required this.lecture, required this.count})
      : super(key: key);

  @override
  _LectureCardState createState() => _LectureCardState();
}

class _LectureCardState extends State<LectureCard> {
  bool added = false;
  int count = 0;

  @override
  void initState() {
    super.initState();
    count = widget.count;
    checkAdded();
  }

  checkAdded() async {
    widget.lecture.tableId =
        await ScopedModel.of<MainStateModel>(context).getClassTable();
    CourseProvider courseProvider = CourseProvider();
    bool rst = await courseProvider.checkHasClassByName(
        widget.lecture.tableId ?? 0, widget.lecture.name ?? '');
    if (rst) {
      setState(() {
        added = true;
      });
    }
  }

  addLecture() async {
    int weekInt = json.decode(widget.lecture.weeks!)[0];
    if (weekInt < 0 || weekInt > Config.MAX_WEEKS) {
      Toast.showToast(S.of(context).lecture_add_fail_toast, context);
      return;
    }
    CourseProvider courseProvider = CourseProvider();
    await courseProvider.insert(widget.lecture);
    Dio dio = Dio();
    await dio.get(Url.URL_BACKEND + '/addCount',
        queryParameters: {'id': widget.lecture.lectureId});
    // print(response);
    Toast.showToast(S.of(context).lecture_add_success_toast, context);
    setState(() {
      added = true;
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    String subtitle = S.of(context).lecture_teacher_title +
        (widget.lecture.teacher ?? S.of(context).lecture_no_teacher) +
        '\n' +
        (widget.lecture.classroom ?? S.of(context).lecture_no_classroom);
    return Padding(
        padding: const EdgeInsets.only(bottom: 15, left: 5, right: 5),
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                // leading: Icon(Icons.album),
                title:
                    Text(widget.lecture.name ?? S.of(context).lecture_no_name),
                subtitle: Text(subtitle),
              ),
              Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(15.0),
                child: SelectableLinkify(
                  onOpen: (link) async {
                    String url =
                        link.url.replaceAll(RegExp('[^\x00-\xff]'), '');
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      Toast.showToast(
                          S.of(context).network_error_toast, context);
                    }
                  },
                  text: widget.lecture.info ?? S.of(context).unknown_info,
                  linkStyle: TextStyle(color: Theme.of(context).primaryColor),
                  options: const LinkifyOptions(humanize: false),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  widget.lecture.expired
                      ? TransBgTextButton(
                          color: Colors.grey,
                          onPressed: () {
                            Toast.showToast(
                                S.of(context).lecture_add_expired_toast,
                                context);
                          },
                          child: Text(S.of(context).lecture_expired(count)))
                      : added
                          ? TransBgTextButton(
                              color: Colors.grey,
                              child: Text(S.of(context).lecture_added(count)),
                              onPressed: () {
                                Toast.showToast(
                                    S.of(context).lecture_added_toast, context);
                              },
                            )
                          : TransBgTextButton(
                              color: Theme.of(context).primaryColor,
                              child: Text(S.of(context).lecture_add(count)),
                              onPressed: () async {
                                if (widget.lecture.isAccurate) {
                                  addLecture();
                                } else {
                                  showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return MDialog(
                                            S
                                                .of(context)
                                                .lecture_cast_dialog_title,
                                            Text(S
                                                .of(context)
                                                .lecture_cast_dialog_content),
                                            widgetCancelAction: () {
                                          UmengCommonSdk.onEvent(
                                              "class_import", {
                                            "type": "lecture",
                                            "action": "cancel"
                                          });
                                          Navigator.of(context).pop();
                                        }, widgetOKAction: () async {
                                          await addLecture();
                                          UmengCommonSdk.onEvent(
                                              "class_import", {
                                            "type": "lecture",
                                            "action": "success"
                                          });
                                          Navigator.of(context).pop();
                                        });
                                      });
                                }
                              },
                            ),
                ],
              ),
            ],
          ),
        ));
  }
}
