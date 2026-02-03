# Widget 与 Live Activity 架构重构方案

## 1. 背景与问题分析

### 1.1 当前架构问题

#### Widget 层问题
- **数据过时**：Flutter 预计算 `currentCourse`/`nextCourse`，Widget Timeline 刷新时数据已过期
- **计算逻辑分散**：Flutter 和 iOS 两端都有时间计算逻辑，易不一致
- **Timeline 策略复杂**：预生成未来状态，但数据基于发送时刻的快照

#### Live Activity 层问题
- **触发机制错误**：依赖 Widget Timeline 刷新创建，不可靠
- **数据模型设计错误**：`ContentState` 包含过多静态数据
- **iOS 限制未处理**：iOS 不支持本地 schedule，必须应用前台或推送才能创建

### 1.2 根本原因
当前架构试图让 Flutter 控制一切，但 Widget 和 Live Activity 有截然不同的生命周期：
- **Widget**：系统控制刷新时机，应用无法干预
- **Live Activity**：应用主动控制，但 iOS 限制创建时机

## 2. 重构目标

1. **Widget 独立化**：作为"微应用"独立运行，自己计算显示状态
2. **Live Activity 平台适配**：iOS 采用"前台主动管理 + 本地通知 fallback"
3. **数据统一**：Flutter 只提供原始数据，不预计算状态
4. **降低复杂度**：删除冗余代码，明确责任边界

## 3. 架构设计

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter 层（数据层）                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │   UnifiedDataService                                │   │
│  │   - 提供原始课程数据                                │   │
│  │   - 提供时间模板                                    │   │
│  │   - 计算 Live Activity 触发时机（应用前台时）       │   │
│  └─────────────────────────────────────────────────────┘   │
│                         │                                   │
│                         ▼                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │   NativeDataBridge                                  │   │
│  │   - sendWidgetData(rawData)                         │   │
│  │   - startOrUpdateLiveActivity(activityData)         │   │
│  │   - endLiveActivity()                               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
┌───────────────────────┐       ┌───────────────────────────────┐
│   iOS Widget          │       │   iOS Live Activity           │
│   （独立进程）        │       │   （应用控制）                │
│                       │       │                               │
│   - 从 App Group 读取 │       │   - 应用前台时创建/更新       │
│   - 自己计算状态      │       │   - 本地通知提醒用户打开      │
│   - Timeline 刷新展示 │       │   - 倒计时更新                │
└───────────────────────┘       └───────────────────────────────┘
```

### 3.2 数据流对比

#### 重构前
```
Flutter 计算状态 → 发送预计算数据 → Widget 展示（可能已过时）
                → Widget 刷新时创建 Live Activity（不可靠）
```

#### 重构后
```
Flutter 发送原始数据 → Widget 自己计算状态展示
Flutter 应用前台时检查 → 符合条件的创建 Live Activity
                     → 不符合的发送本地通知提醒
```

## 4. 详细修改方案

### 4.1 数据模型修改

#### 4.1.1 WidgetScheduleData（删除预计算字段）

```dart
class WidgetScheduleData {
  final String version = '2.0';  // 版本升级
  final DateTime timestamp;
  final String schoolId;
  final String schoolName;
  final SchoolTimeTemplate timeTemplate;  // 关键：时间模板
  final int currentWeek;
  final int currentWeekDay;
  final String semesterName;
  
  // 原始课程数据（排序后）
  final List<WidgetCourse> todayCourses;
  final List<WidgetCourse> tomorrowCourses;
  
  // 可选：保留本周课表用于大型组件
  final Map<int, List<WidgetCourse>>? weekSchedule;
  
  // 配置
  final int approachingMinutes;
  final int tomorrowPreviewHour;
  
  // ❌ 删除以下字段
  // final WidgetCourse? nextCourse;
  // final WidgetCourse? currentCourse;
  // final int todayCourseCount;  // 改为计算属性
  
  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'schoolId': schoolId,
    'schoolName': schoolName,
    'timeTemplate': timeTemplate.toJson(),
    'currentWeek': currentWeek,
    'currentWeekDay': currentWeekDay,
    'semesterName': semesterName,
    'todayCourses': todayCourses.map((c) => c.toJson()).toList(),
    'tomorrowCourses': tomorrowCourses.map((c) => c.toJson()).toList(),
    if (weekSchedule != null)
      'weekSchedule': weekSchedule.map((k, v) => 
        MapEntry(k.toString(), v.map((c) => c.toJson()).toList())
      ),
    'approachingMinutes': approachingMinutes,
    'tomorrowPreviewHour': tomorrowPreviewHour,
  };
}
```

#### 4.1.2 LiveActivityData（精简动态数据）

```dart
class LiveActivityData {
  final String courseId;
  final String courseName;
  final String? classroom;
  final String? teacher;
  final DateTime startTime;
  final DateTime endTime;
  final String? color;
  final String? motivationalTextLeft;
  final String? motivationalTextRight;
  
  // 只有这两个是动态更新的
  final int secondsRemaining;
  final String status; // 'upcoming' | 'startingSoon'
  
  LiveActivityData({
    required this.courseId,
    required this.courseName,
    this.classroom,
    this.teacher,
    required this.startTime,
    required this.endTime,
    this.color,
    this.motivationalTextLeft,
    this.motivationalTextRight,
    required this.secondsRemaining,
    required this.status,
  });
  
  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'courseName': courseName,
    'classroom': classroom,
    'teacher': teacher,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'color': color,
    'motivationalTextLeft': motivationalTextLeft,
    'motivationalTextRight': motivationalTextRight,
    'secondsRemaining': secondsRemaining,
    'status': status,
  };
}
```

### 4.2 Flutter 层修改

#### 4.2.1 UnifiedDataService

```dart
class UnifiedDataService {
  final SharedPreferences _preferences;
  
  UnifiedDataService({required SharedPreferences preferences})
    : _preferences = preferences;
  
  /// 获取 Widget 原始数据
  Future<WidgetScheduleData> getWidgetData() async {
    // 1. 获取当前课程表 ID 和周次
    final tableId = _preferences.getInt('tableId') ?? 0;
    final currentWeek = _preferences.getInt('weekIndex') ?? 1;
    
    // 2. 获取时间模板
    final timeTemplate = await _getTimeTemplate(tableId);
    
    // 3. 获取所有课程
    final allCourses = await _getAllCourses(tableId);
    
    // 4. 使用 ScheduleModel 分类
    final scheduleModel = ScheduleModel(allCourses, currentWeek);
    scheduleModel.init();
    
    // 5. 获取本周课程（active + multi）
    final activeCourses = [
      ...scheduleModel.activeCourses,
      ...scheduleModel.multiCourses.map((list) => list[0]),
    ];
    
    // 6. 筛选今日课程
    final currentWeekDay = DateTime.now().weekday;
    final todayCourses = _filterAndSortCourses(activeCourses, currentWeekDay);
    
    // 7. 筛选明日课程
    final tomorrowWeekDay = currentWeekDay == 7 ? 1 : currentWeekDay + 1;
    final tomorrowCourses = _getTomorrowCourses(
      allCourses, 
      currentWeek, 
      tomorrowWeekDay
    );
    
    // 8. 返回原始数据（不计算 current/next）
    return WidgetScheduleData(
      timestamp: DateTime.now(),
      schoolId: timeTemplate.schoolId,
      schoolName: timeTemplate.schoolName,
      timeTemplate: timeTemplate,
      currentWeek: currentWeek,
      currentWeekDay: currentWeekDay,
      semesterName: await _getSemesterName(tableId),
      todayCourses: todayCourses,
      tomorrowCourses: tomorrowCourses,
      approachingMinutes: _preferences.getInt('widgetApproachingMinutes') ?? 15,
      tomorrowPreviewHour: _preferences.getInt('widgetTomorrowPreviewHour') ?? 21,
    );
  }
  
  /// 获取当前应显示的 Live Activity 数据
  /// 返回 null 表示没有符合条件的课程
  Future<LiveActivityData?> getCurrentLiveActivityData() async {
    final widgetData = await getWidgetData();
    final now = DateTime.now();
    
    // 找到下一节课
    final nextCourse = _findNextCourse(
      widgetData.todayCourses, 
      now, 
      widgetData.timeTemplate
    );
    
    if (nextCourse == null) return null;
    
    // 计算距离上课还有多久
    final secondsRemaining = _calculateSecondsUntil(
      nextCourse, 
      now, 
      widgetData.timeTemplate
    );
    
    // 只在课前15分钟内返回
    if (secondsRemaining <= 0 || secondsRemaining > 15 * 60) {
      return null;
    }
    
    final startTime = _getCourseStartTime(nextCourse, widgetData.timeTemplate);
    final endTime = _getCourseEndTime(nextCourse, widgetData.timeTemplate);
    
    return LiveActivityData(
      courseId: nextCourse.id,
      courseName: nextCourse.name,
      classroom: nextCourse.classroom,
      teacher: nextCourse.teacher,
      startTime: startTime,
      endTime: endTime,
      color: nextCourse.color,
      motivationalTextLeft: _preferences.getString('liveActivityTextLeft') ?? '好好学习',
      motivationalTextRight: _preferences.getString('liveActivityTextRight') ?? '天天向上',
      secondsRemaining: secondsRemaining,
      status: secondsRemaining <= 300 ? 'startingSoon' : 'upcoming',
    );
  }
  
  // 辅助方法
  List<WidgetCourse> _filterAndSortCourses(List<Course> courses, int weekDay) {
    return courses
      .where((c) => c.weekTime == weekDay)
      .sorted((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0))
      .map((c) => WidgetCourse.fromCourse(c, schoolId))
      .toList();
  }
  
  WidgetCourse? _findNextCourse(
    List<WidgetCourse> todayCourses, 
    DateTime now, 
    SchoolTimeTemplate template
  ) {
    final currentPeriod = _getCurrentPeriod(now, template);
    
    for (final course in todayCourses) {
      if (course.startPeriod > currentPeriod) {
        return course;
      }
    }
    return null;
  }
  
  int _calculateSecondsUntil(
    WidgetCourse course, 
    DateTime now, 
    SchoolTimeTemplate template
  ) {
    final period = template.getPeriodRange(course.startPeriod, course.periodCount);
    if (period == null) return 0;
    
    final startTime = _parseTimeOnDate(period.startTime, now);
    if (startTime == null) return 0;
    
    return startTime.difference(now).inSeconds;
  }
}
```

#### 4.2.2 NativeDataBridge 扩展

```dart
class NativeDataBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.wheretosleepinnju/widget_data'
  );
  
  // 原有方法
  Future<bool> sendWidgetData(WidgetScheduleData data) async {
    try {
      final result = await _channel.invokeMethod('sendWidgetData', {
        'data': data.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      return result == true;
    } catch (e) {
      print('发送 Widget 数据失败: $e');
      return false;
    }
  }
  
  // 新增：创建或更新 Live Activity
  Future<bool> startOrUpdateLiveActivity(LiveActivityData data) async {
    if (!Platform.isIOS) return false; // 目前仅 iOS 支持
    
    try {
      final result = await _channel.invokeMethod('startOrUpdateLiveActivity', {
        'data': data.toJson(),
      });
      return result == true;
    } catch (e) {
      print('创建/更新 Live Activity 失败: $e');
      return false;
    }
  }
  
  // 新增：结束 Live Activity
  Future<bool> endLiveActivity() async {
    if (!Platform.isIOS) return false;
    
    try {
      final result = await _channel.invokeMethod('endLiveActivity');
      return result == true;
    } catch (e) {
      print('结束 Live Activity 失败: $e');
      return false;
    }
  }
  
  // 新增：发送本地通知（用于提醒用户打开应用）
  Future<bool> scheduleLocalNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!Platform.isIOS) return false;
    
    try {
      final result = await _channel.invokeMethod('scheduleLocalNotification', {
        'id': id,
        'title': title,
        'body': body,
        'scheduledDate': scheduledDate.toIso8601String(),
      });
      return result == true;
    } catch (e) {
      print('发送本地通知失败: $e');
      return false;
    }
  }
}
```

#### 4.2.3 WidgetRefreshHelper 扩展

```dart
class WidgetRefreshHelper {
  static UnifiedDataService? _cachedService;
  
  static Future<UnifiedDataService> _getService() async {
    if (_cachedService != null) return _cachedService!;
    final preferences = await SharedPreferences.getInstance();
    _cachedService = UnifiedDataService(preferences: preferences);
    return _cachedService!;
  }
  
  // 原有的 Widget 刷新
  static Future<void> refreshAfterCourseAdded() async =>
    _refreshWidget('课程添加');
  static Future<void> refreshAfterCourseDeleted() async =>
    _refreshWidget('课程删除');
  static Future<void> refreshAfterCourseUpdated() async =>
    _refreshWidget('课程更新');
  static Future<void> refreshAfterTableChanged() async =>
    _refreshWidget('课程表切换');
  static Future<void> refreshAfterWeekChanged() async =>
    _refreshWidget('周次变化');
  
  static Future<void> _refreshWidget(String reason) async {
    try {
      if (!Platform.isIOS) return;
      
      final service = await _getService();
      service.clearCache();
      
      final data = await service.getWidgetData();
      final success = await NativeDataBridge().sendWidgetData(data);
      
      if (success) {
        print('Widget refreshed successfully after $reason');
      } else {
        print('Failed to refresh widget after $reason');
      }
    } catch (e) {
      print('Error refreshing widget after $reason: $e');
    }
  }
  
  // 新增：检查并更新 Live Activity（应用进入前台时调用）
  static Future<void> checkLiveActivity() async {
    try {
      if (!Platform.isIOS) return;
      
      final service = await _getService();
      final activityData = await service.getCurrentLiveActivityData();
      
      if (activityData != null) {
        // 创建或更新 Live Activity
        await NativeDataBridge().startOrUpdateLiveActivity(activityData);
        print('Live Activity created/updated for ${activityData.courseName}');
      } else {
        // 没有符合条件的课程，结束 Live Activity
        await NativeDataBridge().endLiveActivity();
        print('Live Activity ended (no upcoming course)');
      }
    } catch (e) {
      print('Error checking Live Activity: $e');
    }
  }
  
  // 新增：预约本地通知提醒（当无法创建 Live Activity 时）
  static Future<void> scheduleCourseReminders() async {
    try {
      if (!Platform.isIOS) return;
      
      final service = await _getService();
      final widgetData = await service.getWidgetData();
      final now = DateTime.now();
      
      // 找到下一节课
      final nextCourse = _findNextCourse(
        widgetData.todayCourses, 
        now, 
        widgetData.timeTemplate
      );
      
      if (nextCourse == null) return;
      
      final startTime = _getCourseStartTime(nextCourse, widgetData.timeTemplate);
      final reminderTime = startTime.subtract(Duration(minutes: 15));
      
      // 如果提醒时间在未来，发送本地通知
      if (reminderTime.isAfter(now)) {
        await NativeDataBridge().scheduleLocalNotification(
          id: 'course_reminder_${nextCourse.id}',
          title: '即将上课',
          body: '${nextCourse.name} 15分钟后在 ${nextCourse.classroom ?? '待定'} 开始',
          scheduledDate: reminderTime,
        );
        print('Scheduled local notification for ${nextCourse.name} at $reminderTime');
      }
    } catch (e) {
      print('Error scheduling course reminders: $e');
    }
  }
  
  static void clearCache() {
    _cachedService = null;
  }
}
```

#### 4.2.4 应用生命周期监听

```dart
// lib/main.dart 或专门的 AppLifecycleManager

class AppLifecycleManager extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用进入前台
        _onAppForeground();
        break;
      case AppLifecycleState.paused:
        // 应用进入后台
        _onAppBackground();
        break;
      default:
        break;
    }
  }
  
  void _onAppForeground() {
    print('App entered foreground');
    
    // 检查 Live Activity
    WidgetRefreshHelper.checkLiveActivity();
  }
  
  void _onAppBackground() {
    print('App entered background');
    
    // 预约本地通知（确保用户即使不打开应用也能收到提醒）
    WidgetRefreshHelper.scheduleCourseReminders();
  }
}

// 在 main.dart 中注册
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final lifecycleManager = AppLifecycleManager();
  WidgetsBinding.instance.addObserver(lifecycleManager);
  
  runApp(MyApp());
}
```

### 4.3 iOS Widget 层修改

#### 4.3.1 ScheduleEntry（计算属性版本）

```swift
// ios/ScheduleWidget/ScheduleWidget.swift

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let todayCourses: [WidgetCourse]
    let tomorrowCourses: [WidgetCourse]
    let timeTemplate: SchoolTimeTemplate
    let approachingMinutes: Int
    let tomorrowPreviewHour: Int
    let relevance: TimelineEntryRelevance?
    
    // MARK: - 计算属性（实时计算）
    
    /// 指定时间的当前课程
    func currentCourse(at date: Date) -> WidgetCourse? {
        for course in todayCourses {
            guard let period = timeTemplate.getPeriodRange(
                startPeriod: course.startPeriod,
                periodCount: course.periodCount
            ) else { continue }
            
            guard let startTime = parseTime(period.startTime, on: date),
                  let endTime = parseTime(period.endTime, on: date) else {
                continue
            }
            
            if date >= startTime && date < endTime {
                return course
            }
        }
        return nil
    }
    
    /// 指定时间的下一节课
    func nextCourse(at date: Date) -> WidgetCourse? {
        for course in todayCourses {
            guard let period = timeTemplate.getPeriodRange(
                startPeriod: course.startPeriod,
                periodCount: course.periodCount
            ) else { continue }
            
            guard let startTime = parseTime(period.startTime, on: date) else {
                continue
            }
            
            if startTime > date {
                return course
            }
        }
        return nil
    }
    
    /// 指定时间的显示状态
    func displayState(at date: Date) -> WidgetDisplayState {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        
        // 晚上显示明日预览
        if currentHour >= tomorrowPreviewHour && !tomorrowCourses.isEmpty {
            return .tomorrowPreview
        }
        
        // 正在上课
        if currentCourse(at: date) != nil {
            return .inClass
        }
        
        // 检查是否即将上课
        if let next = nextCourse(at: date) {
            if let minutesUntil = minutesUntilCourse(next, at: date) {
                if minutesUntil > 0 && minutesUntil <= approachingMinutes {
                    return .approachingClass
                }
            }
            
            // 判断是第一节课前还是课间
            if todayCourses.first?.id == next.id {
                return .beforeFirstClass
            } else {
                return .betweenClasses
            }
        }
        
        return .classesEnded
    }
    
    // MARK: - Helper Methods
    
    private func parseTime(_ timeString: String, on date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: components.hour ?? 0,
                            minute: components.minute ?? 0,
                            second: 0,
                            of: date)
    }
    
    private func minutesUntilCourse(_ course: WidgetCourse, at date: Date) -> Int? {
        guard let period = timeTemplate.getPeriodRange(
            startPeriod: course.startPeriod,
            periodCount: course.periodCount
        ),
        let startTime = parseTime(period.startTime, on: date) else {
            return nil
        }
        return Calendar.current.dateComponents([.minute], from: date, to: startTime).minute
    }
}
```

#### 4.3.2 Provider（简化版）

```swift
struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            todayCourses: WidgetPreviewData.sampleCourses,
            tomorrowCourses: [],
            timeTemplate: WidgetPreviewData.njuTimeTemplate,
            approachingMinutes: 15,
            tomorrowPreviewHour: 21,
            relevance: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(loadEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentEntry = loadEntry()
        var entries: [ScheduleEntry] = [currentEntry]
        
        // 计算未来状态转换点
        if !currentEntry.todayCourses.isEmpty {
            let transitionDates = calculateTransitionPoints(from: Date(), entry: currentEntry)
            
            for date in transitionDates.prefix(9) {
                entries.append(ScheduleEntry(
                    date: date,
                    todayCourses: currentEntry.todayCourses,
                    tomorrowCourses: currentEntry.tomorrowCourses,
                    timeTemplate: currentEntry.timeTemplate,
                    approachingMinutes: currentEntry.approachingMinutes,
                    tomorrowPreviewHour: currentEntry.tomorrowPreviewHour,
                    relevance: calculateRelevance(for: date, entry: currentEntry)
                ))
            }
        }
        
        // ❌ 删除 Live Activity 相关代码
        
        let nextRefresh = calculateNextRefreshDate()
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        completion(timeline)
    }
    
    // MARK: - Data Loading
    
    private func loadEntry() -> ScheduleEntry {
        guard let rawData = WidgetDataManager.shared.loadRawData() else {
            // 返回空数据 Entry
            return ScheduleEntry(
                date: Date(),
                todayCourses: [],
                tomorrowCourses: [],
                timeTemplate: SchoolTimeTemplate.default,
                approachingMinutes: 15,
                tomorrowPreviewHour: 21,
                relevance: TimelineEntryRelevance(score: 0)
            )
        }
        
        return ScheduleEntry(
            date: Date(),
            todayCourses: rawData.todayCourses,
            tomorrowCourses: rawData.tomorrowCourses,
            timeTemplate: rawData.timeTemplate,
            approachingMinutes: rawData.approachingMinutes,
            tomorrowPreviewHour: rawData.tomorrowPreviewHour,
            relevance: calculateRelevance(for: Date(), entry: nil)
        )
    }
    
    // MARK: - Timeline Calculation
    
    private func calculateTransitionPoints(from startDate: Date, entry: ScheduleEntry) -> [Date] {
        var points: [Date] = []
        let calendar = Calendar.current
        
        for course in entry.todayCourses {
            guard let period = entry.timeTemplate.getPeriodRange(
                startPeriod: course.startPeriod,
                periodCount: course.periodCount
            ) else { continue }
            
            // 课程开始时间
            if let startTime = parseTime(period.startTime, on: startDate),
               startTime > startDate {
                points.append(startTime)
                
                // 即将上课提醒点
                if let approachingTime = calendar.date(
                    byAdding: .minute,
                    value: -entry.approachingMinutes,
                    to: startTime
                ), approachingTime > startDate {
                    points.append(approachingTime)
                }
            }
            
            // 课程结束时间
            if let endTime = parseTime(period.endTime, on: startDate),
               endTime > startDate {
                points.append(endTime)
            }
        }
        
        // 明日预览时间
        if let previewTime = calendar.date(
            bySettingHour: entry.tomorrowPreviewHour,
            minute: 0,
            second: 0,
            of: startDate
        ), previewTime > startDate {
            points.append(previewTime)
        }
        
        // 明天凌晨
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: startDate)) {
            points.append(tomorrow)
        }
        
        return Array(Set(points))
            .filter { $0 > startDate }
            .sorted()
            .filterWithMinInterval(300) // 5分钟最小间隔
    }
    
    private func calculateRelevance(for date: Date, entry: ScheduleEntry?) -> TimelineEntryRelevance? {
        guard let entry = entry else { return nil }
        let state = entry.displayState(at: date)
        
        switch state {
        case .inClass:
            return TimelineEntryRelevance(score: 100, duration: 60)
        case .approachingClass:
            if let next = entry.nextCourse(at: date),
               let minutes = entry.minutesUntilCourse(next, at: date) {
                let score = Float(max(25, 100 - (minutes * 5)))
                return TimelineEntryRelevance(score: score)
            }
            return TimelineEntryRelevance(score: 50)
        case .beforeFirstClass, .betweenClasses:
            return TimelineEntryRelevance(score: 20)
        case .tomorrowPreview:
            return TimelineEntryRelevance(score: 5)
        case .classesEnded, .error:
            return TimelineEntryRelevance(score: 0)
        }
    }
    
    private func calculateNextRefreshDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 明天凌晨 0:00 + 随机 jitter
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            let jitter = Int.random(in: 0..<300) // 0-5分钟
            return calendar.date(byAdding: .second, value: jitter, to: tomorrow) ?? tomorrow
        }
        
        return calendar.date(byAdding: .hour, value: 1, to: now) ?? now
    }
}
```

#### 4.3.3 视图层适配

视图层需要使用 entry 的计算属性而不是预计算字段：

```swift
// ios/ScheduleWidget/Views/SmallWidgetView.swift

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        // 实时计算状态
        let currentCourse = entry.currentCourse(at: entry.date)
        let nextCourse = entry.nextCourse(at: entry.date)
        let displayState = entry.displayState(at: entry.date)
        
        VStack(alignment: .leading, spacing: 8) {
            switch displayState {
            case .inClass:
                if let course = currentCourse {
                    CurrentCourseView(course: course)
                }
            case .approachingClass:
                if let course = nextCourse {
                    ApproachingCourseView(course: course)
                }
            case .beforeFirstClass:
                if let course = nextCourse {
                    NextCourseView(course: course, isFirst: true)
                }
            case .betweenClasses:
                if let course = nextCourse {
                    NextCourseView(course: course, isFirst: false)
                }
            case .classesEnded:
                ClassesEndedView()
            case .tomorrowPreview:
                TomorrowPreviewView(courses: entry.tomorrowCourses)
            case .error:
                ErrorView()
            }
        }
    }
}
```

### 4.4 iOS Live Activity 独立管理

#### 4.4.1 LiveActivityManager（单例）

```swift
// ios/Runner/LiveActivityManager.swift

import ActivityKit
import Foundation

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<CourseActivityAttributes>?
    private var updateTimer: Timer?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 开始或更新 Live Activity（由 Flutter 调用）
    func startOrUpdateLiveActivity(data: LiveActivityData) {
        // 检查是否已存在同课程的 Activity
        if let existingActivity = currentActivity,
           existingActivity.attributes.courseId == data.courseId,
           existingActivity.activityState == .active {
            // 更新现有 Activity
            updateLiveActivity(data: data)
        } else {
            // 结束旧的，创建新的
            endCurrentActivity()
            createNewActivity(data: data)
        }
    }
    
    /// 结束 Live Activity（由 Flutter 调用或课程开始后自动结束）
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            self.currentActivity = nil
            self.stopUpdateTimer()
            print("🛑 [LiveActivity] Ended")
        }
    }
    
    /// 检查是否有活跃的 Activity
    func hasActiveActivity() -> Bool {
        guard let activity = currentActivity else { return false }
        return activity.activityState == .active
    }
    
    // MARK: - Private Methods
    
    private func createNewActivity(data: LiveActivityData) {
        let attributes = CourseActivityAttributes(
            courseId: data.courseId,
            courseName: data.courseName,
            classroom: data.classroom,
            teacher: data.teacher,
            startTime: data.startTime,
            endTime: data.endTime,
            color: data.color,
            motivationalTextLeft: data.motivationalTextLeft ?? "好好学习",
            motivationalTextRight: data.motivationalTextRight ?? "天天向上"
        )
        
        let contentState = CourseActivityAttributes.ContentState(
            secondsRemaining: data.secondsRemaining,
            status: data.status == "startingSoon" ? .startingSoon : .upcoming
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            
            print("✅ [LiveActivity] Started for: \(data.courseName)")
            
            // 启动定时器每秒更新倒计时
            startUpdateTimer()
            
        } catch {
            print("❌ [LiveActivity] Failed to start: \(error)")
        }
    }
    
    private func updateLiveActivity(data: LiveActivityData) {
        guard let activity = currentActivity else { return }
        
        let contentState = CourseActivityAttributes.ContentState(
            secondsRemaining: data.secondsRemaining,
            status: data.status == "startingSoon" ? .startingSoon : .upcoming
        )
        
        Task {
            await activity.update(using: contentState)
            print("🔄 [LiveActivity] Updated, remaining: \(data.secondsRemaining)s")
        }
    }
    
    // MARK: - Timer Management
    
    private func startUpdateTimer() {
        stopUpdateTimer()
        
        // 每秒更新一次倒计时
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateCountdown() {
        guard let activity = currentActivity,
              activity.activityState == .active else {
            stopUpdateTimer()
            return
        }
        
        let currentState = activity.contentState
        let newSeconds = max(0, currentState.secondsRemaining - 1)
        
        let newState = CourseActivityAttributes.ContentState(
            secondsRemaining: newSeconds,
            status: newSeconds <= 300 ? .startingSoon : .upcoming
        )
        
        Task {
            await activity.update(using: newState)
            
            // 如果已经开始上课（倒计时<=0），自动结束
            if newSeconds <= 0 {
                await activity.end(dismissalPolicy: .default)
                self.currentActivity = nil
                self.stopUpdateTimer()
                print("🛑 [LiveActivity] Auto-ended (course started)")
            }
        }
    }
}

// MARK: - Data Model

struct LiveActivityData {
    let courseId: String
    let courseName: String
    let classroom: String?
    let teacher: String?
    let startTime: Date
    let endTime: Date
    let color: String?
    let motivationalTextLeft: String?
    let motivationalTextRight: String?
    let secondsRemaining: Int
    let status: String
    
    init?(from dictionary: [String: Any]) {
        guard let courseId = dictionary["courseId"] as? String,
              let courseName = dictionary["courseName"] as? String,
              let startTimeStr = dictionary["startTime"] as? String,
              let endTimeStr = dictionary["endTime"] as? String,
              let secondsRemaining = dictionary["secondsRemaining"] as? Int,
              let status = dictionary["status"] as? String else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        guard let startTime = formatter.date(from: startTimeStr),
              let endTime = formatter.date(from: endTimeStr) else {
            return nil
        }
        
        self.courseId = courseId
        self.courseName = courseName
        self.classroom = dictionary["classroom"] as? String
        self.teacher = dictionary["teacher"] as? String
        self.startTime = startTime
        self.endTime = endTime
        self.color = dictionary["color"] as? String
        self.motivationalTextLeft = dictionary["motivationalTextLeft"] as? String
        self.motivationalTextRight = dictionary["motivationalTextRight"] as? String
        self.secondsRemaining = secondsRemaining
        self.status = status
    }
}
```

#### 4.4.2 CourseActivityAttributes（修正版）

```swift
// ios/ScheduleWidget/LiveActivity/CourseActivityAttributes.swift

import ActivityKit
import SwiftUI

enum CourseStatus: String, Codable {
    case upcoming
    case startingSoon
}

@available(iOS 16.1, *)
struct CourseActivityAttributes: ActivityAttributes {
    // MARK: - Static Attributes
    
    let courseId: String
    let courseName: String
    let classroom: String?
    let teacher: String?
    let startTime: Date
    let endTime: Date
    let color: String?
    let motivationalTextLeft: String
    let motivationalTextRight: String
    
    // MARK: - Dynamic Content State
    
    struct ContentState: Codable, Hashable {
        var secondsRemaining: Int
        var status: CourseStatus
    }
}
```

#### 4.4.3 AppDelegate 集成

```swift
// ios/Runner/AppDelegate.swift

private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "sendWidgetData":
        handleSendWidgetData(call, result: result)
        
    case "startOrUpdateLiveActivity":
        handleStartOrUpdateLiveActivity(call, result: result)
        
    case "endLiveActivity":
        handleEndLiveActivity(result: result)
        
    case "scheduleLocalNotification":
        handleScheduleLocalNotification(call, result: result)
        
    // ... 其他方法
    default:
        result(FlutterMethodNotImplemented)
    }
}

@available(iOS 16.1, *)
private func handleStartOrUpdateLiveActivity(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let dataDict = args["data"] as? [String: Any],
          let data = LiveActivityData(from: dataDict) else {
        result(FlutterError(code: "INVALID_DATA",
                           message: "Invalid LiveActivityData",
                           details: nil))
        return
    }
    
    LiveActivityManager.shared.startOrUpdateLiveActivity(data: data)
    result(true)
}

@available(iOS 16.1, *)
private func handleEndLiveActivity(result: @escaping FlutterResult) {
    LiveActivityManager.shared.endCurrentActivity()
    result(true)
}

private func handleScheduleLocalNotification(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let id = args["id"] as? String,
          let title = args["title"] as? String,
          let body = args["body"] as? String,
          let dateStr = args["scheduledDate"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS",
                           message: "Missing required arguments",
                           details: nil))
        return
    }
    
    let formatter = ISO8601DateFormatter()
    guard let scheduledDate = formatter.date(from: dateStr) else {
        result(FlutterError(code: "INVALID_DATE",
                           message: "Invalid date format",
                           details: nil))
        return
    }
    
    // 创建本地通知
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: scheduledDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            result(FlutterError(code: "SCHEDULE_FAILED",
                               message: error.localizedDescription,
                               details: nil))
        } else {
            result(true)
        }
    }
}
```

## 5. 实施步骤

### 阶段 1：数据模型调整（1-2 天）

1. [ ] 修改 `WidgetScheduleData`，删除预计算字段，添加 `version: '2.0'`
2. [ ] 更新 `WidgetCourse` JSON 序列化
3. [ ] 确保 iOS 端 `WidgetDataManager` 能正确解析新格式
4. [ ] 添加数据版本兼容逻辑（旧数据优雅降级）

### 阶段 2：Flutter 层重构（2-3 天）

1. [ ] 重构 `UnifiedDataService.getWidgetData()`，移除 current/next 计算
2. [ ] 添加 `UnifiedDataService.getCurrentLiveActivityData()` 方法
3. [ ] 扩展 `NativeDataBridge`，添加 Live Activity 和本地通知方法
4. [ ] 修改 `WidgetRefreshHelper`，添加 `checkLiveActivity()` 和 `scheduleCourseReminders()`
5. [ ] 添加应用生命周期监听，调用检查方法

### 阶段 3：iOS Widget 重构（3-4 天）

1. [ ] 重构 `ScheduleEntry`，删除预计算字段，添加计算属性
2. [ ] 重写 `Provider.getTimeline()`，使用原始数据生成 Timeline
3. [ ] 删除 Widget 中的 Live Activity 相关代码
4. [ ] 修改所有视图层，使用 entry 的计算属性
5. [ ] 更新 `WidgetDataManager`，支持加载原始数据格式

### 阶段 4：iOS Live Activity 独立（2-3 天）

1. [ ] 创建 `LiveActivityManager` 类，管理生命周期
2. [ ] 修正 `CourseActivityAttributes` 数据模型
3. [ ] 修改 `AppDelegate`，添加 MethodChannel 处理
4. [ ] 实现本地通知调度功能
5. [ ] 测试各种场景（应用前台、后台、课程切换等）

### 阶段 5：测试与优化（2-3 天）

1. [ ] Widget 时间计算准确性测试
2. [ ] Live Activity 创建/更新/结束时机测试
3. [ ] 跨天、课程冲突等边界情况测试
4. [ ] 性能测试（Timeline 生成速度）
5. [ ] 数据版本兼容性测试

## 6. 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| Widget 与 Flutter 时间计算不一致 | 显示状态错误 | 确保两端使用相同算法，编写单元测试验证 |
| Live Activity 错过创建时机 | 用户看不到实况窗 | iOS 使用本地通知 fallback，提醒用户打开应用 |
| Timeline 刷新不及时 | 状态更新延迟 | 确保课程变更时调用 `reloadAllTimelines()` |
| 数据版本不兼容 | 旧数据无法解析 | Widget 端添加版本检测，旧数据使用默认模板 |
| Live Activity 内存泄漏 | 电池消耗 | 确保课程开始/结束后自动结束 Activity，释放 Timer |
| 本地通知权限被拒 | 无法提醒用户 | 首次使用时请求通知权限，被拒绝时引导用户到设置 |

## 7. 后续优化方向

1. **iOS Push to Start**：未来可考虑添加服务器支持，实现课前自动推送创建 Live Activity
2. **鸿蒙适配**：上游 merge 后，利用 `reminderAgentManager` 实现真正的后台 schedule
3. **Android 小组件**：后续可参考 iOS 架构，实现类似的独立计算模式
4. **数据压缩**：如果课程数据量大，可考虑压缩传输

---

**文档版本**：1.0  
**创建日期**：2025-02-01  
**状态**：待评审
