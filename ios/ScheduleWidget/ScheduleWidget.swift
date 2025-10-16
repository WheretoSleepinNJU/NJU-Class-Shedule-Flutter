import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetScheduleData?
    let nextCourse: WidgetCourse?
    let currentCourse: WidgetCourse?
    let todayCourses: [WidgetCourse]
    let errorMessage: String?

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
            errorMessage: nil
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
                errorMessage: "打开应用更新数据"
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

        return ScheduleEntry(
            date: Date(),
            widgetData: data,
            nextCourse: data.nextCourse,
            currentCourse: data.currentCourse,
            todayCourses: data.todayCourses,
            errorMessage: nil
        )
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

// MARK: - Medium Widget (Today's Schedule)
struct MediumWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        if let errorMessage = entry.errorMessage {
            ErrorView(message: errorMessage)
        } else if entry.todayCourses.isEmpty {
            EmptyStateView(message: "今日无课，好好休息～")
        } else {
            TodayScheduleView(
                courses: Array(entry.todayCourses.prefix(3)),
                currentCourse: entry.currentCourse,
                timeTemplate: entry.widgetData?.timeTemplate
            )
        }
    }
}

// MARK: - Large Widget (Full Day)
struct LargeWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        if let errorMessage = entry.errorMessage {
            ErrorView(message: errorMessage)
        } else if entry.todayCourses.isEmpty {
            EmptyStateView(message: "今日无课，享受休息时光")
        } else {
            TimelineView(
                courses: entry.todayCourses,
                currentCourse: entry.currentCourse,
                timeTemplate: entry.widgetData?.timeTemplate,
                currentWeek: entry.widgetData?.currentWeek ?? 1
            )
        }
    }
}
