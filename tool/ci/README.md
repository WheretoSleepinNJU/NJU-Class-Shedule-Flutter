# 三端 GitHub Actions 构建

流程位于 [`.github/workflows/build.yml`](../../.github/workflows/build.yml)。每次向 `master` 推送、推送 `v*` 标签或提交 PR，先执行 Flutter 与清华导入回归测试，再构建 Android、iOS、HarmonyOS。也可以在 GitHub 的 **Actions → Build Android, iOS and HarmonyOS → Run workflow** 手动运行，选择单个平台或三端。

默认 `signed=false`，无需签名 Secrets。手动选择 `signed=true` 时，所选平台必须配置下表中的全部 Secrets。流程只上传 Actions 构建产物，不会自动发布 GitHub Release、TestFlight、App Store 或应用市场。Actions 下载的 ZIP 内含构建文件和 `SHA256SUMS`，保留 14 天。

| 平台 | 默认产物 | `signed=true` 的产物 |
| --- | --- | --- |
| Android | `android-unsigned.apk`，不能直接安装 | `android-signed.apk`，使用已有发布密钥，可正常安装升级 |
| iOS | `ios-unsigned.xcarchive.zip`，未签名归档，不能直接安装 | `ios-app-store.ipa`，用于 App Store Connect / TestFlight，不是 Ad Hoc 安装包 |
| HarmonyOS | `ohos-unsigned.hap`，不能直接安装 | `ohos-signed.hap`，安装或发布能力取决于所提供的 Profile |

## 固定工具链与依赖

- Flutter 使用 `.fvmrc` 中的 `3.35.8-ohos-1.0.4`，并校验提交 `8320f6ded3f0bdc5409545e26dcd2596bf054203`，三端不混用官方 Flutter SDK。
- `bootstrap.sh` 固定三个 `external` 路径依赖的提交，并按 `pubspec.lock` 严格恢复 Pub 依赖。仓库中遗留的 mobile_scanner gitlink 不作为 submodule 拉取；实际依赖以 `pubspec.yaml` 中固定的 Git 提交为准。
- Release 构建保留 Flutter 自动 Pub / 平台注册文件生成步骤，并在构建后检查 `pubspec.lock` 没有变化。此 SDK 在 `--no-pub` 时也会跳过 Release 插件注册文件重建，可能把 `integration_test` 留在 Android 注册文件中，导致编译失败。
- Android 使用 Ubuntu 24.04、JDK 17、SDK 36、Gradle 8.13；显式设置 Flutter 的 `jdk-dir`，避免它优先选择 Android Studio 自带的新 JDK。在临时空项目中生成 Gradle wrapper，不依赖本机未提交的 wrapper 文件。未提供 `key.properties` 时产出无签名 Release，不会退回 Debug 签名。
- iOS 使用 GitHub 托管 `macos-15` ARM64 runner，明确选择该镜像提供的 Xcode 26.3，使用 Ruby 3.3、CocoaPods 1.17.0 和 xcodeproj 1.27.0。版本来源见 [官方镜像清单](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)。提交 `ios/Podfile.lock` 固定原生依赖，并在构建后检查锁文件没有漂移。主应用最低 iOS 15，小组件最低 iOS 17。
- 鸿蒙使用 Ubuntu 24.04 x64，下载固定的 Command Line Tools `6.1.1.280` 并校验 SHA-256。下载源沿用 [SDL 官方 HarmonyOS CI](https://github.com/libsdl-org/SDL/blob/main/.github/actions/setup-harmonyos-toolchain/action.yml) 使用的 SDK 镜像；工具包约 2 GB，首次运行会较慢。升级时同时更改 `install_ohos_sdk.sh` 中的版本与校验值。
- CI 在临时检出目录清除 `ohos/build-profile.json5` 中的本机签名配置，保留产品、模块和 SDK 设置。先构建 unsigned HAP，再用 SDK 自带的 `hap-sign-tool.jar` 签名并验证，避免依赖 DevEco 本机 `material` 目录的加密口令。签名参数参见 [OpenHarmony 官方说明](https://gitee.com/openharmony/docs/blob/master/en/application-dev/security/hapsigntool-guidelines.md)。

## 配置签名 Secrets

在仓库 **Settings → Secrets and variables → Actions → New repository secret** 中添加。文件类值为整个文件内容的 Base64。密码填真实原始密码，不要填 DevEco `build-profile.json5` 中的加密十六进制串。签名文件只写入 runner 临时目录，任务结束清理，不进入缓存或构建产物。

### Android

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | 原发布 `.jks` 文件的 Base64 |
| `ANDROID_STORE_PASSWORD` | Keystore 密码 |
| `ANDROID_KEY_ALIAS` | 发布 Key Alias |
| `ANDROID_KEY_PASSWORD` | 对应 Key 密码 |

使用原有发布密钥，以便覆盖安装旧版本。CI 不读取个人电脑的 `android/key.properties`。

### iOS

| Secret | 内容 |
| --- | --- |
| `IOS_P12_BASE64` | Apple Distribution 证书及其私钥导出的 `.p12` 的 Base64 |
| `IOS_P12_PASSWORD` | 导出 P12 时设置的密码 |
| `IOS_TEAM_ID` | Apple Developer Team ID，本项目为 `6Z4232N2L9` |
| `IOS_APP_PROFILE_BASE64` | 主应用的 App Store Distribution `.mobileprovision` 的 Base64 |
| `IOS_WIDGET_PROFILE_BASE64` | 小组件的 App Store Distribution `.mobileprovision` 的 Base64 |

两份 Profile 需要分别对应：

- 主应用：`top.idealclover.wheretosleepinnju`
- 小组件：`top.idealclover.wheretosleepinnju.ScheduleWidgetExtension`

两个 App ID 均需启用现有 App Group `group.top.idealclover.wheretosleepinnju.group`。CI 校验 Profile 的 Team 与 Bundle ID，再按 target 分别配置手动签名；不会依赖 Xcode 登录账户或自动向 Apple 申请描述文件。若证书或 Profile 过期，需要更新对应 Secrets。

### HarmonyOS

| Secret | 内容 |
| --- | --- |
| `OHOS_CERT_BASE64` | 与应用密钥对应的签名证书 `.cer` 的 Base64 |
| `OHOS_PROFILE_BASE64` | 应用的已签名 `.p7b` Profile 的 Base64 |
| `OHOS_KEYSTORE_BASE64` | `.p12` Keystore 的 Base64 |
| `OHOS_KEY_ALIAS` | Keystore 中的应用密钥别名 |
| `OHOS_KEY_PASSWORD` | 密钥的原始密码 |
| `OHOS_STORE_PASSWORD` | Keystore 的原始密码 |

正式发布使用 Release Profile；若使用 Debug Profile，只能安装到其中登记的设备。应用 Bundle Name 为 `top.idealclover.wheretosleepinnju`（以 `ohos/AppScope/app.json5` 为准）。

## 在本机检查流程

```bash
actionlint .github/workflows/build.yml
bash -n tool/ci/bootstrap.sh tool/ci/install_ohos_sdk.sh
python3 -m py_compile tool/ci/configure_signing.py tool/ci/sign_ohos.py
ruby -c tool/ci/configure_ios_signing.rb
```

`bootstrap.sh` 与签名脚本面向 CI 的临时检出目录。特别是鸿蒙配置脚本会覆盖该检出目录的签名配置，请勿对日常开发目录直接执行。提交并推送 workflow 后，才会在 GitHub 产生真正的托管 runner 构建记录；本地检查不代表远端运行已通过。
