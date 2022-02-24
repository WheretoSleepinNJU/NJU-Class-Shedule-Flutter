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
import '../../../Components/TransBgTextButton.dart';
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
    widget.course.tableId =
        await ScopedModel.of<MainStateModel>(context).getClassTable();
    CourseProvider courseProvider = CourseProvider();
    bool rst = await courseProvider.checkHasClassByName(
        widget.course.tableId ?? 0, widget.course.name ?? '');
    if (rst) {
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
    Dio dio = Dio();
    await dio.get(Url.URL_BACKEND + '/addCount',
        queryParameters: {'id': widget.course.courseId});
    // print(response);
    Toast.showToast(S.of(context).lecture_add_success_toast, context);
    setState(() {
      added = true;
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // String subtitle = S.of(context).lecture_teacher_title +
    //     (widget.course.teacher ?? S.of(context).lecture_no_teacher) +
    //     '\n' +
    //     (widget.course.classroom ?? S.of(context).lecture_no_classroom);
    String time = "时间&地点： 周一 第5-6节 第3周 第7周 第11周 第15周 仙Ⅰ-109 ";
    String teacher = "授课教师：李其芳";
    widget.course.info =
        "邀请您参加腾讯会议会议主题：大四上形势与政策课会议时间：2021/09/13-2021/10/25 14:00-14:30(GMT 08:00) 中国标准时间 - 北京, 每两周 (周一)点击链接入会，或添加至会议列表：https://meeting.tencent.com/dm/QwC3svPLW9jO?rs=25会议 ID：699 6156 9408手机一键拨号入会 8675536550000,,69961569408";
    return Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        child: Card(
          child: ExpansionTile(
            onExpansionChanged: (val) => setState(() {
              collapsed = !collapsed;
            }),
            // textColor: Theme.of(context).brightness == Brightness.light
            //           ? Theme.of(context).primaryColor
            //           : Colors.white,
            textColor: Colors.black,
            iconColor: Colors.grey,
            title: Column(
              children: [
                // Text(widget.course.name ?? S.of(context).lecture_no_name),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      widget.course.name ?? S.of(context).lecture_no_name,
                      overflow: collapsed
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          maxLines: 2,
                          overflow: collapsed
                              ? TextOverflow.ellipsis
                              : TextOverflow.visible,
                        ),
                        Text(
                          teacher,
                          overflow: collapsed
                              ? TextOverflow.ellipsis
                              : TextOverflow.visible,
                        ),
                      ],
                    )),
              ],
            ),
            children: <Widget>[
              Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(15.0),
                  child:
                      Text(widget.course.info ?? S.of(context).unknown_info)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  added
                      ? TransBgTextButton(
                          color: Colors.grey,
                          child: Text(S.of(context).lecture_added(count)),
                          onPressed: () {
                            Toast.showToast(
                                S.of(context).lecture_added_toast, context);
                          },
                        )
                      : TransBgTextButton(
                          color: Theme.of(context).brightness == Brightness.light
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          child: Text(S.of(context).lecture_add(count)),
                          onPressed: () async {
                            addCourse();
                          },
                        ),
                ],
              ),
            ],
          ),
          // Column(
          //   mainAxisSize: MainAxisSize.min,
          //   children: <Widget>[
          //     ListTile(
          //       // leading: Icon(Icons.album),
          //       title:
          //           Text(widget.course.name ?? S.of(context).lecture_no_name),
          //       subtitle: Text(subtitle),
          //     ),
          //     Container(
          //       alignment: Alignment.topLeft,
          //       padding: const EdgeInsets.all(15.0),
          //       child: SelectableLinkify(
          //         onOpen: (link) async {
          //           String url =
          //               link.url.replaceAll(RegExp('[^\x00-\xff]'), '');
          //           if (await canLaunch(url)) {
          //             await launch(url);
          //           } else {
          //             Toast.showToast(
          //                 S.of(context).network_error_toast, context);
          //           }
          //         },
          //         text: widget.course.info ?? S.of(context).unknown_info,
          //         linkStyle: TextStyle(color: Theme.of(context).primaryColor),
          //         options: const LinkifyOptions(humanize: false),
          //       ),
          //     ),
          //     Row(
          //       mainAxisAlignment: MainAxisAlignment.end,
          //       children: <Widget>[added
          //                 ? TextButton(
          //                     style: TextButton.styleFrom(primary: Colors.grey),
          //                     child: Text(S.of(context).lecture_added(count)),
          //                     onPressed: () {
          //                       Toast.showToast(
          //                           S.of(context).lecture_added_toast, context);
          //                     },
          //                   )
          //                 : TextButton(
          //                     style: TextButton.styleFrom(
          //                         primary: Theme.of(context).primaryColor),
          //                     child: Text(S.of(context).lecture_add(count)),
          //                     onPressed: () async {
          //                         addCourse();
          //                     },
          //                   ),
          //       ],
          //     ),
          //   ],
          // ),
        ));
  }
}
