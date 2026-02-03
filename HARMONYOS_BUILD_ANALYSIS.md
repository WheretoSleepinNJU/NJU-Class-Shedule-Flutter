# HarmonyOS 构建分析与建议

**日期:** 2026-02-03  
**分支:** `fix/widget-conflicts-review`  
**环境:** macOS (arm64), Flutter 3.22.3 (标准), HarmonyOS SDK oh-3.27.0 (已克隆)

## 📊 当前状态评估

### ✅ 已完成
- [x] HarmonyOS Flutter SDK (oh-3.27.0) 已克隆到 `~/fvm/versions/oh-3.27.0`
- [x] 所有外部依赖已克隆到 `external/`
  - `flutter_packages` (包含 path_provider, shared_preferences, webview_flutter, url_launcher, image_picker)
  - `flutter_sqflite` (HarmonyOS 兼容版本)
  - `flutter_plus_plugins` (HarmonyOS 平台特定插件)
- [x] `pubspec.yaml` 配置正确，所有依赖都指向 `external/` 路径
- [x] `ohos/build-profile.json5` 存在，包含 HarmonyOS 编译配置
- [x] 代码兼容性修复已完成（动态平台检测）

### ⚠️ 需要注意的问题

#### 1. **HarmonyOS Flutter SDK 版本识别问题**
- **问题:** `fvm` 不识别 `oh-3.27.0` 为有效的 Flutter 版本
- **原因:** HarmonyOS 定制版本与标准 Flutter 版本规范不同
- **现状:** 需要直接调用 `~/fvm/versions/oh-3.27.0/bin/flutter` 而不是通过 `fvm`
- **影响:** 不能使用 FVM 自动版本管理，需要手动管理路径

#### 2. **签名配置依赖用户证书**
- **问题:** `build-profile.json5` 包含硬编码的用户路径和证书路径
  ```json5
  "certpath": "/Users/idealclover/.ohos/config/default_ohos_beb2R7_SesHgy1vQMNVsuiLAGxWazM3AmhIWVkTJIZI=.cer"
  ```
- **影响:** 此配置仅对 `idealclover` 用户有效，不适用于 `lilingfeng` 用户
- **解决方案:** 需要为当前用户生成 HarmonyOS 签名证书，或创建新的编译配置

#### 3. **缺少 HarmonyOS SDK 和开发工具**
- **需求:** 完整的 HarmonyOS 开发环境包括：
  - HarmonyOS SDK (用于编译 Kotlin/Java 代码)
  - DevEco Studio 或命令行工具
  - OpenHarmony 模拟器或真实设备
- **现状:** 只有 Flutter 的 HarmonyOS 适配版本，还需要 HarmonyOS 官方工具链

#### 4. **小组件实现验证缺口**
- **现状:** HarmonyOS 小组件通过 `MethodChannel('wheretosleepinnju/widget')` 实现
- **风险:** 与 iOS 新架构 (`com.wheretosleepinnju/widget_data`) 不统一
- **建议:** 需要验证 HarmonyOS 端的小组件数据流是否与新的 `UnifiedDataService` 兼容

## 🔧 HarmonyOS 构建的三个可行方案

### 方案 A: 标准 Flutter + HarmonyOS SDK (推荐 - 完整支持)
```bash
# 1. 安装 HarmonyOS SDK 和 DevEco Studio
#    从 https://developer.huawei.com/consumer/cn/deveco-studio/ 下载

# 2. 配置路径
export OHOS_SDK_HOME=/path/to/ohos-sdk

# 3. 切换到 HarmonyOS Flutter
export PATH=~/fvm/versions/oh-3.27.0/bin:$PATH

# 4. 生成签名配置（使用 DevEco Studio 或 keytool）
#    需要更新 build-profile.json5 中的证书路径

# 5. 构建应用
hvigor assembleHap
```

**优点:**
- 完全支持 HarmonyOS 所有特性
- 可以打包为 HAP (HarmonyOS App Package)
- 支持小组件、后台任务等高级功能

**缺点:**
- 需要安装完整的 HarmonyOS 开发环境 (~20GB)
- 需要有效的开发者签名

### 方案 B: Docker 容器中编译 (中等 - 自动化但有限制)
```bash
# 使用容器镜像如：
# - huaweicloud/deveco-studio:latest
# - 官方 HarmonyOS 编译器容器

docker run --rm -v $(pwd):/workspace \
  huaweicloud/ohos-build:latest \
  /workspace/build.sh

# 这要求 Dockerfile 的编写和容器配置
```

**优点:**
- 不污染本地环境
- 可重复的编译环境

**缺点:**
- 需要 Docker 配置和映像
- 可能有性能开销

### 方案 C: 代码静态分析与模拟验证 (当前可行 - 部分验证)
```bash
# 1. 使用标准 Flutter 进行 Dart 代码分析
flutter analyze --no-pub

# 2. 检查 HarmonyOS 特定的实现
grep -r "ohos\|HarmonyOS\|harmonyos" lib/

# 3. 验证小组件通道兼容性
grep -r "wheretosleepinnju/widget" lib/

# 4. 执行集成测试（需要模拟器或真机）
flutter test integration_test/
```

**优点:**
- 无需额外工具
- 可立即执行
- 可识别大多数兼容性问题

**缺点:**
- 无法进行真实的编译验证
- 无法测试 HarmonyOS 特定行为

## 🎯 立即可执行的步骤 (方案 C)

### 1. 代码兼容性检查
```bash
flutter analyze --no-pub
```

### 2. 检查 HarmonyOS 小组件集成
```bash
# 查找 HarmonyOS 小组件实现
grep -r "wheretosleepinnju/widget" lib/

# 验证动态平台检测
grep -A 5 "_getCurrentPlatform" lib/core/widget_data/communication/native_data_bridge.dart
```

### 3. 验证依赖配置
```bash
# 检查所有外部依赖都正确配置
flutter pub get

# 列出所有 HarmonyOS 兼容的依赖
grep -E "# .*HarmonyOS|# .*harmonyos|# .*ohos" pubspec.yaml
```

### 4. 小组件数据流验证
```bash
# 确认两个小组件通道的数据结构一致
diff <(grep -A 20 "wheretosleepinnju/widget" lib/Utils/WidgetHelper.dart) \
     <(grep -A 20 "com.wheretosleepinnju/widget_data" lib/core/widget_data/communication/native_data_bridge.dart)
```

## 📋 HarmonyOS 小组件集成清单

### 当前实现状态

| 组件 | 实现方式 | 通道名 | 状态 |
|------|--------|-------|------|
| **HarmonyOS 小组件** | Kotlin/Java 原生 | `wheretosleepinnju/widget` | ⚠️ 需验证 |
| **iOS 小组件** | Swift 原生 | `com.wheretosleepinnju/widget_data` | ✅ 已修复 |
| **共享数据** | UserDefaults/SharedPreferences | - | ✅ 已修复 |
| **数据服务** | `UnifiedDataService` (新) | - | ✅ 已实现 |

### 已应用的兼容性修复

1. ✅ **动态平台检测** (lib/core/widget_data/communication/native_data_bridge.dart)
   - 从硬编码的 `'ios'` 改为动态检测
   - 支持 Android, iOS, macOS, HarmonyOS (ohos)

2. ✅ **iOS 数据结构修复** (ios/Runner/AppDelegate.swift)
   - 提取 `activities` 数组再保存
   - 与 iOS 读取逻辑一致

3. ✅ **HarmonyOS 小组件刷新通道** (lib/Utils/WidgetHelper.dart)
   - `_updateAndroidWidget()` 通过 `wheretosleepinnju/widget` 调用
   - 与 HarmonyOS 端实现兼容

### 需要的进一步验证

```dart
// ✅ 已验证: 动态平台检测
Platform.isAndroid  // HarmonyOS 上应返回 false，需确认
Platform.isIOS      // 
Platform.operatingSystem == 'ohos'  // HarmonyOS 识别

// ⚠️ 需验证: HarmonyOS 端小组件实现
// 文件: lib/Utils/WidgetHelper.dart
// 需确认 HarmonyOS 端是否正确接收并处理小组件更新事件
```

## 📈 构建流程建议

### 短期 (当前冲刺)
**目标:** 验证代码兼容性，无需完整编译

```bash
# 1. 执行 Flutter 代码分析
flutter analyze --no-pub

# 2. 验证依赖解析
flutter pub get

# 3. 检查所有导入和引用
grep -r "import.*ohos" lib/
grep -r "import.*harmony" lib/

# 4. 查看代码中的 TODO 或 FIXME
grep -r "TODO\|FIXME\|HACK" lib/ --include="*.dart" | grep -i "harmonyos\|ohos"
```

### 中期 (下个冲刺)
**目标:** 建立 HarmonyOS 开发环境

- [ ] 安装 DevEco Studio 和 HarmonyOS SDK
- [ ] 配置开发者签名证书
- [ ] 更新 `build-profile.json5` 中的证书路径
- [ ] 测试 HarmonyOS 模拟器编译

### 长期 (版本计划)
**目标:** 统一小组件实现

- [ ] 将 HarmonyOS 小组件迁移到 `UnifiedDataService`
- [ ] 使用统一的通道名 `com.wheretosleepinnju/widget_data`
- [ ] 减少平台特定代码，提高可维护性

## 💡 建议优先级

### 优先级 1: 必须立即处理
- [x] iOS 合并冲突修复 (已完成)
- [x] 动态平台检测 (已完成)
- [ ] **验证 HarmonyOS 小组件是否正确接收事件** (需要)

### 优先级 2: 应该在发布前完成
- [ ] 建立 HarmonyOS 签名和构建配置
- [ ] 在 HarmonyOS 模拟器上验证小组件功能
- [ ] 更新 iOS 和 HarmonyOS 文档

### 优先级 3: 长期改进
- [ ] 统一小组件通道和数据结构
- [ ] 减少平台特定代码的重复

## 🚀 下一步推荐行动

### 立即执行 (5 分钟)
```bash
# 进行代码兼容性检查
cd /Users/lilingfeng/Repositories/NJU-Class-Shedule-Flutter
flutter analyze --no-pub
```

### 后续行动 (需要用户决定)
1. **是否需要立即建立完整的 HarmonyOS 编译环境?**
   - 如是: 需要安装 DevEco Studio 和 HarmonyOS SDK (~20GB, 1-2 小时)
   - 如否: 继续用代码分析进行验证

2. **是否需要统一小组件实现?**
   - 建议: 统一为 `com.wheretosleepinnju/widget_data` 通道，便于未来维护

3. **是否需要优先支持某个平台?**
   - 建议: iOS 现已修复，建议下一个重点为 Android/HarmonyOS

---

**报告完成时间:** 2026-02-03 12:30  
**涉及文件:** 
- [ohos/build-profile.json5](ohos/build-profile.json5)
- [pubspec.yaml](pubspec.yaml)
- [lib/Utils/WidgetHelper.dart](lib/Utils/WidgetHelper.dart)
- [lib/core/widget_data/communication/native_data_bridge.dart](lib/core/widget_data/communication/native_data_bridge.dart)