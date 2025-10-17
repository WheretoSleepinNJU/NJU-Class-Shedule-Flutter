import WidgetKit
import SwiftUI

// MARK: - Widget Display State
enum WidgetDisplayState {
    case beforeFirstClass    // 上课前（当天第一节课之前）
    case betweenClasses      // 课间（已上过课，等待下一节课）
    case approachingClass    // 即将上课
    case inClass             // 上课中
    case classesEnded        // 课程结束
    case tomorrowPreview     // 明日预览
    case error               // 错误状态
}

// MARK: - Timeline Entry
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetScheduleData?
    let nextCourse: WidgetCourse?
    let currentCourse: WidgetCourse?
    let todayCourses: [WidgetCourse]
    let errorMessage: String?
    let displayState: WidgetDisplayState  // 显式指定显示状态
    let relevance: TimelineEntryRelevance?  // Smart Stack 优先级评分

    var hasData: Bool {
        return widgetData != nil
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            widgetData: nil,
            nextCourse: nil,
            currentCourse: nil,
            todayCourses: [],
            errorMessage: nil,
            displayState: .error,
            relevance: TimelineEntryRelevance(score: 0)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        print("🔄 [Widget] ========== Generating Timeline ==========")
        let currentEntry = loadEntry()
        var entries: [ScheduleEntry] = [currentEntry]

        // Generate entries for future state transitions
        if let data = currentEntry.widgetData {
            let transitionDates = calculateStateTransitions(data: data)

            print("📊 [Widget] Generating \(min(transitionDates.count, 9)) additional timeline entries")

            // Limit to 9 additional entries (10 total including current)
            for (index, transitionDate) in transitionDates.prefix(9).enumerated() {
                let futureEntry = createEntry(at: transitionDate, data: data)
                entries.append(futureEntry)

                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                print("   Entry \(index + 2): \(formatter.string(from: transitionDate)) - \(futureEntry.displayState)")
            }
        }

        // Calculate when to request new timeline (end of day or major event)
        let nextRefresh = calculateNextMajorRefresh(entry: currentEntry)
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        print("📊 [Widget] Timeline contains \(entries.count) entries")
        print("📊 [Widget] Next major refresh: \(formatter.string(from: nextRefresh))")
        print("✅ [Widget] ========== Timeline Generated ==========")

        completion(timeline)
    }

    // MARK: - Data Loading
    private func loadEntry() -> ScheduleEntry {
        print("🔄 [Widget] ========== Loading Widget Entry ==========")
        print("📅 [Widget] Current time: \(Date())")

        // Debug: Test direct App Group access
        let appGroupId = "group.top.idealclover.wheretosleepinnju"
        if let testAppGroup = UserDefaults(suiteName: appGroupId) {
            print("✅ [Widget] Direct App Group access successful")
            if let testData = testAppGroup.data(forKey: "widget_data") {
                print("✅ [Widget] Direct read successful: \(testData.count) bytes")
            } else {
                print("❌ [Widget] Direct read failed: No data at key 'widget_data'")
                print("🔍 [Widget] Available keys:")
                for (key, _) in testAppGroup.dictionaryRepresentation() {
                    print("   - \(key)")
                }
            }
        } else {
            print("❌ [Widget] Direct App Group access failed!")
        }

        let widgetData = WidgetDataManager.shared.loadWidgetData()

        guard let data = widgetData else {
            print("❌ [Widget] No widget data found in App Group")
            print("⚠️ [Widget] Displaying 'Open app to update' message")
            print("🔍 [Widget] Possible causes:")
            print("   1. App has not sent data yet")
            print("   2. App Group not configured correctly")
            print("   3. Data was cleared")

            return ScheduleEntry(
                date: Date(),
                widgetData: nil,
                nextCourse: nil,
                currentCourse: nil,
                todayCourses: [],
                errorMessage: "打开应用更新数据",
                displayState: .error,
                relevance: TimelineEntryRelevance(score: 0)
            )
        }

        print("✅ [Widget] Widget data loaded successfully")
        print("📊 [Widget] School: \(data.schoolName)")
        print("📊 [Widget] Current week: \(data.currentWeek)")
        print("📊 [Widget] Today's courses: \(data.todayCourseCount)")
        print("📊 [Widget] Tomorrow's courses: \(data.tomorrowCourseCount)")

        if let currentCourse = data.currentCourse {
            print("📖 [Widget] Current course: \(currentCourse.name)")
        } else {
            print("📖 [Widget] No current course")
        }

        if let nextCourse = data.nextCourse {
            print("📖 [Widget] Next course: \(nextCourse.name)")
        } else {
            print("📖 [Widget] No next course")
        }

        print("✅ [Widget] ========== Entry Loaded Successfully ==========")

        // 计算显示状态
        let displayState = determineDisplayState(data: data)
        print("📊 [Widget] Display State: \(displayState)")

        // 创建临时 entry 用于计算 relevance
        let tempEntry = ScheduleEntry(
            date: Date(),
            widgetData: data,
            nextCourse: data.nextCourse,
            currentCourse: data.currentCourse,
            todayCourses: data.todayCourses,
            errorMessage: nil,
            displayState: displayState,
            relevance: nil
        )

        // 计算 relevance
        let relevance = calculateRelevance(for: tempEntry)
        print("📊 [Widget] Relevance Score: \(relevance?.score ?? 0)")

        return ScheduleEntry(
            date: tempEntry.date,
            widgetData: tempEntry.widgetData,
            nextCourse: tempEntry.nextCourse,
            currentCourse: tempEntry.currentCourse,
            todayCourses: tempEntry.todayCourses,
            errorMessage: tempEntry.errorMessage,
            displayState: tempEntry.displayState,
            relevance: relevance
        )
    }

    // MARK: - State Determination
    private func determineDisplayState(data: WidgetScheduleData) -> WidgetDisplayState {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        let tomorrowPreviewHour = data.tomorrowPreviewHour ?? 21
        let approachingMinutes = data.approachingMinutes ?? 15

        // 1. 晚上指定时间后显示明日预览
        if currentHour >= tomorrowPreviewHour {
            if !data.tomorrowCourses.isEmpty {
                return .tomorrowPreview
            }
        }

        // 2. 正在上课
        if data.currentCourse != nil {
            return .inClass
        }

        // 3. 检查是否即将上课
        if let next = data.nextCourse {
            if let minutesUntil = getMinutesUntilCourse(next, template: data.timeTemplate),
               minutesUntil > 0 && minutesUntil <= approachingMinutes {
                return .approachingClass
            }
        }

        // 4. 今日还有课程，判断是第一节课前还是课间
        if let nextCourse = data.nextCourse {
            // 检查是否是当天第一节课
            let todayCourses = data.todayCourses
            if !todayCourses.isEmpty,
               let firstCourse = todayCourses.first,
               firstCourse.id == nextCourse.id {
                // 是第一节课
                return .beforeFirstClass
            } else {
                // 不是第一节课，说明已经上过课了，现在是课间
                return .betweenClasses
            }
        }

        // 5. 今日课程已结束
        return .classesEnded
    }

    private func getMinutesUntilCourse(_ course: WidgetCourse, template: SchoolTimeTemplate) -> Int? {
        guard let period = template.getPeriodRange(
            startPeriod: course.startPeriod,
            periodCount: course.periodCount
        ) else { return nil }

        guard let startTime = parseTime(period.startTime) else { return nil }

        let now = Date()
        let minutes = Calendar.current.dateComponents([.minute], from: now, to: startTime).minute
        return minutes
    }

    // MARK: - Refresh Calculation
    /// 计算下一次主要刷新时间（用于重新生成 timeline）
    /// 通常设置为第二天凌晨，让 timeline entries 处理当天的状态变化
    private func calculateNextMajorRefresh(entry: ScheduleEntry) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // 默认：明天凌晨 0:00（加上随机 jitter）
        if let tomorrowMidnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        ) {
            // 添加随机 jitter (0-5 分钟)，避免所有设备同时刷新
            let jitter = Int.random(in: 0..<300) // 0-5分钟（秒）
            if let jitteredTime = calendar.date(byAdding: .second, value: jitter, to: tomorrowMidnight) {
                return jitteredTime
            }
            return tomorrowMidnight
        }

        // Fallback: 1 小时后
        return calendar.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
    }

    /// 计算下一次刷新时间（旧方法，已被 calculateNextMajorRefresh 替代）
    /// 保留用于兼容性，添加了 jitter
    private func calculateNextRefreshTime(entry: ScheduleEntry) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // If there's a next course, refresh at its start time
        if let nextCourse = entry.nextCourse,
           let template = entry.widgetData?.timeTemplate,
           let period = template.getPeriodRange(
               startPeriod: nextCourse.startPeriod,
               periodCount: nextCourse.periodCount
           ) {
            // Parse start time
            if let startTime = parseTime(period.startTime) {
                if startTime > now {
                    // 添加随机 jitter (0-5 分钟)
                    let jitter = Int.random(in: 0..<300)
                    return calendar.date(byAdding: .second, value: jitter, to: startTime) ?? startTime
                }
            }
        }

        // Default: refresh in 15 minutes (with jitter)
        let baseRefresh = calendar.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let jitter = Int.random(in: 0..<300)
        return calendar.date(byAdding: .second, value: jitter, to: baseRefresh) ?? baseRefresh
    }

    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let time = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(bySettingHour: components.hour ?? 0,
                            minute: components.minute ?? 0,
                            second: 0,
                            of: now)
    }

    // MARK: - Relevance Calculation
    /// 计算 Smart Stack 的优先级评分
    /// 评分越高，widget 在 Smart Stack 中越容易被显示
    private func calculateRelevance(for entry: ScheduleEntry, at date: Date = Date()) -> TimelineEntryRelevance? {
        switch entry.displayState {
        case .inClass:
            // 正在上课：最高优先级
            return TimelineEntryRelevance(score: 100, duration: 60)

        case .approachingClass:
            // 即将上课：根据距离上课时间动态评分（15分钟内）
            if let nextCourse = entry.nextCourse,
               let template = entry.widgetData?.timeTemplate {
                if let minutesUntil = getMinutesUntilCourse(nextCourse, template: template, from: date) {
                    // 距离上课时间越近，分数越高
                    // 0分钟 = 100分，15分钟 = 25分
                    let score = Float(max(25, 100 - (minutesUntil * 5)))
                    return TimelineEntryRelevance(score: score)
                }
            }
            return TimelineEntryRelevance(score: 50)

        case .beforeFirstClass, .betweenClasses:
            // 有即将到来的课程
            if let nextCourse = entry.nextCourse,
               let template = entry.widgetData?.timeTemplate {
                if let minutesUntil = getMinutesUntilCourse(nextCourse, template: template, from: date) {
                    if minutesUntil <= 120 {
                        // 2小时内：中等优先级
                        return TimelineEntryRelevance(score: 20)
                    }
                }
            }
            // 今日还有课，但时间较远：低优先级
            return TimelineEntryRelevance(score: 10)

        case .tomorrowPreview:
            // 明日预览：很低优先级
            return TimelineEntryRelevance(score: 5)

        case .classesEnded, .error:
            // 课程已结束或错误状态：不显示
            return TimelineEntryRelevance(score: 0)
        }
    }

    /// 获取距离课程开始的分钟数（支持指定参考时间）
    private func getMinutesUntilCourse(_ course: WidgetCourse, template: SchoolTimeTemplate, from referenceDate: Date) -> Int? {
        guard let period = template.getPeriodRange(
            startPeriod: course.startPeriod,
            periodCount: course.periodCount
        ) else { return nil }

        guard let startTime = parseTimeOnDate(period.startTime, date: referenceDate) else { return nil }

        let minutes = Calendar.current.dateComponents([.minute], from: referenceDate, to: startTime).minute
        return minutes
    }

    /// 在指定日期上解析时间字符串
    private func parseTimeOnDate(_ timeString: String, date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let time = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        return calendar.date(bySettingHour: components.hour ?? 0,
                            minute: components.minute ?? 0,
                            second: 0,
                            of: date)
    }

    // MARK: - State Transition Calculation
    /// 计算所有未来的状态转换时间点
    /// 包括：课程开始、课程结束、即将上课（15分钟前）、明日预览时间（21:00）、新的一天（0:00）
    private func calculateStateTransitions(data: WidgetScheduleData) -> [Date] {
        var transitions: [Date] = []
        let calendar = Calendar.current
        let now = Date()

        let template = data.timeTemplate
        let approachingMinutes = data.approachingMinutes ?? 15
        let tomorrowPreviewHour = data.tomorrowPreviewHour ?? 21

        // 1. 遍历今日所有课程，添加关键时间点
        for course in data.todayCourses {
            guard let period = template.getPeriodRange(
                startPeriod: course.startPeriod,
                periodCount: course.periodCount
            ) else { continue }

            // 课程开始时间
            if let startTime = parseTimeOnDate(period.startTime, date: now), startTime > now {
                transitions.append(startTime)

                // 课程开始前 N 分钟（即将上课状态）
                if let approachingTime = calendar.date(
                    byAdding: .minute,
                    value: -approachingMinutes,
                    to: startTime
                ), approachingTime > now {
                    transitions.append(approachingTime)
                }
            }

            // 课程结束时间
            if let endTime = parseTimeOnDate(period.endTime, date: now), endTime > now {
                transitions.append(endTime)
            }
        }

        // 2. 添加明日预览时间（今天的21:00或配置的时间）
        if let tomorrowPreviewTime = calendar.date(
            bySettingHour: tomorrowPreviewHour,
            minute: 0,
            second: 0,
            of: now
        ), tomorrowPreviewTime > now {
            transitions.append(tomorrowPreviewTime)
        }

        // 3. 添加明天 0:00 作为新的一天的状态重置点
        if let tomorrowMidnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        ) {
            transitions.append(tomorrowMidnight)
        }

        // 4. 去重、排序、过滤（只保留未来的时间）
        let uniqueTransitions = Array(Set(transitions))
            .filter { $0 > now }
            .sorted()

        // 5. 确保时间点之间至少间隔 5 分钟（Apple 推荐）
        var filteredTransitions: [Date] = []
        var lastTime: Date?

        for time in uniqueTransitions {
            if let last = lastTime {
                // 检查是否距离上一个时间点至少5分钟
                if time.timeIntervalSince(last) >= 300 { // 300秒 = 5分钟
                    filteredTransitions.append(time)
                    lastTime = time
                }
            } else {
                filteredTransitions.append(time)
                lastTime = time
            }
        }

        print("📊 [Widget] Calculated \(filteredTransitions.count) state transitions:")
        for (index, time) in filteredTransitions.prefix(10).enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            print("   \(index + 1). \(formatter.string(from: time))")
        }

        return filteredTransitions
    }

    // MARK: - Future Entry Creation
    /// 创建指定未来时间的 timeline entry
    /// 模拟在该时间点的 widget 状态
    private func createEntry(at futureDate: Date, data: WidgetScheduleData) -> ScheduleEntry {
        // 在指定时间点，重新计算当前课程和下一节课
        let (currentCourse, nextCourse) = findCoursesAt(date: futureDate, data: data)

        // 计算该时间点的显示状态
        let displayState = determineDisplayState(
            data: data,
            currentCourse: currentCourse,
            nextCourse: nextCourse,
            at: futureDate
        )

        let entry = ScheduleEntry(
            date: futureDate,
            widgetData: data,
            nextCourse: nextCourse,
            currentCourse: currentCourse,
            todayCourses: data.todayCourses,
            errorMessage: nil,
            displayState: displayState,
            relevance: nil  // 先创建，稍后计算 relevance
        )

        // 计算该时间点的 relevance
        let relevance = calculateRelevance(for: entry, at: futureDate)

        return ScheduleEntry(
            date: entry.date,
            widgetData: entry.widgetData,
            nextCourse: entry.nextCourse,
            currentCourse: entry.currentCourse,
            todayCourses: entry.todayCourses,
            errorMessage: entry.errorMessage,
            displayState: entry.displayState,
            relevance: relevance
        )
    }

    /// 查找指定时间点的当前课程和下一节课
    private func findCoursesAt(date: Date, data: WidgetScheduleData) -> (current: WidgetCourse?, next: WidgetCourse?) {
        let template = data.timeTemplate

        var currentCourse: WidgetCourse?
        var nextCourse: WidgetCourse?

        for course in data.todayCourses {
            guard let period = template.getPeriodRange(
                startPeriod: course.startPeriod,
                periodCount: course.periodCount
            ) else { continue }

            guard let startTime = parseTimeOnDate(period.startTime, date: date),
                  let endTime = parseTimeOnDate(period.endTime, date: date) else {
                continue
            }

            // 检查是否是当前课程（在上课时间范围内）
            if date >= startTime && date < endTime {
                currentCourse = course
            }

            // 检查是否是下一节课（还未开始的最近一节课）
            if startTime > date {
                if nextCourse == nil {
                    nextCourse = course
                } else if let nextStart = parseTimeOnDate(
                    template.getPeriodRange(
                        startPeriod: nextCourse!.startPeriod,
                        periodCount: nextCourse!.periodCount
                    )?.startTime ?? "",
                    date: date
                ), startTime < nextStart {
                    nextCourse = course
                }
            }
        }

        return (currentCourse, nextCourse)
    }

    /// 重载的状态判断方法，支持指定时间和课程
    private func determineDisplayState(
        data: WidgetScheduleData,
        currentCourse: WidgetCourse?,
        nextCourse: WidgetCourse?,
        at date: Date
    ) -> WidgetDisplayState {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)

        let tomorrowPreviewHour = data.tomorrowPreviewHour ?? 21
        let approachingMinutes = data.approachingMinutes ?? 15

        // 1. 晚上指定时间后显示明日预览
        if currentHour >= tomorrowPreviewHour {
            if !data.tomorrowCourses.isEmpty {
                return .tomorrowPreview
            }
        }

        // 2. 正在上课
        if currentCourse != nil {
            return .inClass
        }

        // 3. 检查是否即将上课
        if let next = nextCourse {
            let template = data.timeTemplate
            if let minutesUntil = getMinutesUntilCourse(next, template: template, from: date),
               minutesUntil > 0 && minutesUntil <= approachingMinutes {
                return .approachingClass
            }
        }

        // 4. 今日还有课程，判断是第一节课前还是课间
        if let next = nextCourse {
            let todayCourses = data.todayCourses
            if !todayCourses.isEmpty,
               let firstCourse = todayCourses.first,
               firstCourse.id == next.id {
                return .beforeFirstClass
            } else {
                return .betweenClasses
            }
        }

        // 5. 今日课程已结束
        return .classesEnded
    }
}

// MARK: - Widget Configuration
struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("课程表")
        .description("查看今日课程和下节课信息")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Main Entry View
struct ScheduleWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
