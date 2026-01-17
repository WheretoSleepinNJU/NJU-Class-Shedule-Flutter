# umeng_common_sdk Flutter Plugin

# 安装

在工程 pubspec.yaml 中加入 dependencies

dependencies:
  umeng_common_sdk: 1.2.4

# 使用

import 'package:umeng_common_sdk/umeng_common_sdk.dart';

**注意** : 需要先调用 UMConfigure.init 来初始化插件（Appkey可在统计后台 “管理->应用管理->应用列表” 页面查看，或在 “我的产品”选择某应用->设置->应用信息 查看Appkey），才能保证其他功能正常工作。