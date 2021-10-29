import 'dart:io';
import 'dart:convert';
import '../../generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../Models/LectureModel.dart';
import '../../Resources/Url.dart';

import './Widgets/LectureCard.dart';

class LectureView extends StatefulWidget {
  LectureView() : super();

  @override
  _LectureViewState createState() => _LectureViewState();
}

class _LectureViewState extends State<LectureView> {
  List<LectureCard> _lectureCards = <LectureCard>[];

  GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  ScrollController _scrollController = ScrollController();

  // bool isLoading = false;

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
        // if (!isLoading) {
        //   setState(() {
        //     isLoading = true;
        //   });
        _loadLectures();
        // }
      }
    });
  }

  _loadLectures() async {
    Dio dio = Dio();
    var response = await dio.get(Url.URL_BACKEND + '/getAll');
    print(response);

    for (Map lectureRow in response.data['data']) {
      _lectureCards.add(LectureCard(lecture: _parseLecture(lectureRow)));
    }

    setState(() {
      _lectureCards = _lectureCards;
    });
    return true;
  }

  Lecture _parseLecture(data) {
    return Lecture(0, data['title'], "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
        color: '#8AD297',
        classroom: data['classroom'],
        teacher: data['teacher'],
        info: data['info']);
  }

  Future<Null> _refresh() async {
    await _loadLectures();
  }

  @override
  Widget build(BuildContext context) {
    // List<Lecture> lectures = [
    //   Lecture(0, "形变理论与Hodge理论", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
    //       color: '#8AD297',
    //       classroom: '戊己庚四楼北',
    //       teacher: '沈洋',
    //       info:
    //       '腾讯会议：629 7515 8598\n\n摘要：分类问题是数学的主要问题,模空间是研究复几何与代数几何中分类问题的重要概念。形变理论是由 Kodaira 与 Spencer 在1958-1960创立的,用来研究模空间的无穷小性质; Hodge 理论是由 Griffiths 在1967年创立的,是研究模空间整体性质的重要工具。'),
    //   Lecture(0, "形变理论与Hodge理论", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
    //       color: '#8AD297',
    //       classroom: '戊己庚四楼北',
    //       teacher: '沈洋',
    //       info:
    //       '腾讯会议：629 7515 8598\n\n摘要：分类问题是数学的主要问题,模空间是研究复几何与代数几何中分类问题的重要概念。形变理论是由 Kodaira 与 Spencer 在1958-1960创立的,用来研究模空间的无穷小性质; Hodge 理论是由 Griffiths 在1967年创立的,是研究模空间整体性质的重要工具。')
    // ];
    // _lectureCards = lectures
    //     .map((lecture) => new LectureCard(lecture: lecture)).toList();

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
        body:
            // SingleChildScrollView(
            //     child: Column(children: <Widget>[
            //   Flexible(
            //       child:
            RefreshIndicator(
                key: _refreshKey,
                onRefresh: _refresh,
                child: ListView.builder(
                  itemBuilder: (_, int index) => _lectureCards[index],
                  itemCount: _lectureCards.length,
                  controller: _scrollController,
                ))
        // ),
        // const Divider(),
        // Padding(
        //     padding: const EdgeInsets.only(top: 5, bottom: 20),
        //     child: FittedBox(
        //         fit: BoxFit.scaleDown,
        //         child: Text(S.of(context).lecture_bottom)))
        // ]))
        );

    // return Scaffold(
    //     appBar:
    //         AppBar(title: Text(S.of(context).lecture_title), actions: <Widget>[
    //       IconButton(
    //         icon: Icon(Icons.search),
    //         onPressed: () async {},
    //       ),
    //       IconButton(
    //         icon: Icon(Icons.filter_list),
    //         onPressed: () async {},
    //       ),
    //     ]),
    //     body: SingleChildScrollView(
    //         child: Column(
    //             children: <Widget>[]
    //               ..addAll(lectures
    //                   .map((lecture) => new LectureCard(lecture: lecture)))
    //               ..addAll([
    //                 const Divider(),
    //                 Padding(
    //                     padding: const EdgeInsets.only(top: 5, bottom: 20),
    //                     child: FittedBox(
    //                         fit: BoxFit.scaleDown,
    //                         child: Text(S.of(context).lecture_bottom)))
    //               ]))));
  }
}
