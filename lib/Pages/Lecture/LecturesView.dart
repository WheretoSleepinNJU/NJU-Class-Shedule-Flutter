import '../../AdaptiveUI/adaptive_ui.dart';
import '../../generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// import 'package:flutter_search_bar/flutter_search_bar.dart';
import '../../Components/Toast.dart';
import '../../Models/LectureModel.dart';
import '../../Resources/Constant.dart';
import '../../Resources/Url.dart';
import '../../Utils/WeekUtil.dart';

import './Widgets/LectureCard.dart';

//TODO: 讲座搜索

class LectureView extends StatefulWidget {
  const LectureView({Key? key}) : super(key: key);

  @override
  _LectureViewState createState() => _LectureViewState();
}

class _LectureViewState extends State<LectureView> {
  // late SearchBar searchBar;
  int totalPages = 1;
  int pageNum = 0;
  String searchParam = '';
  List<LectureCard> _lectureCards = <LectureCard>[];
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  final ScrollController _scrollController = ScrollController();
  List<String> _filterNames = [];
  final List<String> _filterStatus = [];
  bool _loadError = false;
  bool _loading = false;
  final Dio _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15)));

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
          _loadLectures();
        }
      }
    });
  }

  // _onSearchBarSubmitted(String value) {
  //   // print(value);
  // }

  Future<bool> _loadFilters() async {
    try {
      final response = await _dio.get(Url.URL_BACKEND + '/getTag');
      if (!mounted) return false;
      setState(() => _filterNames = List<String>.from(response.data['data']));
      return true;
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
      return false;
    }
  }

  Future<bool> _loadLectures() async {
    if (_loading) return false;
    _loading = true;
    try {
    var params = {'limit': 5, 'page': pageNum + 1, 'tag': _filterStatus};
    if (_filterStatus.isEmpty) params.remove('tag');
    var response =
        await _dio.get(Url.URL_BACKEND + '/getAll', queryParameters: params);
    if (!mounted) return false;
    totalPages = response.data['total_page'];

    for (Map lectureRow in response.data['data']) {
      _lectureCards.add(LectureCard(
          lecture: await _parseLecture(lectureRow),
          count: lectureRow['count']));
    }

    setState(() {
      _lectureCards = _lectureCards;
    });
    return true;
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
      return false;
    } finally {
      _loading = false;
    }
  }

  Future<Lecture> _parseLecture(data) async {
    DateTime startTime = DateTime.parse(data['startTime']);
    DateTime endTime = DateTime.parse(data['endTime']);

    List<int> weekNum = [await WeekUtil.getWeekNumOfDay(startTime)];

    var fullFormatter = DateFormat('yyyy-MM-dd HH:mm');
    var simpleFormatter = DateFormat('HH:mm');
    String timeString =
        fullFormatter.format(startTime) + '-' + simpleFormatter.format(endTime);

    DateTime now = DateTime.now();
    bool expired = now.isAfter(endTime);

    return Lecture(
        0,
        data['title'],
        weekNum.toString(),
        startTime.weekday,
        data['startIndex'],
        data['endIndex'] - data['startIndex'],
        Constant.ADD_BY_LECTURE,
        data['id'],
        timeString,
        data['accurate'],
        expired,
        classroom: data['classroom'],
        teacher: data['teacher'],
        info: data['info']);
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loadError = false);
    totalPages = 1;
    pageNum = 0;
    _lectureCards = <LectureCard>[];

    bool rst = true;
    if (_filterNames.isEmpty) rst = await _loadFilters();
    rst &= await _loadLectures();
    if (!mounted) return;
    if (rst) {
      Toast.showToast(S.of(context).lecture_refresh_success_toast, context);
    } else {
      Toast.showToast(S.of(context).lecture_refresh_fail_toast, context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
        appBar:
            // searchBar.build(context),
            AdaptiveTopAppBar(
                title: Text(S.of(context).lecture_title),
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
        body: SafeArea(
          child: RefreshIndicator(
          color: Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).primaryColor
              : Colors.white,
          key: _refreshKey,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: List<Widget>.generate(
                _lectureCards.length, (int i) => _lectureCards[i])
              ..insertAll(0, _loadError ? [
                TextButton(onPressed: _refresh,
                    child: Text(S.of(context).network_error_toast))
              ] : <Widget>[])
              ..insert(
                  0,
                  Padding(
                      padding:
                          const EdgeInsets.only(top: 5, left: 10, right: 10),
                      child: SizedBox(
                          height: 50, // 设置横向列表的高度
                          child: ListView(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            children: List<Padding>.generate(
                                _filterNames.length,
                                (int i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: FilterChip(
                                        label: Text(_filterNames[i]),
                                        labelStyle: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? (_filterStatus.contains(
                                                            _filterNames[i])
                                                        ? Colors.white
                                                        : Colors.black)
                                                    : Colors.white),
                                        checkmarkColor: Colors.white,
                                        selected: _filterStatus
                                            .contains(_filterNames[i]),
                                        selectedColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                        onSelected: (bool value) {
                                          setState(() {
                                            if (value) {
                                              _filterStatus
                                                  .add(_filterNames[i]);
                                            } else {
                                              _filterStatus
                                                  .remove(_filterNames[i]);
                                            }
                                            _refresh();
                                          });
                                        },
                                      ),
                                    )),
                          ))))
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
        )));
  }
}
