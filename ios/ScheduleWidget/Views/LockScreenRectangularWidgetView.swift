import SwiftUI
import WidgetKit

/// 锁屏矩形组件（accessoryRectangular）
/// 复用 ScheduleEntry 的状态与数据，不引入新模型。
struct LockScreenRectangularWidgetView: View {
    let entry: ScheduleEntry

    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            if let errorMessage = entry.errorMessage {
                LockScreenRectangularContentView(
                    title: errorMessage,
                    subtitle: "轻触打开应用",
                    footnote: nil,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    destination: URL(string: "ncs://refresh")
                )
            } else {
                switch entry.displayState {
                case .inClass:
                    if let course = entry.currentCourse {
                        LockScreenRectangularContentView(
                            title: course.name,
                            subtitle: combineCourseInfo(course.classroom, course.teacher),
                            footnote: buildTimeText(for: course),
                            icon: "book.fill",
                            iconColor: .green,
                            destination: URL(string: "ncs://course/\(course.id)")
                        )
                    } else {
                        endedView
                    }
                case .approachingClass, .beforeFirstClass, .betweenClasses:
                    if let course = entry.nextCourse {
                        LockScreenRectangularContentView(
                            title: course.name,
                            subtitle: combineCourseInfo(course.classroom, course.teacher),
                            footnote: buildStartTimeText(for: course),
                            icon: "clock.fill",
                            iconColor: .orange,
                            destination: URL(string: "ncs://course/\(course.id)")
                        )
                    } else {
                        endedView
                    }
                case .tomorrowPreview:
                    if let course = entry.widgetData?.tomorrowCourses.first {
                        LockScreenRectangularContentView(
                            title: course.name,
                            subtitle: "明日首课",
                            footnote: buildStartTimeText(for: course),
                            icon: "sunrise.fill",
                            iconColor: .blue,
                            destination: URL(string: "ncs://course/\(course.id)")
                        )
                    } else {
                        endedView
                    }
                case .classesEnded:
                    endedView
                case .error:
                    LockScreenRectangularContentView(
                        title: "打开应用更新数据",
                        subtitle: "轻触打开应用",
                        footnote: nil,
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        destination: URL(string: "ncs://refresh")
                    )
                }
            }
        }
        .widgetURL(URL(string: "ncs://refresh"))
        .containerBackground(for: .widget) {
            containerBackgroundColor
        }
    }

    private var containerBackgroundColor: Color {
        if renderingMode == .fullColor && colorScheme == .dark {
            return .black
        }
        return .clear
    }

    private var endedView: some View {
        LockScreenRectangularContentView(
            title: "今日课程已结束",
            subtitle: nil,
            footnote: nil,
            icon: "checkmark.circle.fill",
            iconColor: .green,
            destination: URL(string: "ncs://refresh")
        )
    }

    private func combineCourseInfo(_ classroom: String?, _ teacher: String?) -> String? {
        if let classroom, let teacher {
            return "\(classroom) · \(teacher)"
        }
        return classroom ?? teacher
    }

    private func buildStartTimeText(for course: WidgetCourse) -> String? {
        guard let template = entry.widgetData?.timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return "第\(course.startPeriod)节"
        }
        return "开始 \(formatTime(period.startTime))"
    }

    private func buildTimeText(for course: WidgetCourse) -> String? {
        guard let template = entry.widgetData?.timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return "第\(course.startPeriod)节"
        }
        return "\(formatTime(period.startTime)) - \(formatTime(period.endTime))"
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

private struct LockScreenRectangularContentView: View {
    let title: String
    let subtitle: String?
    let footnote: String?
    let icon: String
    let iconColor: Color
    let destination: URL?

    var body: some View {
        Link(destination: destination ?? URL(string: "ncs://refresh")!) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(iconColor)
                    Text(statusText)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundColor(.secondary)
                }

                if let footnote {
                    Text(footnote)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var statusText: String {
        switch icon {
        case "book.fill": return "上课中"
        case "clock.fill": return "下一节"
        case "sunrise.fill": return "明日预览"
        case "checkmark.circle.fill": return "课程状态"
        default: return "提醒"
        }
    }
}
