# class_alarm_bridge 方案草案（简化版）

## 1. 目标

`class_alarm_bridge` 只解决一件事：
把 Android / iOS / HarmonyOS 的闹钟能力封装成统一 Flutter 接口。

插件不关心“课表”“早八”“周末规则”等业务逻辑。
这些逻辑由应用层自己实现，然后调用插件接口。

## 2. 设计边界

插件负责：

- 权限请求与状态查询
- 能力探测（是否支持系统闹钟、是否支持精确闹钟）
- 创建/更新/取消闹钟
- 查询已调度闹钟（可选）

插件不负责：

- 闹钟策略生成（如根据课表推导）
- 周期规则解释器
- 业务存储模型

## 3. 包结构（保持最小）

建议先单包实现，不拆 federated：

- `lib/class_alarm_bridge.dart`：统一 API
- `android/`：AlarmManager 实现
- `ios/`：AlarmKit / 本地能力实现
- `ohos/`：reminderAgentManager 实现

后续如果维护成本上升，再拆为 federated plugin。

## 4. 统一数据模型

```dart
class AlarmItem {
  final String id;                // 业务侧唯一 ID
  final DateTime triggerAt;       // 触发时间
  final String? title;            // 标题
  final String? body;             // 文本
  final Map<String, String>? meta;// 透传字段（可选）

  const AlarmItem({
    required this.id,
    required this.triggerAt,
    this.title,
    this.body,
    this.meta,
  });
}

class AlarmCapabilities {
  final bool supportsSystemAlarm;
  final bool supportsExactAlarm;
  final bool supportsBatchUpsert;
  final String platform;
  final String? note;

  const AlarmCapabilities({
    required this.supportsSystemAlarm,
    required this.supportsExactAlarm,
    required this.supportsBatchUpsert,
    required this.platform,
    this.note,
  });
}

enum AlarmPermissionState {
  granted,
  denied,
  permanentlyDenied,
  notApplicable,
}
```

## 5. 统一 API

```dart
abstract class ClassAlarmBridge {
  Future<AlarmCapabilities> getCapabilities();

  Future<AlarmPermissionState> getPermissionState();
  Future<AlarmPermissionState> requestPermission();

  Future<void> scheduleAlarm(AlarmItem alarm);
  Future<void> upsertAlarms(List<AlarmItem> alarms); // 推荐主入口
  Future<void> cancelAlarm(String id);
  Future<void> cancelAll();

  Future<List<AlarmItem>> getScheduledAlarms(); // 可选
}
```

约定：

- `id` 相同视为同一闹钟，`upsert` 要幂等。
- 不支持的能力通过异常码或能力字段显式返回，不 silent fail。

## 6. 平台实现约定

## 6.1 Android

- 基于 `AlarmManager`
- 建议支持 exact alarm 能力探测
- 通过 `BroadcastReceiver` 处理触发
- 可选支持重启恢复（由插件存储最小必要数据）

## 6.2 iOS

- 优先走系统闹钟能力（若可用）
- 若系统版本/能力不支持，返回 `supportsSystemAlarm=false`
- 插件不强行降级到通知（是否降级由应用层决定）

## 6.3 HarmonyOS

- 基于 `@ohos.reminderAgentManager`
- 与 Flutter 通过 method channel 对接

## 7. 错误码建议

```text
permission_denied
capability_unsupported
invalid_alarm_time
schedule_failed
cancel_failed
internal_error
```

应用层根据错误码决定是否重试、提示、降级。

## 8. 与当前仓库集成方式

应用层流程示例：

1. 应用自己计算出目标闹钟列表（任何业务规则都在应用层）
2. 调用 `bridge.upsertAlarms(alarms)`
3. 对比失败项并提示用户

这样插件保持通用，业务保持自由。

## 9. 迭代顺序

- `v0`：统一 API + Android 可用 + iOS/Harmony 基础壳
- `v1`：iOS 可用
- `v2`：Harmony 可用

## 10. 结论

按“纯接口封装层”实现更轻、边界清晰，适合当前诉求。
插件只做跨平台能力抽象，不预设业务场景。
