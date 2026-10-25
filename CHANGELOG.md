# 更新记录

## 4.1.0 (71) — 2026-10-25

- [#3](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/3)、[#48](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/48)：支持课程编辑、删除，以及一门课程多个时段的识别、添加、修改和整体保存；详情采用主题卡片，点击空白处关闭。
- [#47](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/47)：导入页标题点击五次开启测试模式，可填写 URL、预处理、延时和提取脚本，复用真实导入流程。
- [#68](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/68)：课表管理支持修改名称，保留课程、作息和学期设置。
- [#77](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/77)（部分）：支持每个时段分别选择任意周次、教室和教师；该议题其余需求未全部覆盖。
- 移除导入页旧内置入口和冗余说明，补充网络异常、空学校列表与重试状态；测试脚本错误直接展示，导入结果以事务保存。
- Android、鸿蒙小组件增加两种尺寸、实际预览、不透明浅深背景及完整课程滚动；鸿蒙同步补充跨天、跨周和无课状态。
- 优化编辑页周次等宽布局、“自由时间/时间待定”文案，以及深色课表管理的选中样式。
- 修复 iOS 27 上未采用 UIScene 生命周期导致的启动终止；迁移插件和小组件通道初始化，保留冷/热 URL 回调。对应 Organizer 崩溃点：`C2X63xhDJ3_94Zsq7Zv-sH`。
- 修复损坏的启动配色、周次和主题偏好，以及评分配置网络请求失败时的异常；iOS 正式包构建号升至 71。
- iOS 签名 CI 增加导出 IPA 的 Scene 配置、AOT、证书/Profile、App Group 和主应用/扩展版本校验。

验证：96 项 Flutter 回归通过；三端课程管理和导入实测通过；Android/鸿蒙桌面卡片均滚动到第 12 门课。
iOS 26.4/27.0 Debug 模拟器各完成五次冷启动及前后台恢复，27.0 原生插件、设置、小组件读写和链接回调验证通过。
iOS App Store IPA 的签名、AOT、证书和 dSYM UUID 检查通过；当前没有真机，正式 IPA 的真机/TestFlight 运行尚待复测。

## 4.1.0 (70) — 2026-10-24

本版包含的 GitHub 问题修复（已实现在前序提交 `5df852490`）：

- [#69](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/69)：导出系统日历时正确写入上课地点。
- [#71](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/71)：iOS 小组件排除仅在其他周上课的课程。
- [#76](https://github.com/WheretoSleepinNJU/NJU-Class-Shedule-Flutter/issues/76)：修复 iOS 小组件跨零点使用陈旧数据误报“今日课程已结束”。

本次发布新增修复：

- 清华研究生导入配置改走 WebVPN 信息门户与教学日历，兼容旧客户端，并合并同周、同日、同教室的相邻相同课程。
- 冲突课程显示数量圆标，保留卡片圆角；优化正文留白，圆标不再挤占正文位置。
- 系统字号变化时重新计算课表行高、列宽。
- Android 底部系统导航栏保持透明，手势条随明暗模式调整。
- 主应用、iOS 小组件及鸿蒙应用版本统一为 4.1.0，构建号为 70。
- iOS 主应用最低系统升至 iOS 15，小组件仍需 iOS 17；移除小组件固定引用的本机签名描述文件。
- 新增 GitHub Actions 三端构建、回归测试及可选发布签名，自动保存产物与 SHA-256 校验值。
