# fluttertoast

本项目基于 [fluttertoast](https://github.com/PonnamKarthik/FlutterToast) 开发。

## 目录

- [简介](#简介)
- [下载安装](#下载安装)
- [约束与限制](#约束与限制)
- [OHOS 开发环境配置](#ohos-开发环境配置)
- [使用示例](#使用示例)
- [使用说明](#使用说明)
- [接口说明](#接口说明)
- [常见问题](#常见问题)
- [遗留问题](#遗留问题)
- [目录结构](#目录结构)
- [贡献代码](#贡献代码)
- [开源协议](#开源协议)

## 简介

Flutter Toast 提示库，支持一行代码显示 Toast 消息。提供两种使用方式：

- **无需 BuildContext**：通过 `Fluttertoast.showToast()` 调用原生平台 Toast
- **需要 BuildContext**：通过 `FToast` 类使用自定义 Widget 作为 Toast 内容，支持队列管理和动画

## 下载安装

进入工程目录，在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  fluttertoast:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_fluttertoast.git
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: TAG # 请根据下方版本对应表选择分支
```

执行命令：

```bash
flutter pub get
```

| 三方库版本 | Flutter 框架版本 | TAG 名称 | 分支名 |
|---|---|---|---|
| 9.0.0 | 3.22 | 9.0.0-ohos-1.0.0 | br_v9.0.0_ohos |
| 9.0.0 | 3.27 | 9.0.0-ohos-1.0.0 | br_v9.0.0_ohos |
| 9.0.0 | 3.35 | 9.0.0-ohos-1.0.0 | br_v9.0.0_ohos |

### 版本升级迁移说明

- 从上游 `fluttertoast@8.x` 升级到本库 `9.0.0`：API 基本兼容，`Fluttertoast.showToast` / `FToast` 用法不变；请按上表选择与当前 Flutter 框架匹配的 TAG。
- 跨 Flutter 框架升级（如 3.7 → 3.22 / 3.27 / 3.35）：仅需更换 `pubspec.yaml` 中的 `ref` 为对应 TAG，并重新执行 `flutter pub get`。
- OHOS 自定义字体：请使用 `fontAssetOhosPath`（鸿蒙专属参数），勿与跨平台参数 `fontAsset` 混淆。

## 约束与限制

### 兼容性

在下述版本验证通过：

| 三方库版本 | Flutter (OHOS) | DevEco Studio | SDK | ROM |
|---|---|---|---|---|
| 9.0.0 | 3.22.3-ohos-1.0.1 | 6.1.0.860 | 6.1.0(23) | 6.0.0.120 SP6 |
| 9.0.0 | 3.27.5-ohos-1.0.1 | 6.1.0.860 | 6.1.0(23) | 6.0.0.120 SP6 |
| 9.0.0 | 3.35.7-ohos-0.0.1 | 6.1.0.860 | 6.1.0(23) | 6.0.0.120 SP6 |

### 权限要求

无。

## OHOS 开发环境配置

1. **安装 DevEco Studio**：下载并安装与上表兼容性信息匹配的 DevEco Studio 版本。
2. **配置 HarmonyOS SDK**：在 DevEco Studio 中安装对应 API 版本的 SDK（如 API 12 / API 21）。
3. **配置 Flutter OHOS SDK**：安装与目标 Flutter 版本匹配的 Flutter OHOS 引擎（如 `3.22.3-ohos-1.0.1`）。
4. **获取依赖**：在工程根目录执行 `flutter pub get`。
5. **编译运行**：进入 `example` 目录，执行 `flutter build hap` 或通过 DevEco Studio 打开 `example/ohos` 进行编译与真机/模拟器调试。

> 完整可运行示例见 [example](./example/) 目录。

## 使用示例

### Toast 无需 BuildContext

```dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 显示短 Toast
Fluttertoast.showToast(
  msg: "This is Short Toast",
  toastLength: Toast.LENGTH_SHORT,
  gravity: ToastGravity.BOTTOM,
  backgroundColor: Colors.black,
  textColor: Colors.white,
  fontSize: 16.0,
);

// 取消当前显示的 Toast
Fluttertoast.cancel();
```

### Toast 需要 BuildContext

```dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 在 MaterialApp 中配置 builder（必须，否则 Overlay 不可用）
MaterialApp(
  builder: FToastBuilder(),
  home: MyApp(),
  navigatorKey: navigatorKey,
);

// 初始化 FToast
FToast fToast = FToast();
fToast.init(context);

// 显示自定义 Toast
Widget toast = Container(
  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(25.0),
    color: Colors.greenAccent,
  ),
  child: Text("This is a Custom Toast"),
);

fToast.showToast(
  child: toast,
  gravity: ToastGravity.BOTTOM,
  toastDuration: Duration(seconds: 2),
);

// 移除当前 Toast
fToast.removeCustomToast();

// 清空 Toast 队列
fToast.removeQueuedCustomToasts();
```

### OHOS 自定义字体（fontAssetOhosPath）

`example` 工程已内置字体资源 `assets/HarmonyOS_Sans_Black_Italic.ttf`，可直接参考运行。

```dart
import 'package:fluttertoast/fluttertoast.dart';

Fluttertoast.showToast(
  msg: "This is Short Toast",
  toastLength: Toast.LENGTH_SHORT,
  // fontAsset：跨平台字体资源标识（Android/iOS 等）
  fontAsset: 'font style test',
  // fontAssetOhosPath：鸿蒙平台专属参数，指定 Flutter asset 中的字体文件路径；
  // 传入后 OHOS 侧使用自定义弹窗展示 Toast（支持 cancel），而非系统 Toast
  fontAssetOhosPath: 'assets/HarmonyOS_Sans_Black_Italic.ttf',
);
```

## 使用说明

### 无 BuildContext 模式

`Fluttertoast.showToast()` 通过原生平台 Toast 显示消息，适用于简单文本提示场景。该方法通过 MethodChannel 与平台通信，返回 `Future<bool?>`。

> **OpenHarmony 平台**：自定义字体场景下使用 `fontAssetOhosPath` 参数指定字体路径，OHOS 侧将通过自定义弹窗显示 Toast。系统 Toast 模式下不支持 cancel（鸿蒙平台限制）。

### 有 BuildContext 模式

`FToast` 使用 Flutter Overlay 显示自定义 Widget，支持队列管理、淡入淡出动画、自定义位置等高级特性。

> 使用 `FToast` 必须在 `MaterialApp.builder` 中添加 `FToastBuilder()`，否则 Overlay 不可用。

## 接口说明

### Fluttertoast

| 名称 | 返回类型 | 描述 | 鸿蒙支持 |
|------|----------|------|----------|
| `showToast({required String msg, ...})` | `Future<bool?>` | 显示原生 Toast | 是 |
| `cancel()` | `Future<bool?>` | 取消当前 Toast | 是（仅自定义字体场景） |

**showToast 参数**（`Fluttertoast.showToast`，原生平台 Toast）：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| msg | String | 必填 | Toast 消息内容 |
| toastLength | Toast? | Toast.LENGTH_SHORT | 显示时长 |
| gravity | ToastGravity? | ToastGravity.BOTTOM | 显示位置 |
| backgroundColor | Color? | Colors.black | 背景颜色 |
| textColor | Color? | Colors.white | 文字颜色 |
| fontSize | double? | null | 字体大小；为 null 时不覆盖系统默认字号 |
| fontAsset | String? | null | 字体文件路径（Flutter asset，跨平台） |
| fontAssetOhosPath | String? | null | OHOS 平台专属字体路径；指定后使用自定义弹窗 |
| timeInSecForIosWeb | int | 1 | iOS/Web 显示时长 |

### FToast

| 名称 | 返回类型 | 描述 | 鸿蒙支持 |
|------|----------|------|----------|
| `FToast()` | `FToast` | 工厂构造函数 | 是 |
| `FToastBuilder()` | `TransitionBuilder` | MaterialApp.builder 所需构建器 | 是 |
| `init(BuildContext context)` | `FToast` | 初始化，保存上下文 | 是 |
| `showToast({required Widget child, ...})` | `void` | 显示自定义 Widget Toast | 是 |
| `removeCustomToast()` | `void` | 移除当前 Toast | 是 |
| `removeQueuedCustomToasts()` | `void` | 清空队列 | 是 |
| `context` | `BuildContext?` | 存储的上下文 | 是 |

**showToast 参数**（`FToast.showToast`，自定义 Widget Toast，与 `Fluttertoast.showToast` 不同）：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| child | Widget | 必填 | Toast 内容 |
| toastDuration | Duration | Duration(seconds: 2) | 显示时长 |
| gravity | ToastGravity? | null | 显示位置 |
| positionedToastBuilder | PositionedToastBuilder? | null | 自定义位置构建函数 |
| fadeDuration | Duration | Duration(milliseconds: 350) | 淡入淡出时长 |
| ignorePointer | bool | false | 是否忽略指针事件 |
| isDismissible | bool | false | 是否可点击关闭 |

### 枚举

**Toast**：

| 值 | 说明 |
|----|------|
| LENGTH_SHORT | 短时长（约 2 秒） |
| LENGTH_LONG | 长时长（约 3.5 秒） |

**ToastGravity**：

| 值 | 说明 |
|----|------|
| TOP | 顶部 |
| BOTTOM | 底部 |
| CENTER | 中间 |

## 常见问题

### cancel 方法对系统 Toast 无效

`Fluttertoast.cancel()` 仅在自定义字体场景（传了 `fontAssetOhosPath` 参数且字体已加载）下生效。无自定义字体时使用系统 `promptAction.showToast()`，鸿蒙系统未提供关闭接口，cancel 调用无法立即消失。这是鸿蒙平台 API 限制。

### 升级到 9.0.0 后 Android 端报 Platform.isOhos 异常

v9.0.0 版本在 `lib/fluttertoast.dart` 中增加了 `Platform.isOhos` 判断，编译时会引入 `dart:io`。请确保使用的 Flutter 版本 >= 3.7.x，且未在 Web 平台使用本库（Web 不支持 `dart:io`）。

### 自定义字体 Toast 使用弹窗实现

OHOS 平台在自定义字体场景下使用 `promptAction.openCustomDialog` 替代系统 Toast，与 Android/iOS 原生 Toast 的行为不完全一致。遇到位置、样式等差异属正常现象。

## 遗留问题

- **系统 Toast 不支持 cancel**：`promptAction.showToast()` 无取消接口，无自定义字体场景下 `Fluttertoast.cancel()` 无法立即关闭正在显示的系统 Toast。这是鸿蒙平台 API 限制。

## 目录结构

```
├── lib/                  # Dart 层公开 API
│   └── fluttertoast.dart
├── ohos/                 # OHOS 平台实现
│   ├── index.ets
│   └── src/main/ets/toast/
│       ├── FlutterToastPlugin.ets  # 插件主类
│       ├── CustomToastDialog.ets   # 自定义弹窗工具类
│       └── CustomToastView.ets     # 自定义弹窗视图组件
├── android/              # Android 平台实现
├── ios/                  # iOS 平台实现
├── example/              # 示例应用
│   └── lib/
│       ├── main.dart
│       ├── toast_no_context.dart   # 无 BuildContext 示例
│       └── toast_context.dart      # 有 BuildContext 示例
└── assets/               # 静态资源
```

## 贡献代码

使用过程中发现问题，请在 [GitCode Issues](https://gitcode.com/CPF-Flutter/flutter_fluttertoast/issues) 提交 Issue。

## 开源协议

本项目基于 [Apache License 2.0](LICENSE) 开源。
