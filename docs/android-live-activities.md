# Android 课程实时活动

## 范围与入口

设置 → 实时活动与小米超级岛 → 课前实时活动。默认关闭；开启后使用小组件的“即将上课提醒时间”。仅在课前窗口展示最近的一节课，上课时、到达后或关闭本次提醒后撤销。关闭/到达按课程实际发生时间持久化，不影响下一周同一门课。

Android 16+ 请求原生 Live Updates；小米/Redmi/Poco API 35+ 可附加 Focus V3 超级岛协议。系统是否真正提升由通知权限、系统设置及 ROM 决定。设置中的“展示请求”不等同于实际显示，原生 `promoted` 字段来自已发布通知的标记。

## 后台运行

- Flutter 仍经 `com.wheretosleepinnju/widget_data` 同步，原生保存全学期课程和作息。
- 调度独立于桌面小组件安装状态；使用 `RTC_WAKEUP`，精确闹钟可用时调用 `setExactAndAllowWhileIdle`，否则使用非精确闹钟。
- 仅排下一次课前、上课或午夜边界。活动显示期间按需运行短时前台服务，系统 chronometer 驱动倒计时，不进行每秒特权发布。超级岛展示绝对上课时间。
- `BOOT_COMPLETED`、`MY_PACKAGE_REPLACED`、时间/时区/日期变化及精确闹钟授权后重新核对持久化数据。
- 开机恢复不直接启动前台服务；先发布通知、恢复闹钟。前台界面和允许的精确闹钟入口可以启动活动期间的服务。
- 课程增删、切换课表和设置变化继续走原有 widget 刷新链路，重新核对通知并替换待执行闹钟。用户关闭通知后停止调度，返回界面时重新检查权限。
- Android 原有跨天推算补充读取 `semesterCourses`，避免后续周才开始的课程丢失；支持 Dart 微秒时间及 UTC/偏移量，保留临近边界。

厂商自启动、电池限制和用户强行停止应用仍会影响触发。自启动入口优先打开小米安全中心，失败时回退应用信息；应用无法确认所有 ROM 的自启动开关。没有精确闹钟权限时，不承诺准点开始或结束。

## Flutter 接口契约

沿用原有方法；`true` 表示已接收并安排核对，不能解释为已显示到岛。

| 方法 | Android 语义 |
| --- | --- |
| `sendWidgetData` | 保存课表，切换到课表驱动的自动调度，独立于桌面小组件 |
| `sendLiveActivityData` | 完整显式活动快照，按 activityId 更新；空数组撤销全部显式活动 |
| `sendUnifiedDataPackage` | 先校验活动，再接收 widget/liveActivities；提供活动数组时显式快照优先，省略时沿用原有模式 |
| `refreshLiveActivities` | 从原生持久化数据重新核对，不依赖 Dart 后台执行 |
| `endLiveActivity` | 关闭 activityId 对应的这一次课程提醒 |
| `configureLiveActivities` | 设置 `enabled` 或 `islandMode` |
| `getLiveActivityStatus` | 查询通知、精确闹钟、电池状态、提升权限/实际标记、后端状态、下次调度及最近错误 |
| `openLiveActivitySettings` | `notifications` / `exactAlarm` / `promotion` / `battery` / `autostart` |
| `authorizeIsland` | 请求 Shizuku 授权或连接 Root 后端 |
| `restoreIslandNetwork` | 请求恢复遗留 XMSF 网络规则 |

`LiveActivityData` 的 ID 为 `schoolId:courseId:startEpochMillis`，与原生课表展开的 ID 一致。Dart 生成器使用全学期周次与真实作息，提供真实 startTime/endTime；后台原生从同一课表快照投影今日与明日。`ended`、`ending`、`failed` 不参与课前展示。非法活动快照被拒绝，保留此前有效数据。

通知按钮直接在原生侧落盘，Flutter 不在线也可关闭或到达。普通通知用不可变 PendingIntent；超级岛采用显式 Activity Intent URI、安装级随机 token，并校验发生实例仍存在，拒绝伪造和过期动作。

## Deadliner 适配来源

复用本地 Deadliner 的 `LiveUpdateNotificationAdapter` 分流思路、`XiaomiIslandExtras` Focus V3 字段结构、`IslandWhitelistBypass`、`IslandFirewallWindow`、特权服务和 AIDL。移除了 Task/KMP/Compose 依赖，课程协议与展示独立实现。没有引入歌词项目源码。

模式互斥：

- `OFF`：不使用特权；API 36+ 请求原生 Live Updates，API 35 小米可按系统白名单尝试 Focus 协议。
- `SHIZUKU` / `ROOT`：显式选择后使用特权进程，在发布窗口阻断 XMSF UID 约 100ms，然后恢复；失败时发布普通/原生 Live Updates 通知。
- `SYSTEM_HOOK`：用户已通过外部系统模块解除白名单时直接发送 Focus 协议，不主动修改网络。

保留应用内发布串行化、重复请求合并、10 秒重试退避、特权进程 5 秒 watchdog、销毁恢复及遗留恢复记录。倒计时不触发每秒发布。Root/Shizuku 授权不代表应用获得后台保活能力。

不同应用分别维护的发布锁无法协调同一个 XMSF 防火墙 UID；与 Deadliner 同时使用特权模式的交叉发布需要单独真机验证。实际 HyperOS 展示、断网/恢复和权限撤回也必须在专用测试设备验收。

## 验证

共享 Dart 数据与既有刷新链路：

```sh
flutter test --no-pub test/core/widget_data test/Utils/harmony_widget_test.dart
```

原生验证可以正常使用项目 Android 测试任务，也可在 Flutter SDK 未对齐时隔离运行：

```sh
JAVA_HOME=/path/to/jdk python3 tool/test_android_live_activity.py \
  --flutter-sdk /path/to/flutter \
  --android-sdk /path/to/android-sdk \
  --gradle /path/to/gradle
```

脚本使用真实 Flutter Android embedding、生产的实时活动 Manifest 条目、资源、MainActivity、通道、原生实现和宿主测试，构建临时 Android library。它排除无关友盟初始化及自动插件注册，不修改工作区工具链，不生成完整应用 APK，也不操作设备。

自动检查覆盖：窗口边界、跨周新课程、微秒/时区解析、发生实例去重、通知撤销、启动恢复、关闭状态持久化、无桌面小组件、非法快照保留、原有 Flutter 方法、伪造/过期动作、前台服务结束以及 watchdog 网络恢复（伪后端）。iOS ActivityKit 的实际创建/更新/结束不在此次 Android 实现范围。

### 2026-10-26 验证记录

- Flutter 课程选择、刷新顺序、活动构建与鸿蒙数据回归：15 项通过。
- 原生宿主检查 56 项通过，调试 library 构建通过；新增 Flutter 设置页、构建器及相关设置文件静态分析无问题。
- 原生宿主验证使用 AGP 8.13.0 / Kotlin 2.2.21 / compileSdk 36 / Java 与 Kotlin 1.8 字节码目标，真实 Flutter Android embedding；测试计数见脚本输出。
- 已生成 arm64 release 测试 APK，使用本机调试证书签名；未在实际 Android/HyperOS 设备验证 promotion、系统杀进程、自动启动开关及真实特权网络窗口。

### 发布失败排查修复

用户反馈 HyperOS 4 上已允许通知、开启开关且进入提醒窗口，普通通知与岛均未出现，同机 Deadliner 正常。尚无设备日志，无法确认设备端唯一原因。

修复原生通知等待特权回调才发布、通知被系统移除后因签名缓存而不重发的问题。先发布标准通知，再尝试超级岛；特权连接/模板异常保留基础通知，闹钟异常不阻止当前通知发布。最近错误保留至后续排查，不再每次核对即清空。

设置页开启时检查课表同步结果，必要时主动请求通知权限。新增“立即测试实时活动”：独立保存两分钟测试实例，使用当前展示模式，支持关闭和自动过期，结束后恢复真实课程，不覆盖真实课表或已关闭实例，不写入真实课程到达状态。

原生宿主回归共 62 项全部通过，涵盖特权回调等待期间已存在普通通知、系统通知丢失后重发、缺课表/未进入窗口/通知禁用的原因、测试实例过期与已关闭实例保留。新增设置页静态分析无问题；桥接文件仍有原有 print 和未使用私有函数提示。

“刷新运行状态”会同步最新课表，并显示未触发原因、今日/明日投影数量、下节课和提醒开始时间。`notificationPosted` 从系统实际活动通知列表读取；它仅确认通知存在，不保证 OEM 界面已经显示超级岛。`testLiveActivity` 为沿用通道的新增诊断方法，要求已开启功能和通知权限。

本次修复包为 4.1.0+72 arm64 release，沿用上一测试版的 Android Debug 证书；v2/v3 签名验证与 16KB ZIP 对齐检查通过。

设置入口按平台显示：Android 为“实时活动与小米超级岛”，集中提醒时间、通知权限、后台设置、超级岛后端和测试诊断；iOS 为“灵动岛”，显示尚未完成接入的说明。入口与页面标题一致。鸿蒙仅显示禁用的“实况窗 / 暂未接入”占位项，不发起通道调用。小组件设置保留桌面显示选项。

独立设置入口测试包为 4.1.0+73 arm64 release，沿用测试签名。设置相关文件静态检查没有新增问题（主设置页有 3 条原有 info）；release 构建、v2/v3 签名验证及 16KB ZIP 对齐检查通过。
