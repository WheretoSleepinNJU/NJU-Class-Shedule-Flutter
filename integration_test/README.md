# 三端原生模拟器检查

`checklist_test.dart` 在真实 Flutter 应用上执行 UI 操作，并用本地采集服务触发 Android / iOS / 鸿蒙原生截图。它创建 QA 课表，并在正常结束时恢复测试开始时的配置及课表选择。

仅使用一次性测试模拟器：`flutter test -d` 的安装阶段可能重置应用容器，脚本中的 finally 无法恢复安装前的数据。运行前应备份需要保留的数据库和配置。

`flutter drive` 默认在退出时停止并卸载应用；需要保留模拟器数据时必须使用 `--keep-app-running`，并在测试后安装正常 `lib/main.dart` 入口。鸿蒙普通 Ability 没有原生测试 Delegator，VM 驱动模式使用 `--dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false`，避免测试结束时 IntegrationTestPlugin 的原生上报异常；仍需检查 VM 驱动的完整结果，不能只看某一行“All tests passed”。

Debug/集成测试与 Release 构建应串行执行，切换模式后首次构建不要加 `--no-pub`。Flutter 3.35 需要按模式重新生成插件注册文件；跳过后可能残留 `IntegrationTestPlugin`，与 Release 已排除的测试依赖不匹配。

采集服务需监听 `127.0.0.1:8768`，接受脚本中的 snapshot、exchange、import-readback、result 和 native-poll JSON 请求。Android / 鸿蒙需要 SDK 反向端口转发。2026-10-24 本地实测报告的 `qa-round2/recorder.py` 保留该服务及原始事件日志。

截图采集器应检查原生前台窗口，拒绝系统权限弹窗遮挡的画面。采集接口返回非 200 时，测试会明确失败，不能仅凭 Flutter 页面断言通过认定截图有效。Android 一次性模拟器可预先授予本场景需要的相机权限。

`QA_RECORDER_PORT` 可指定采集端口，`QA_RETRY_CASES` 可指定逗号分隔的场景 ID。Android 权限遮挡补测使用 `QA_ANDROID_NETWORK_RETAKE=true`：采集器还需处理 `sdk-network` 的 `offline` / `restore` 请求，通过 SDK 关闭模拟器 Wi-Fi 和移动数据、确认无默认网络，并恢复原状态；R01 的 finally 也会请求恢复。

```sh
flutter test integration_test/checklist_test.dart -d DEVICE_ID --reporter expanded
```

可选参数：

- `--dart-define=QA_SKIP_SHARE=true`：复测其他场景时跳过已验证的跨端分享。
- `--dart-define=QA_LAYOUT_ONLY=true`：单独验证大字、小屏/横屏视口和混合冲突课程。
- `--dart-define=QA_APPEARANCE_ONLY=true`：在实际设备尺寸下验证 3.2 倍文字比例、节次栏宽度、课程字号与省略，以及课程详情采用同步放大的弹窗文字比例；不注入屏幕尺寸。
- `--dart-define=QA_DIALOG_ONLY=true`：验证大字详情的完整标题/正文缩放/长内容滚动、删除取消、新增输入弹窗，以及本次依赖升级后的剪贴板课表导入、WebView 本地页面/JavaScript 消息桥和 Toast 原生调用。
- `--dart-define=QA_PLUGIN_ONLY=true`：仅执行上述 WebView 和 Toast 原生插件检查；页面截图需另行目视确认，接口返回成功不代表画面已完成绘制。
- `--dart-define=QA_NATIVE_WIDGETS=true`：创建真实时钟下的短期课程，在 native-poll 阶段暂停，供桌面/锁屏原生组件操作及截图。
- `--dart-define=QA_NATIVE_ONLY=true`：仅准备上述原生组件夹具。
- `--dart-define=QA_WIDGET_QUICK=true`：将原生课程边界缩短为 1 / 2 / 3 / 4 分钟。

原生暂停阶段需手动添加组件、回到桌面等待，完成后由采集服务的 `PLATFORM-native-done` 标记结束。该暂停不自动判定原生截图通过；应对照时钟、课程数据和截图单独判定。

测试的离线用例是进程内拒绝连接注入；视口与大字用例是 Flutter 测试视口/文字比例注入，不代替物理真机、蜂窝弱网、系统读屏或真实整夜调度。未完成的账号、签名与功能接入条件应保留在报告中。

2026-10-24 补测发现 iOS 真正横屏时存在左右安全边距：`R02-small-rotate` 已增加两侧各 57 逻辑像素的 `padding` / `viewPadding` 回归，避免零边距视口掩盖刘海屏溢出。

注意：`TestFlutterView.physicalSize` 只改变框架布局，部分原生 SDK 截图仍保留旧 surface。R02 小屏、横屏与安全边距的注入步骤只输出 `layout-check` 和异常检查结果，不把 SDK 旧帧当作尺寸证明；实际尺寸与旋转截图使用正常产品包和系统设置另行采集。

课表七列总览将文字比例上限设为 1.4，统一放大节次、日期与课程文字；设置页仍保留系统文字比例。弹窗统一采用最高 2 倍文字比例，标题、正文和操作同步放大；长标题换行，长内容滚动，操作按钮固定可用。R05 另使用正常产品包与 iOS 系统最大辅助功能字号实拍，避免只凭无异常日志判断可读性。

`test/Components/dialog_accessibility_test.dart` 覆盖默认字号、3.2 倍输入比例下的 393×852 / 320×568 / 852×393 详情、删除取消以及 320×568 的键盘遮挡回归。检查完整课名、链接正文放大、滚动与按钮可操作性；不能仅以 MediaQuery 数值或没有异常判断视觉通过。

ICS / 多图背景原生回归：`integration_test/ics_background_test.dart` 使用端口8782的本地记录器，创建匿名课表与PNG图片，在真实生产页面验证配置和导出。Android使用官方模拟器主机地址10.0.2.2，避免drive清理reverse映射造成记录器断线。系统相册选择需要由adb、iOS XCTest或hdc在`picker-wait`后实际选择预置的两张测试图；不替换图片选择插件结果。测试最后恢复偏好和原有课表ID，使用`--keep-app-running`后再安装正常main.dart入口。鸿蒙需先把测试图从系统文件管理器保存到图库（Download目录中的图片不能直接出现在图库选择器）。

`background_refresh_test.dart` 使用真实首页和设置路由，回归立即换图后连续回退、深浅图自动标题色、逐图手动设置及主设置入口顺序。它用匿名生成图片，恢复原偏好与课表；截图记录服务端口为 8789，Android 使用 10.0.2.2，iOS/鸿蒙使用 127.0.0.1（鸿蒙需配置 hdc rport）。
