# Widget 数据管道连接状态

## ✅ 已完成功能

### 1. 数据计算层（Flutter）
- ✅ **真实数据读取**：从 SQLite 数据库读取课程数据
- ✅ **课程分类**：使用现有 `ScheduleModel` 逻辑筛选活跃课程
- ✅ **时间计算**：当前周次、今日/明日课程、当前课程/下一节课
- ✅ **数据转换**：Course → WidgetCourse 格式转换
- ✅ **完整打包**：生成 `WidgetScheduleData` 包含所有 Widget 需要的信息

### 2. 数据传输层
- ✅ **MethodChannel 桥接**：`NativeDataBridge` 封装通信逻辑
- ✅ **数据序列化**：Dart → JSON → Swift 自动转换
- ✅ **App Group 存储**：iOS 端保存到共享 UserDefaults

### 3. 自动刷新机制
- ✅ **应用启动时**：`InitUtil.initialize()` 自动更新 Widget
- ✅ **课程添加后**：`AddCoursePresenter.addCourse()` 
- ✅ **课程删除后**：`CourseDeleteDialog` 
- ✅ **课程表切换**：`ClassTableStateModel.changeclassTable()`
- ✅ **周次变化**：`WeekStateModel.changeWeek()`

### 4. iOS 显示层
- ✅ **小组件 UI**：完整的 `SmallWidgetView` 实现
- ✅ **智能显示逻辑**：5种状态切换（上课前/即将上课/上课中/课程结束/明日预览）
- ✅ **课程卡片**：带颜色指示器和时间显示
- ✅ **"我已到达"按钮**：Live Activity 联动准备

### 5. 数据管道架构

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   SQLite DB     │────▶│  Flutter 计算层   │────▶│ MethodChannel   │
│ (CourseProvider)│     │(UnifiedDataService)│     │(NativeDataBridge)│
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  iOS Widget UI  │◀────│   App Group      │◀────│ iOS AppDelegate │
│ (SmallWidgetView)│     │ (UserDefaults)   │     │ (MethodChannel) │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## 📋 测试清单

### 手动测试步骤

1. **基础数据测试**
   - [ ] 应用启动后检查 Xcode 控制台是否显示 "Widget data initialized successfully"
   - [ ] 添加一门课程，检查是否显示 "Widget refreshed successfully after 课程添加"
   - [ ] 删除课程，检查刷新日志
   - [ ] 切换课程表，检查刷新日志

2. **Widget 显示测试**
   - [ ] 在 iOS 主屏添加小组件
   - [ ] 验证是否显示今日课程信息
   - [ ] 验证时间显示是否正确（格式：8:00 - 9:50）
   - [ ] 验证颜色是否正确应用

3. **状态切换测试**
   - [ ] 上课前：显示"下一节课"
   - [ ] 临近上课（15分钟内）：显示"即将上课" + "我已到达"按钮
   - [ ] 上课中：显示"正在上课"
   - [ ] 今日无课：显示"今日课程已结束"
   - [ ] 晚上21:00后：显示明日课程预览

4. **边界情况测试**
   - [ ] 无课程数据时的空状态
   - [ ] 超长课程名的截断处理
   - [ ] 跨天课程的处理
   - [ ] 不同学校时间模板的兼容性

## 🔍 调试方法

### 1. 查看 iOS 日志
```bash
# 在 Xcode 中运行应用，查看 Debug Area 控制台
# 寻找以下关键日志：
- "Widget data initialized successfully"
- "Widget refreshed successfully after..."
- "Received widget data: ..."
- "Widget data saved successfully"
```

### 2. 验证数据传输
```dart
// 在 Flutter 中添加调试代码
final service = UnifiedDataService(preferences: preferences);
final data = await service.getWidgetData();
print('Widget data: ${data.todayCourses.length} courses today');
print('Next course: ${data.nextCourse?.name ?? "None"}');
```

### 3. 检查 App Group 数据
```swift
// 在 iOS 中添加调试代码
let manager = WidgetDataManager.shared
manager.printAllData()
```

## 🎯 性能优化点

1. **缓存机制**：`UnifiedDataService` 有5分钟缓存，避免频繁计算
2. **平台检查**：仅在 iOS 平台执行 Widget 更新
3. **异步执行**：所有 Widget 刷新都是异步执行，不阻塞UI
4. **错误处理**：所有操作都有 try-catch，失败不影响主功能

## ⚠️ 已知限制

1. **仅支持 iOS**：Android Widget 需要单独实现
2. **时间模板硬编码**：目前仅支持南京大学和东南大学
3. **调试日志**：生产环境需要替换为正式日志框架
4. **Live Activities**：框架已搭建，具体功能需要进一步实现

## 🚀 下一步计划

1. **验证数据传输**：在真实设备上测试 Widget 显示
2. **Live Activities 实现**：完成课前提醒功能
3. **中/大组件**：实现其他尺寸的 Widget 布局
4. **锁屏 Widget**：实现 iOS 16+ 锁屏小组件
5. **错误监控**：添加数据传输失败的监控和重试机制

---

**状态：** 数据管道已完全连通 ✅  
**最后更新：** 2024-10-15  
**测试状态：** 待验证 🧪