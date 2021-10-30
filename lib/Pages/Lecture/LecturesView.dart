import 'dart:io';
import 'dart:convert';
import '../../generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../Components/Toast.dart';
import '../../Models/LectureModel.dart';
import '../../Resources/Constant.dart';
import '../../Resources/Url.dart';
import '../../Utils/WeekUtil.dart';
import '../../Utils/TimeUtil.dart';

import './Widgets/LectureCard.dart';

class LectureView extends StatefulWidget {
  LectureView() : super();

  @override
  _LectureViewState createState() => _LectureViewState();
}

class _LectureViewState extends State<LectureView> {
  // TODO: change
  int totalPages = 2;
  int pageNum = 0;
  List<LectureCard> _lectureCards = <LectureCard>[];
  GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
    });
    _scrollController.addListener(() {
      double edge = 50;
      if (_scrollController.position.maxScrollExtent -
              _scrollController.position.pixels <=
          edge) {
        if (pageNum < totalPages - 1) {
          pageNum++;
          _loadLectures();
        }
      }
    });
  }

  Future<bool> _loadLectures() async {
    Dio dio = Dio();
    var response = await dio.get(Url.URL_BACKEND + '/getAll');
    // print(response);

    for (Map lectureRow in response.data['data']) {
      _lectureCards.add(LectureCard(lecture: await _parseLecture(lectureRow)));
    }

    setState(() {
      _lectureCards = _lectureCards;
    });
    return true;
  }

  Future<Lecture> _parseLecture(data) async {
    DateTime startTime = DateTime.parse(data['startTime']);
    DateTime endTime = DateTime.parse(data['endTime']);

    List<int> weekNum = [await WeekUtil.getWeekNumOfDay(startTime)];

    var fullFormatter = new DateFormat('yyyy-MM-dd HH:mm');
    var simpleFormatter = new DateFormat('HH:mm');
    String timeString =
        fullFormatter.format(startTime) + '-' + simpleFormatter.format(endTime);

    TimeUtil timeUtil = TimeUtil();
    Map timeRst = timeUtil.getClassTime(startTime, endTime);

    print(data['title']);
    print(timeRst['isStrict']);
    return Lecture(
        0,
        data['title'],
        weekNum.toString(),
        startTime.weekday,
        timeRst['startTime'],
        timeRst['timeCount'],
        Constant.ADD_BY_LECTURE,
        timeString,
        timeRst['isStrict'],
        classroom: data['classroom'],
        teacher: data['teacher'],
        info: data['info']);
  }

  Future<Null> _refresh() async {
    bool rst = await _loadLectures();
    if (rst)
      Toast.showToast(S.of(context).lecture_refresh_success_toast, context);
    else
      Toast.showToast(S.of(context).lecture_refresh_fail_toast, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text(S.of(context).lecture_title), actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () async {},
          ),
        ]),
        body: RefreshIndicator(
            color: Theme.of(context).primaryColor,
            key: _refreshKey,
            onRefresh: _refresh,
            child: ListView.builder(
              itemBuilder: (_, int index) {
                if (_lectureCards.isEmpty)
                  return Container();
                else if (index == _lectureCards.length)
                  return Column(
                    children: [
                      const Divider(),
                      Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 20),
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(S.of(context).lecture_bottom,
                                  style: TextStyle(color: Colors.grey))))
                    ],
                  );
                else
                  return _lectureCards[index];
              },
              itemCount: _lectureCards.length + 1,
              controller: _scrollController,
            )));
  }
}
