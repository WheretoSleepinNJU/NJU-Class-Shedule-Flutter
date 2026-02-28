# 鸿蒙构建环境配置指南

## 前置要求

1. **DevEco Studio** 或 **Command Line Tools**
   - 下载地址: https://developer.harmonyos.com/cn/develop/deveco-studio
   - 推荐版本: 5.1.0 Beta1 或更新版本
   - 需要配置好 Java 17

2. **FVM** (Flutter Version Management)
   - 安装: `dart pub global activate fvm`
   - 或: `brew install fvm`

## 快速配置

### 1. 环境变量配置

项目已配置 `.envrc` 文件，如果使用 [direnv](https://direnv.net/)，进入项目目录时会自动加载环境变量：

```bash
# 安装 direnv (macOS)
brew install direnv

# 允许项目环境变量
direnv allow
```

或者手动加载：

```bash
source tool/setup_ohos_env.sh
```

如果 `fvm install` 在中国大陆网络失败，可开启国内镜像后重试：

```bash
export USE_CN_FLUTTER_MIRROR=1
source tool/setup_ohos_env.sh
```

### 2. 安装鸿蒙 Flutter

```bash
# 安装指定版本 (FVM 已配置为使用鸿蒙 Flutter 仓库)
fvm install oh-3.27.0-release

# 设置当前项目使用该版本
fvm use oh-3.27.0-release
```

### 3. 验证环境

```bash
# 检查 Flutter 环境
fvm flutter doctor -v

# 确保 Flutter 与 OpenHarmony 都显示为 ok
```

### 4. 安装依赖

```bash
# 获取 Flutter 依赖
fvm flutter pub get

# 确保 external 目录下的依赖已克隆
cd external
ls -la
# 应该包含: flutter_packages, flutter_plus_plugins, flutter_sqflite
```

## 构建应用

### 构建 HAP 包

```bash
# Debug 版本
fvm flutter build hap --debug --target-platform ohos-arm64

# Release 版本
fvm flutter build hap --release --target-platform ohos-arm64
```

构建产物位于: `ohos/entry/build/default/outputs/default/entry-default-signed.hap`

### 安装到设备

```bash
# 查看连接的设备
fvm flutter devices

# 运行到设备
fvm flutter run -d <device-id>

# 或使用 hdc 安装
hdc -t <device-id> install ohos/entry/build/default/outputs/default/entry-default-signed.hap
```

## 常见问题

### 1. 环境变量未生效

确保已正确配置 DevEco Studio 路径：

```bash
# 检查 DEVECO_SDK_HOME 是否设置
echo $DEVECO_SDK_HOME

# 检查相关工具是否在 PATH 中
which ohpm
which hvigorw
which node
```

### 2. Flutter doctor 显示 OpenHarmony 未配置

检查是否正确设置了鸿蒙 SDK 环境变量：

```bash
export TOOL_HOME=/Applications/DevEco-Studio.app/Contents
export DEVECO_SDK_HOME=$TOOL_HOME/sdk
export PATH=$TOOL_HOME/tools/ohpm/bin:$PATH
export PATH=$TOOL_HOME/tools/hvigor/bin:$PATH
export PATH=$TOOL_HOME/tools/node/bin:$PATH
```

### 3. 依赖下载失败

检查镜像配置：

```bash
export USE_CN_FLUTTER_MIRROR=1
source tool/setup_ohos_env.sh
```

### 4. 版本切换

如需切换回官方 Flutter 版本：

```bash
# 重置 FVM 为官方仓库
fvm config --flutter-url https://github.com/flutter/flutter.git

# 安装官方版本
fvm install 3.27.0
fvm use 3.27.0
```

## 参考文档

- [鸿蒙 Flutter 仓库](https://gitcode.com/openharmony-tpc/flutter_flutter/tree/oh-3.27.0-release)
- [鸿蒙 Flutter 三方库适配](https://gitcode.com/openharmony-tpc/flutter_packages)
- [DevEco Studio 官方文档](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/environment_config-0000001052902427-V3)
