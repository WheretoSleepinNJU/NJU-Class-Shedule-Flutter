> 模板版本: v0.0.1

<p align="center">
  <h1 align="center"> <code>package_info_plus</code> </h1>
</p>

本项目基于 [package_info_plus](https://pub.dev/packages/package_info_plus) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  package_info_plus:
    git: 
      url: https://gitcode.com/openharmony-sig/flutter_plus_plugins.git
      path: packages/package_info_plus/package_info_plus

...
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [example](example/lib/main.dart)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;
2. Flutter: 3.22.1-ohos-1.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;


## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

### PackageInfo API 
| Name                | Description                         | Type     | Input | Output  | ohos Support |
|---------------------|-------------------------------------|----------|-------|---------|--------------|
| fromPlatform      | 获取并缓存平台特定的包信息 | future | / | Future<PackageInfo> | yes |

## 4. 属性

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

### PackageInfo Filters 
| Name                | Description                         | Type     | Input | Output  | ohos Support |
|---------------------|-------------------------------------|----------|-------|---------|--------------|
| appName             | 获取应用名称  | String | / | / | yes |
| packageName         | 获取包名称  | String | / | / | yes |
| version             | 获取包版本号  | String | / | / | yes |
| buildNumber         | 获取构建编号  | String | / | / | yes |
| buildSignature      | 获取构建签名  | String | / | / | yes |
| installerStore      | 获取安装商店信息 | String? | / | / | no |
| data                | 获取包信息的Map表示形式 | Map<String, dynamic> | / | / | yes |

## 5. 遗留问题

## 6. 其他

## 7. 开源协议

本项目基于 [The BSD-3-Clause (license)](LICENSE) ，请自由地享受和参与开源。
