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
        let widgetData = WidgetDataManager.shared.loadWidgetData()

        guard let data = widgetData else {
            return ScheduleEntry(
                date: Date(),
                widgetData: nil,
                nextCourse: nil,
                currentCourse: nil,
                todayCourses: [],
                errorMessage: "打开应用更新数据"
            )
        }

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
           let widgetData = entry.widgetData,
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
@main
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

// MARK: - Small Widget (Next Course)
struct SmallWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        if let errorMessage = entry.errorMessage {
            ErrorView(message: errorMessage)
        } else if let course = entry.nextCourse ?? entry.currentCourse {
            NextCourseView(course: course,
                          timeTemplate: entry.widgetData?.timeTemplate,
                          isCurrent: entry.currentCourse?.id == course.id)
        } else {
            EmptyStateView(message: "今日无课")
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

// MARK: - Preview
struct ScheduleWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCourse = WidgetCourse(
            id: "1",
            name: "数据结构",
            classroom: "仙I-101",
            teacher: "张教授",
            startPeriod: 3,
            periodCount: 2,
            weekDay: 1,
            color: "#4A90E2",
            schoolId: "nju",
            weeks: [1, 2, 3, 4, 5],
            courseType: "imported",
            notes: nil
        )

        let entry = ScheduleEntry(
            date: Date(),
            widgetData: nil,
            nextCourse: sampleCourse,
            currentCourse: nil,
            todayCourses: [sampleCourse],
            errorMessage: nil
        )

        Group {
            ScheduleWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            ScheduleWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            ScheduleWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
