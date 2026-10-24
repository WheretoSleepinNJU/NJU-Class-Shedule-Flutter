# 更新记录

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
