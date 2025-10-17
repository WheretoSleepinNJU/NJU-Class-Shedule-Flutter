import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../Utils/States/MainState.dart';
import '../../core/widget_data/utils/widget_refresh_helper.dart';

/// 小组件和实时活动设置页面
/// 仅在 iOS 平台显示
class WidgetSettingsView extends StatefulWidget {
  const WidgetSettingsView({Key? key}) : super(key: key);

  @override
  State<WidgetSettingsView> createState() => _WidgetSettingsViewState();
}

class _WidgetSettingsViewState extends State<WidgetSettingsView> {
  // 可选值
  final List<int> _approachingMinutesOptions = [5, 10, 15, 20, 30];
  final List<int> _tomorrowPreviewHourOptions = [19, 20, 21, 22, 23];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小组件和实时活动设置'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 即将上课提醒时间
          ListTile(
            title: const Text('即将上课提醒时间'),
            subtitle: const Text('在课程开始前多久显示"即将上课"状态'),
            trailing: FutureBuilder<int>(
              future: _getApproachingMinutes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(width: 0);
                }
                return DropdownButton<int>(
                  value: snapshot.data,
                  items: _approachingMinutesOptions.map((minutes) {
                    return DropdownMenuItem<int>(
                      value: minutes,
                      child: Text('$minutes 分钟'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _setApproachingMinutes(value);
                    }
                  },
                );
              },
            ),
          ),

          const Divider(),

          // 明日预览开始时间
          ListTile(
            title: const Text('明日预览开始时间'),
            subtitle: const Text('晚上几点后显示明天的课程'),
            trailing: FutureBuilder<int>(
              future: _getTomorrowPreviewHour(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(width: 0);
                }
                return DropdownButton<int>(
                  value: snapshot.data,
                  items: _tomorrowPreviewHourOptions.map((hour) {
                    return DropdownMenuItem<int>(
                      value: hour,
                      child: Text('$hour:00'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _setTomorrowPreviewHour(value);
                    }
                  },
                );
              },
            ),
          ),

          const Divider(),

          // 说明文本
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '设置将在下次小组件刷新时生效',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getApproachingMinutes() async {
    return await ScopedModel.of<MainStateModel>(context)
        .getWidgetApproachingMinutes();
  }

  void _setApproachingMinutes(int minutes) async {
    ScopedModel.of<MainStateModel>(context).setWidgetApproachingMinutes(minutes);
    setState(() {});

    // 刷新小组件
    await WidgetRefreshHelper.manualRefresh();

    // 显示提示
    Fluttertoast.showToast(
      msg: '小组件设置已保存',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<int> _getTomorrowPreviewHour() async {
    return await ScopedModel.of<MainStateModel>(context)
        .getWidgetTomorrowPreviewHour();
  }

  void _setTomorrowPreviewHour(int hour) async {
    ScopedModel.of<MainStateModel>(context).setWidgetTomorrowPreviewHour(hour);
    setState(() {});

    // 刷新小组件
    await WidgetRefreshHelper.manualRefresh();

    // 显示提示
    Fluttertoast.showToast(
      msg: '小组件设置已保存',
      toastLength: Toast.LENGTH_SHORT,
    );
  }
}
