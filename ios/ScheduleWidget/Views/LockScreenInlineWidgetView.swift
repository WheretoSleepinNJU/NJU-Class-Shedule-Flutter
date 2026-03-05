import SwiftUI
import WidgetKit

/// 锁屏 Inline 组件（accessoryInline）
/// 仅展示：教室 + 上课时间
struct LockScreenInlineWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        Group {
            if let inlineContent = inlineContent {
                (Text(inlineContent.classroom).fontWeight(.medium)
                + Text("·").foregroundColor(.secondary)
                + Text(inlineContent.timeText).fontWeight(.light).foregroundColor(.secondary))
            } else {
                Text(displayText)
                    .lineLimit(1)
            }
        }
        .widgetURL(destinationURL)
    }

    private var selectedCourse: WidgetCourse? {
        switch entry.displayState {
        case .inClass:
            return entry.currentCourse
        case .approachingClass, .beforeFirstClass, .betweenClasses:
            return entry.nextCourse
        case .tomorrowPreview:
            return entry.widgetData?.tomorrowCourses.first
        case .classesEnded, .error:
            return nil
        }
    }

    private var displayText: String {
        if isNoDataState {
            return "打开应用更新数据"
        }

        return "今日无课"
    }

    private var destinationURL: URL? {
        if isNoDataState {
            return URL(string: "ncs://refresh")
        }

        if let course = selectedCourse {
            return URL(string: "ncs://course/\(course.id)")
        }
        return URL(string: "ncs://refresh")
    }

    private var isNoDataState: Bool {
        entry.widgetData == nil || entry.errorMessage != nil
    }

    private func buildTimeText(for course: WidgetCourse) -> String {
        guard let template = entry.widgetData?.timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return "第\(course.startPeriod)节"
        }

        switch entry.displayState {
        case .inClass:
            return formatTime(period.endTime)
        case .approachingClass, .beforeFirstClass, .betweenClasses, .tomorrowPreview:
            return formatTime(period.startTime)
        case .classesEnded, .error:
            return "第\(course.startPeriod)节"
        }
    }

    private var inlineContent: (classroom: String, timeText: String)? {
        guard !isNoDataState, let course = selectedCourse else { return nil }
        return (course.classroom ?? "教室待定", buildTimeText(for: course))
    }

    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        if components.count == 2,
           let hour = Int(components[0]) {
            return "\(hour):\(components[1])"
        }
        return timeString
    }
}
