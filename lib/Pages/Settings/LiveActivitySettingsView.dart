import '../../Components/Toast.dart';
import 'Widgets/MiuixSettings.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../Utils/States/MainState.dart';
import '../../core/widget_data/utils/widget_refresh_helper.dart';
import 'AndroidLiveActivitySettings.dart';

class LiveActivitySettingsView extends StatefulWidget {
  const LiveActivitySettingsView({Key? key}) : super(key: key);

  static String get settingsTitle => Platform.isIOS ? '灵动岛' : '实时活动与小米超级岛';

  @override
  State<LiveActivitySettingsView> createState() =>
      _LiveActivitySettingsViewState();
}

class _LiveActivitySettingsViewState extends State<LiveActivitySettingsView> {
  bool _saving = false;

  Future<void> _setMinutes(int minutes) async {
    setState(() => _saving = true);
    try {
      await ScopedModel.of<MainStateModel>(
        context,
      ).setWidgetApproachingMinutes(minutes);
      if (!await WidgetRefreshHelper.manualRefresh()) {
        throw StateError('课表同步失败，请刷新运行状态重试');
      }
    } catch (error) {
      if (mounted) {
        Toast.showToast('$error', context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsScaffold(
    title: LiveActivitySettingsView.settingsTitle,
    body: SafeArea(
      child: ListView(
        children: [
          if (Platform.isAndroid) ...[
            SettingsTile(
              title: const Text('课前提醒时间'),
              subtitle: const Text('同时用于小组件的“即将上课”状态'),
              trailing: FutureBuilder<int>(
                future: ScopedModel.of<MainStateModel>(
                  context,
                ).getWidgetApproachingMinutes(),
                builder: (context, snapshot) => snapshot.hasData
                    ? SettingsDropdown<int>(
                        value: snapshot.data,
                        items: [5, 10, 15, 20, 30]
                            .map(
                              (minutes) => SettingsOption(
                                value: minutes,
                                child: Text('$minutes 分钟'),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) _setMinutes(value);
                              },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const MiuixHorizontalDivider(),
            const AndroidLiveActivitySettings(),
          ] else if (Platform.isIOS)
            const SettingsTile(
              title: Text('灵动岛'),
              subtitle: Text('暂未完成接入'),
              enabled: false,
            ),
        ],
      ),
    ),
  );
}
