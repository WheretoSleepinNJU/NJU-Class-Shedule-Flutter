import 'Widgets/PlatformSettings.dart';
import 'package:flutter/material.dart';
import '../../core/widget_data/communication/native_data_bridge.dart';
import '../../core/widget_data/utils/widget_refresh_helper.dart';

/// Android permission state is queried again after returning from system settings.
class AndroidLiveActivitySettings extends StatefulWidget {
  const AndroidLiveActivitySettings({Key? key}) : super(key: key);
  @override
  State<AndroidLiveActivitySettings> createState() =>
      _AndroidLiveActivitySettingsState();
}

class _AndroidLiveActivitySettingsState
    extends State<AndroidLiveActivitySettings>
    with WidgetsBindingObserver {
  final _bridge = NativeDataBridge();
  Map<String, dynamic> _status = {};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await _bridge.getLiveActivityStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _permission(String title, String key, String target, String missing) =>
      SettingsTile(
        title: Text(title),
        subtitle: Text(_status[key] == true ? '已开启' : missing),
        trailing: const Icon(Icons.chevron_right),
        enabled: !_busy,
        onTap: () => _run(() => _bridge.openLiveActivitySettings(target)),
      );

  String _stateText() {
    switch (_status['state']) {
      case 'disabled':
        return '实时活动已关闭';
      case 'permissionDenied':
        return '通知权限或课前实时活动通知类别未开启';
      case 'posted':
        return '系统通知列表中已有本应用的实时活动';
      case 'noData':
        return '没有可用于提醒的课程，请刷新课表并检查当前周次与作息';
      case 'noUpcomingCourse':
        return '今日及明日没有待提醒课程，或本次提醒已关闭';
      case 'waiting':
        return '尚未进入课前 ${_status['approachingMinutes'] ?? 15} 分钟提醒窗口';
      case 'notPosted':
        return '已进入提醒窗口，但系统通知列表中没有通知，请立即测试并查看错误';
      default:
        return '正在读取运行状态';
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsIsland = _status['supportsIsland'] == true;
    final next = (_status['nextAt'] as num?)?.toInt() ?? 0;
    return Column(
      children: [
        SettingsSwitchTile(
          title: const Text('课前实时活动'),
          subtitle: const Text('课前显示课程和倒计时，上课或点击“我已到达”后结束'),
          value: _status['enabled'] == true,
          onChanged: _busy
              ? null
              : (value) => _run(() async {
                  // Persist the newest timetable before enabling native scheduling.
                  if (value && !await WidgetRefreshHelper.manualRefresh()) {
                    throw StateError('课表同步失败，请重试后再开启');
                  }
                  final status = await _bridge.configureLiveActivities(
                    enabled: value,
                  );
                  if (value && status['notificationsEnabled'] != true) {
                    await _bridge.openLiveActivitySettings('notifications');
                  }
                }),
        ),
        _permission(
          '通知权限',
          'notificationsEnabled',
          'notifications',
          '未开启，无法显示实时活动',
        ),
        _permission(
          '准时提醒',
          'exactAlarmAllowed',
          'exactAlarm',
          '未允许精确闹钟，提醒可能延迟',
        ),
        if (_status['supportsLiveUpdates'] == true)
          _permission(
            '原生 Live Updates',
            'promotionAllowed',
            'promotion',
            '系统未允许提升，使用普通通知',
          ),
        _permission(
          '后台电池限制',
          'batteryUnrestricted',
          'battery',
          '可在系统设置中允许后台运行',
        ),
        SettingsTile(
          title: const Text('自启动设置'),
          subtitle: const Text('打开应用信息页，在系统支持时允许自启动；应用无法读取所有厂商的开关状态'),
          enabled: !_busy,
          onTap: () =>
              _run(() => _bridge.openLiveActivitySettings('autostart')),
        ),
        if (supportsIsland) ...[
          SettingsTile(
            title: const Text('小米超级岛'),
            subtitle: const Text('Shizuku/Root 模式会在发布时短暂阻断小米推送网络，可能延迟推送。默认关闭'),
            trailing: SettingsDropdown<String>(
              value: _status['islandMode'] as String? ?? 'OFF',
              items: const [
                SettingsOption(value: 'OFF', child: Text('默认')),
                SettingsOption(value: 'SHIZUKU', child: Text('Shizuku')),
                SettingsOption(value: 'ROOT', child: Text('Root')),
                SettingsOption(value: 'SYSTEM_HOOK', child: Text('已解除白名单')),
              ],
              onChanged: _busy
                  ? null
                  : (mode) {
                      if (mode != null) {
                        _run(() async {
                          await _bridge.configureLiveActivities(
                            islandMode: mode,
                          );
                        });
                      }
                    },
            ),
          ),
          if (['SHIZUKU', 'ROOT'].contains(_status['islandMode']))
            SettingsTile(
              title: const Text('授权并连接超级岛后端'),
              subtitle: Text(
                '${_status['islandStatus'] ?? '尚未连接'}${_status['islandReady'] == true ? ' · 已就绪' : ''}',
              ),
              enabled: !_busy,
              onTap: () => _run(_bridge.authorizeIsland),
            ),
          SettingsTile(
            title: const Text('恢复小米推送网络'),
            enabled: !_busy,
            onTap: () => _run(_bridge.restoreIslandNetwork),
          ),
        ],
        SettingsTile(
          title: const Text('立即测试实时活动'),
          subtitle: const Text('立即显示两分钟测试提醒，使用当前展示模式，结束后恢复课程提醒'),
          enabled: !_busy && _status['enabled'] == true,
          trailing: const Icon(Icons.notifications_active_outlined),
          onTap: () => _run(_bridge.testLiveActivity),
        ),
        SettingsTile(
          title: const Text('刷新运行状态'),
          subtitle: Text(
            [
              _stateText(),
              '今日及明日可解析课程：${_status['courseCount'] ?? 0} 节',
              if ((_status['nextCourseAt'] as num?) != null)
                '下节上课：${DateTime.fromMillisecondsSinceEpoch((_status['nextCourseAt'] as num).toInt()).toLocal()}',
              if ((_status['windowStartAt'] as num?) != null)
                '开始提醒：${DateTime.fromMillisecondsSinceEpoch((_status['windowStartAt'] as num).toInt()).toLocal()}',
              if (next > 0)
                '下次调度：${DateTime.fromMillisecondsSinceEpoch(next).toLocal()}',
              if (_status['activeId'] != null)
                '展示请求：${_status['surface'] ?? 'notification'}',
              if (_status['promoted'] == true) '已提升为 Live Update',
              if (_error != null) _error!,
              if (_status['lastError'] != null) '${_status['lastError']}',
            ].join('\n'),
          ),
          trailing: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: SettingsCircularProgressIndicator(),
                )
              : const Icon(Icons.refresh),
          onTap: _busy
              ? null
              : () => _run(() async {
                  if (!await WidgetRefreshHelper.manualRefresh()) {
                    throw StateError('课表同步失败，未能更新运行状态');
                  }
                  if (!await _bridge.refreshLiveActivities()) {
                    throw StateError('原生调度刷新失败');
                  }
                }),
        ),
      ],
    );
  }
}
