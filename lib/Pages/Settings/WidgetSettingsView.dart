import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../Components/Toast.dart';
import '../../Utils/States/MainState.dart';
import '../../core/widget_data/utils/widget_refresh_helper.dart';

class WidgetSettingsView extends StatefulWidget {
  const WidgetSettingsView({Key? key}) : super(key: key);

  @override
  State<WidgetSettingsView> createState() => _WidgetSettingsViewState();
}

class _WidgetSettingsViewState extends State<WidgetSettingsView> {
  final List<int> _approachingMinutesOptions = <int>[5, 10, 15, 20, 30];
  final List<int> _tomorrowPreviewHourOptions = <int>[19, 20, 21, 22, 23];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小组件设置'),
        elevation: 0,
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('即将上课提醒时间'),
            subtitle: const Text('在课程开始前多久显示“即将上课”状态'),
            trailing: FutureBuilder<int>(
              future: _getApproachingMinutes(),
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return DropdownButton<int>(
                  value: snapshot.data,
                  items: _approachingMinutesOptions.map((int minutes) {
                    return DropdownMenuItem<int>(
                      value: minutes,
                      child: Text('$minutes 分钟'),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      _setApproachingMinutes(value);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('明日预览开始时间'),
            subtitle: const Text('晚上几点后显示明天的课程'),
            trailing: FutureBuilder<int>(
              future: _getTomorrowPreviewHour(),
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return DropdownButton<int>(
                  value: snapshot.data,
                  items: _tomorrowPreviewHourOptions.map((int hour) {
                    return DropdownMenuItem<int>(
                      value: hour,
                      child: Text('$hour:00'),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      _setTomorrowPreviewHour(value);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getApproachingMinutes() async {
    return ScopedModel.of<MainStateModel>(context)
        .getWidgetApproachingMinutes();
  }

  Future<int> _getTomorrowPreviewHour() async {
    return ScopedModel.of<MainStateModel>(context)
        .getWidgetTomorrowPreviewHour();
  }

  Future<void> _setApproachingMinutes(int minutes) async {
    ScopedModel.of<MainStateModel>(context)
        .setWidgetApproachingMinutes(minutes);
    setState(() {});
    await WidgetRefreshHelper.manualRefresh();
    if (mounted) {
      Toast.showToast('小组件设置已保存', context);
    }
  }

  Future<void> _setTomorrowPreviewHour(int hour) async {
    ScopedModel.of<MainStateModel>(context).setWidgetTomorrowPreviewHour(hour);
    setState(() {});
    await WidgetRefreshHelper.manualRefresh();
    if (mounted) {
      Toast.showToast('小组件设置已保存', context);
    }
  }
}
