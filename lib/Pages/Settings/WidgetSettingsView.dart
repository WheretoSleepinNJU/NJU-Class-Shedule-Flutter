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

  // 文本输入控制器
  final TextEditingController _textLeftController = TextEditingController();
  final TextEditingController _textRightController = TextEditingController();

  @override
  void dispose() {
    _textLeftController.dispose();
    _textRightController.dispose();
    super.dispose();
  }

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
            subtitle: const Text('在课程开始前多久显示"即将上课"状态和创建实时活动'),
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

          // Live Activity 设置标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '课前实时活动 (Live Activity)',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 启用 Live Activity
          FutureBuilder<bool>(
            future: _getLiveActivityEnabled(),
            builder: (context, snapshot) {
              return SwitchListTile(
                title: const Text('启用课前实时活动'),
                subtitle: const Text('在灵动岛和锁屏显示即将开始的课程'),
                value: snapshot.data ?? true,
                onChanged: (value) {
                  _setLiveActivityEnabled(value);
                },
              );
            },
          ),

          const Divider(),

          // 励志文本左
          ListTile(
            title: const Text('左侧文本'),
            subtitle: const Text('灵动岛展开时左上角显示的文字'),
            trailing: SizedBox(
              width: 120,
              child: FutureBuilder<String>(
                future: _getLiveActivityTextLeft(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _textLeftController.text = snapshot.data!;
                  }
                  return TextField(
                    controller: _textLeftController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '好好学习',
                    ),
                    onSubmitted: (value) {
                      _setLiveActivityTextLeft(value);
                    },
                  );
                },
              ),
            ),
          ),

          const Divider(),

          // 励志文本右
          ListTile(
            title: const Text('右侧文本'),
            subtitle: const Text('灵动岛展开时右上角显示的文字'),
            trailing: SizedBox(
              width: 120,
              child: FutureBuilder<String>(
                future: _getLiveActivityTextRight(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _textRightController.text = snapshot.data!;
                  }
                  return TextField(
                    controller: _textRightController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '天天向上',
                    ),
                    onSubmitted: (value) {
                      _setLiveActivityTextRight(value);
                    },
                  );
                },
              ),
            ),
          ),

          const Divider(),

          // 说明文本
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '提示：\n'
              '• 实时活动使用与小组件相同的"即将上课提醒时间"\n'
              '• 设置将在下次小组件刷新时生效\n'
              '• 实时活动将在课程开始前自动创建，上课时自动关闭',
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

  // Live Activity 相关方法
  Future<bool> _getLiveActivityEnabled() async {
    return await ScopedModel.of<MainStateModel>(context)
        .getLiveActivityEnabled();
  }

  void _setLiveActivityEnabled(bool enabled) async {
    ScopedModel.of<MainStateModel>(context).setLiveActivityEnabled(enabled);
    setState(() {});

    Fluttertoast.showToast(
      msg: '实时活动设置已保存',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<String> _getLiveActivityTextLeft() async {
    return await ScopedModel.of<MainStateModel>(context)
        .getLiveActivityTextLeft();
  }

  void _setLiveActivityTextLeft(String text) async {
    ScopedModel.of<MainStateModel>(context).setLiveActivityTextLeft(text);
    setState(() {});

    Fluttertoast.showToast(
      msg: '实时活动设置已保存',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<String> _getLiveActivityTextRight() async {
    return await ScopedModel.of<MainStateModel>(context)
        .getLiveActivityTextRight();
  }

  void _setLiveActivityTextRight(String text) async {
    ScopedModel.of<MainStateModel>(context).setLiveActivityTextRight(text);
    setState(() {});

    Fluttertoast.showToast(
      msg: '实时活动设置已保存',
      toastLength: Toast.LENGTH_SHORT,
    );
  }
}
