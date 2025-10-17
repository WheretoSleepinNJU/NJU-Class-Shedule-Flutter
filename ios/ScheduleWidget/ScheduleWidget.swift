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
            displayState: .error
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = loadEntry()

        // Calculate next refresh time
        let nextRefresh = calculateNextRefreshTime(entry: entry)
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))

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
                displayState: .error
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

        return ScheduleEntry(
            date: Date(),
            widgetData: data,
            nextCourse: data.nextCourse,
            currentCourse: data.currentCourse,
            todayCourses: data.todayCourses,
            errorMessage: nil,
            displayState: displayState
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
                    return startTime
                }
            }
        }

        // Default: refresh in 15 minutes
        return calendar.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
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
