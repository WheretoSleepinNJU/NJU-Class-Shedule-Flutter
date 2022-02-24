import '../../generated/l10n.dart';
import 'package:dio/dio.dart';

// import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// import 'package:flutter_search_bar/flutter_search_bar.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Resources/Constant.dart';
import '../../Resources/Url.dart';
import '../../Utils/WeekUtil.dart';

import './Widgets/CourseCard.dart';

//TODO: 全校课程

class AllCourseView extends StatefulWidget {
  const AllCourseView({Key? key}) : super(key: key);

  @override
  _AllCourseViewState createState() => _AllCourseViewState();
}

class _AllCourseViewState extends State<AllCourseView> {
  // late SearchBar searchBar;
  int totalPages = 1;
  int pageNum = 0;
  String searchParam = '';
  List<CourseCard> _lectureCards = <CourseCard>[];
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  final List<int> _filterStatus = [];

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).lecture_title),
      // actions: [searchBar.getSearchAction(context)]
    );
  }

  @override
  void initState() {
    super.initState();
    // searchBar = new SearchBar(
    //     inBar: true,
    //     hintText: S.of(context).lecture_search,
    //     buildDefaultAppBar: buildAppBar,
    //     setState: setState,
    //     onSubmitted: _onSearchBarSubmitted,
    //     onCleared: () {
    //       print("Search bar has been cleared");
    //     },
    //     onClosed: () {
    //       print("Search bar has been closed");
    //     });
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
          _loadAllCourses();
        }
      }
    });
  }

  // _onSearchBarSubmitted(String value) {
  //   print(value);
  // }

  Future<bool> _loadAllCourses() async {
    Dio dio = Dio();
    // print(pageNum);
    var response = await dio.get(Url.URL_BACKEND + '/getAll',
        queryParameters: {'limit': 10, 'page': pageNum + 1});
    totalPages = response.data['total_page'];

    for (Map courseRow in response.data['data']) {
      _lectureCards.add(CourseCard(
          course: await _parseAllCourse(courseRow), count: courseRow['count']));
    }

    setState(() {
      _lectureCards = _lectureCards;
    });
    return true;
  }

  Future<Course> _parseAllCourse(data) async {
    DateTime startTime = DateTime.parse(data['startTime']);
    // DateTime endTime = DateTime.parse(data['endTime']);

    List<int> weekNum = [await WeekUtil.getWeekNumOfDay(startTime)];

    // var fullFormatter = DateFormat('yyyy-MM-dd HH:mm');
    // var simpleFormatter = DateFormat('HH:mm');
    // String timeString =
    //     fullFormatter.format(startTime) + '-' + simpleFormatter.format(endTime);

    // DateTime now = DateTime.now();
    // bool expired = now.isAfter(endTime);

    return Course(
        0,
        data['title'],
        weekNum.toString(),
        startTime.weekday,
        data['startIndex'],
        data['endIndex'] - data['startIndex'],
        Constant.ADD_BY_LECTURE,
        classroom: data['classroom'],
        teacher: data['teacher'],
        info: data['info']);
  }

  Future<void> _refresh() async {
    totalPages = 1;
    pageNum = 0;
    _lectureCards = <CourseCard>[];
    bool rst = await _loadAllCourses();
    if (rst) {
      Toast.showToast(S.of(context).lecture_refresh_success_toast, context);
    } else {
      Toast.showToast(S.of(context).lecture_refresh_fail_toast, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            // searchBar.build(context),
            AppBar(
                title: Text(S.of(context).all_course_title),
                actions: const <Widget>[
              // searchBar.getSearchAction(context),
              // IconButton(
              //   icon: Icon(Icons.search),
              //   onPressed: () async {},
              // ),
              // IconButton(
              //   icon: Icon(Icons.filter_list),
              //   onPressed: () async {},
              // ),
            ]),
        body: RefreshIndicator(
          color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white,
          key: _refreshKey,
          onRefresh: _refresh,
          child: ListView(
            children: List<Widget>.generate(
                _lectureCards.length, (int i) => _lectureCards[i])
              ..insert(
                  0,
                  Padding(
                      padding:
                          const EdgeInsets.only(top: 5, left: 10, right: 10),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: FilterChip(
                              label: const Text('精选'),
                              labelStyle: TextStyle(
                                  color: _filterStatus.contains(1)
                                      ? Colors.white
                                      : Colors.black),
                              checkmarkColor: Colors.white,
                              selected: _filterStatus.contains(1),
                              selectedColor: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                              onSelected: (bool value) {
                                setState(() {
                                  if (value) {
                                    _filterStatus.add(1);
                                  } else {
                                    _filterStatus.remove(1);
                                  }
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: FilterChip(
                              label: const Text('仙林'),
                              labelStyle: TextStyle(
                                  color: _filterStatus.contains(2)
                                      ? Colors.white
                                      : Colors.black),
                              checkmarkColor: Colors.white,
                              selected: _filterStatus.contains(2),
                              selectedColor: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                              onSelected: (bool value) {
                                setState(() {
                                  if (value) {
                                    _filterStatus.add(2);
                                  } else {
                                    _filterStatus.remove(2);
                                  }
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: FilterChip(
                              label: const Text('鼓楼'),
                              labelStyle: TextStyle(
                                  color: _filterStatus.contains(3)
                                      ? Colors.white
                                      : Colors.black),
                              checkmarkColor: Colors.white,
                              selected: _filterStatus.contains(3),
                              selectedColor: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                              onSelected: (bool value) {
                                setState(() {
                                  if (value) {
                                    _filterStatus.add(3);
                                  } else {
                                    _filterStatus.remove(3);
                                  }
                                });
                              },
                            ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 5),
                          //   child: ChoiceChip(label: Text('仙林'), selected: true,),
                          // ),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 5),
                          //   child: ChoiceChip(label: Text('鼓楼'), selected: true,),
                          // ),
                        ],
                      )))
              ..add(Column(
                children: [
                  const Divider(),
                  Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 20),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(S.of(context).lecture_bottom,
                              style: const TextStyle(color: Colors.grey))))
                ],
              )),
            controller: _scrollController,
          ),
          // ListView.builder(
          //   itemBuilder: (_, int index) {
          //     if (_lectureCards.isEmpty)
          //       return Container();
          //     else if (index == _lectureCards.length)
          //       return Column(
          //         children: [
          //           const Divider(),
          //           Padding(
          //               padding: const EdgeInsets.only(top: 5, bottom: 20),
          //               child: FittedBox(
          //                   fit: BoxFit.scaleDown,
          //                   child: Text(S.of(context).lecture_bottom,
          //                       style: TextStyle(color: Colors.grey))))
          //         ],
          //       );
          //     else
          //       return _lectureCards[index];
          //   },
          //   itemCount: _lectureCards.length + 1,
          //   controller: _scrollController,
          // )
        ));
  }
}
