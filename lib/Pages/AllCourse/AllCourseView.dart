import '../../AdaptiveUI/adaptive_ui.dart';
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
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  bool _loading = false, _loadError = false;
  int totalPages = 1;
  int pageNum = 0;
  String searchParam = '';
  List<CourseCard> _lectureCards = <CourseCard>[];
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  final List<int> _filterStatus = [];

  AdaptiveTopAppBar buildAppBar(BuildContext context) {
    return AdaptiveTopAppBar(
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
    });
    _scrollController.addListener(() {
      double edge = 50;
      if (_scrollController.position.maxScrollExtent -
              _scrollController.position.pixels <=
          edge) {
        if (!_loading && !_loadError && pageNum < totalPages - 1) {
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
    if (_loading) return false;
    _loading = true;
    try {
      final response = await _dio.get(
        Url.URL_BACKEND + '/getAll',
        queryParameters: {'limit': 10, 'page': pageNum + 1},
      );
      final cards = <CourseCard>[];
      for (final row in response.data['data']) {
        cards.add(
          CourseCard(course: await _parseAllCourse(row), count: row['count']),
        );
      }
      if (!mounted) return false;
      setState(() {
        totalPages = response.data['total_page'];
        _loadError = false;
        _lectureCards.addAll(cards);
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
      return false;
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dio.close(force: true);
    super.dispose();
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
      info: data['info'],
    );
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loadError = false);
    totalPages = 1;
    pageNum = 0;
    _lectureCards = <CourseCard>[];
    bool rst = await _loadAllCourses();
    if (!mounted) return;
    if (rst) {
      Toast.showToast(S.of(context).lecture_refresh_success_toast, context);
    } else {
      Toast.showToast(S.of(context).lecture_refresh_fail_toast, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar:
          // searchBar.build(context),
          AdaptiveTopAppBar(
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
            ],
          ),
      body: SafeArea(
        child: AdaptiveRefreshIndicator(
          color: Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).primaryColor
              : Colors.white,
          refreshIndicatorKey: _refreshKey,
          onRefresh: _refresh,
          child: AdaptivePageList(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            children:
                List<Widget>.generate(
                    _lectureCards.length,
                    (int i) => _lectureCards[i],
                  )
                  ..insertAll(
                    0,
                    _loadError
                        ? [
                            AdaptiveButton.text(
                              onPressed: _refresh,
                              child: Text(S.of(context).network_error_toast),
                            ),
                          ]
                        : <Widget>[],
                  )
                  ..insert(
                    0,
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (id, name) in [
                            (1, '精选'),
                            (2, '仙林'),
                            (3, '鼓楼'),
                          ])
                            AdaptiveFilterChip(
                              label: Text(name),
                              selected: _filterStatus.contains(id),
                              onSelected: (value) => setState(() {
                                if (value) {
                                  _filterStatus.add(id);
                                } else {
                                  _filterStatus.remove(id);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  )
                  ..add(
                    Column(
                      children: [
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 20),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              S.of(context).lecture_bottom,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        ),
      ),
    );
  }
}
