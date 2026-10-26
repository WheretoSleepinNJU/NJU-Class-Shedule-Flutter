> 模板版本: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

本项目基于 [mobile_scanner](https://pub.dev/packages/mobile_scanner) 开发。


## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  fluttertpc_mobile_scanner:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
      ref: br_v7.1.4_ohos

...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [example](/example/lib/main.dart)


## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.35.7-ohos-0.0.1; SDK: 6.0.1(21); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;

### 2.2 权限要求

####  2.2.1 在 entry 目录下的module.json5中添加权限

打开 `entry/src/main/module.json5`，添加：

```diff
...
"requestPermissions": [
+  {
+    "name": "ohos.permission.CAMERA",
+    "reason": "$string:camera_reason",
+    "usedScene": {
+      "abilities": [
+        "EntryAbility"
+      ],
+      "when":"inuse"
+    }
+  }
]
```

#### 2.2.2 在 entry 目录下添加申请以上权限的原因

打开 `entry/src/main/resources/base/element/string.json`，添加：

```diff
...
{
  "string": [
+    {
+      "name": "camera_reason",
+      "value": "使用相机"
+    }
  ]
}
```


## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标iOS 或 Android 的效果。

| Name             | Description | Type    | Input                                                                | Output                  | ohos Support |
|------------------|-------------|---------|----------------------------------------------------------------------|-------------------------|--------------|
| start            | 开始扫码服务      |function | {CameraFacing? cameraDirection}                                      | Future<void>            | yes          |
| toggleTorch      | 开启或者关闭相机闪光灯 |function | /                                                                    | Future<void>            | yes          |
| stop             | 停止扫码服务      |function | /                                                                    | Future<void>            | yes          |
| analyzeImage     | 识别本地的图像文件   |function | String path, {List<BarcodeFormat> formats = const <BarcodeFormat>[]} | Future<BarcodeCapture?> | yes          |
| setZoomScale     | 设置相机变焦比     |function | double zoomScale                                                     | Future<void>            | yes          |
| resetZoomScale   | 重置相机变焦比为初始值   |function | /                                                                    | Future<void>            | yes          |
| updateScanWindow | 更新扫码框大小     |function | Rect? window                                                         | Future<void>            | yes          |
| switchCamera     | 切换摄像头       |function | /                                                                    | Future<void>            | yes          |
| setFocusPoint     | 设置相机焦点       |function | Offset position                                                                    | Future<void>            | yes          |


## 4. 属性

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标iOS 或 Android 的效果。

### MobileScannerController

| Name                 | Description                                | Type                    | ohos Support |
|----------------------|--------------------------------------------|-------------------------|--------------|
| facing               | 选择相机                                     | CameraFacing            | no           |
| torchEnabled         | 开启或者关闭闪光灯                             | bool                    | yes          |
| returnImage          | 扫码成功时返回图像缓冲区                         | bool                    | yes          |
| formats              | 码制式格式                                    | List<BarcodeFormat>?    | yes          |
| detectionTimeoutMs   | 设置扫码超时时间，单位毫秒                        | int                     | no           |
| autoStart            | 初始化时自动启动扫码服务                          | bool                    | yes          |
| cameraResolution     | 相机分辨率                                    | Size                    | yes           |
| useNewCameraSelector | 使用新的分辨率选择器                             | bool                    | no           |
| detectionSpeed       | 设置扫码检测速度                                | DetectionSpeed          | no           |
| invertImage          | 处理图片颜色反转                             | bool                    | yes           |
| autoZoom             | 是否自动变焦                                   | bool                    | yes           |
| initialZoom          | 初始化相机变焦比                                | double?                 | yes           |

### Parameters

| Name      | Description                                | Type      | ohos Support |
|-----------|--------------------------------------------|-----------|--------------|
| window    | 扫码框大小                                      | Rect?     | yes          |
| zoomScale | 相机变焦比必须在 0.0 和 1.0 之间，其中 1.0 为最大缩放，0.0 为缩小 | double?   | yes          |
| path      | 本地的图像文件路径                                  | String?   | yes          |


## 5. 遗留问题

- [ ] 自定义二维码扫描无法切换到前置摄像头: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)

## 6. 其他


## 7. 开源协议

本项目基于 [BSD 3-Clause License](/LICENSE)，请自由地享受和参与开源。