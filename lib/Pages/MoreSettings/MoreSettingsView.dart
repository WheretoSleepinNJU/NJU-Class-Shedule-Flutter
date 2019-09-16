import '../../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Components/Toast.dart';

class MoreSettingsView extends StatefulWidget {
  MoreSettingsView() : super();

  @override
  _MoreSettingsViewState createState() => _MoreSettingsViewState();
}

class _MoreSettingsViewState extends State<MoreSettingsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).more_settings_title),
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          SingleChildScrollView(
              child: Column(
                  children: ListTile.divideTiles(context: context, tiles: [
            ListTile(
              title: Text(S.of(context).shuffle_color_pool_title),
              subtitle: Text(S.of(context).shuffle_color_pool_subtitle),
              onTap: () {
                ColorPool.shuffleColorPool();
                Toast.showToast(
                    S.of(context).shuffle_color_pool_success_toast, context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text(S.of(context).if_show_weekend_title),
              subtitle: Text(S.of(context).if_show_weekend_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getShowWeekend(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowWeekend(value),
                      );
                    }
                  }),
            ),
            ListTile(
              title: Text(S.of(context).if_show_classtime_title),
              subtitle: Text(S.of(context).if_show_classtime_subtitle),
              trailing: FutureBuilder<bool>(
                  future: _getShowClassTime(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowClassTime(value),
                      );
                    }
                  }),
            ),
            ListTile(
              title: Text('显示月份'),
              subtitle: Text('在课表的左上角显示当前月份'),
              trailing: FutureBuilder<bool>(
                  future: _getShowMonth(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowMonth(value),
                      );
                    }
                  }),
            ),
            ListTile(
              title: Text('显示日期'),
              subtitle: Text('显示当前周的日期'),
              trailing: FutureBuilder<bool>(
                  future: _getShowDate(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (!snapshot.hasData) {
                      return Container(width: 0);
                    } else {
                      return Switch(
                        value: snapshot.data,
                        onChanged: (bool value) =>
                            ScopedModel.of<MainStateModel>(context)
                                .setShowDate(value),
                      );
                    }
                  }),
            ),
          ]).toList()))
        ])));
  }

  Future<bool> _getShowWeekend() async {
    return await ScopedModel.of<MainStateModel>(context).getShowWeekend();
  }

  Future<bool> _getShowClassTime() async {
    return await ScopedModel.of<MainStateModel>(context).getShowClassTime();
  }

  Future<bool> _getShowMonth() async {
    return await ScopedModel.of<MainStateModel>(context).getShowMonth();
  }

  Future<bool> _getShowDate() async {
    return await ScopedModel.of<MainStateModel>(context).getShowDate();
  }
}
