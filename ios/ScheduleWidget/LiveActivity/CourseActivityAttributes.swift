import ActivityKit
import WidgetKit
import SwiftUI

/// 课程 Live Activity 属性
@available(iOS 16.1, *)
struct CourseActivityAttributes: ActivityAttributes {
    /// 静态内容（不会改变）
    public struct ContentState: Codable, Hashable {
        var courseName: String
        var classroom: String?
        var teacher: String?
        var startTime: Date
        var endTime: Date
        var status: CourseStatus
        var minutesRemaining: Int

        enum CourseStatus: String, Codable {
            case upcoming = "upcoming"            // 即将开始
            case startingSoon = "starting_soon"   // 即将上课（5分钟内）
            case inProgress = "in_progress"       // 正在上课
            case ending = "ending"                 // 即将结束
        }
    }

    // 课程固定信息
    var courseId: String
    var color: String?
}

/// Live Activity 视图
@available(iOS 16.1, *)
struct CourseActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CourseActivityAttributes.self) { context in
            // Lock screen / banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: getCourseIcon(context.state.status))
                            .font(.system(size: 20))
                            .foregroundColor(getCourseColor(context.attributes.color))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.courseName)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)

                            if let classroom = context.state.classroom {
                                Text(classroom)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(getStatusText(context.state.status))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(getStatusColor(context.state.status))

                        Text(formatMinutes(context.state.minutesRemaining))
                            .font(.system(size: 16, weight: .bold))
                            .monospacedDigit()
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let teacher = context.state.teacher {
                            Label(teacher, systemImage: "person.fill")
                                .font(.system(size: 11))
                        }

                        Spacer()

                        Text("\(formatTime(context.state.startTime)) - \(formatTime(context.state.endTime))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact leading (课程图标)
                Image(systemName: getCourseIcon(context.state.status))
                    .foregroundColor(getCourseColor(context.attributes.color))
            } compactTrailing: {
                // Compact trailing (剩余时间)
                Text(formatMinutesShort(context.state.minutesRemaining))
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
            } minimal: {
                // Minimal (最小显示)
                Image(systemName: "book.fill")
                    .foregroundColor(getCourseColor(context.attributes.color))
            }
        }
    }

    // MARK: - Helper Functions

    private func getCourseIcon(_ status: CourseActivityAttributes.ContentState.CourseStatus) -> String {
        switch status {
        case .upcoming:
            return "clock"
        case .startingSoon:
            return "bell.fill"
        case .inProgress:
            return "book.fill"
        case .ending:
            return "checkmark.circle.fill"
        }
    }

    private func getCourseColor(_ colorHex: String?) -> Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return .blue
    }

    private func getStatusText(_ status: CourseActivityAttributes.ContentState.CourseStatus) -> String {
        switch status {
        case .upcoming:
            return "即将开始"
        case .startingSoon:
            return "准备上课"
        case .inProgress:
            return "正在上课"
        case .ending:
            return "即将结束"
        }
    }

    private func getStatusColor(_ status: CourseActivityAttributes.ContentState.CourseStatus) -> Color {
        switch status {
        case .upcoming:
            return .orange
        case .startingSoon:
            return .red
        case .inProgress:
            return .green
        case .ending:
            return .blue
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 0 {
            return "已开始"
        } else if minutes == 0 {
            return "现在"
        } else if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)小时\(mins)分"
        }
    }

    private func formatMinutesShort(_ minutes: Int) -> String {
        if minutes < 0 {
            return "进行中"
        } else if minutes == 0 {
            return "现在"
        } else if minutes < 60 {
            return "\(minutes)分"
        } else {
            return "\(minutes / 60)h\(minutes % 60)m"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/// 锁屏 Live Activity 视图
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CourseActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(getCourseColor(context.attributes.color).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: getCourseIcon(context.state.status))
                    .font(.system(size: 18))
                    .foregroundColor(getCourseColor(context.attributes.color))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.courseName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let classroom = context.state.classroom {
                        Label(classroom, systemImage: "mappin.circle.fill")
                            .font(.system(size: 12))
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(formatMinutes(context.state.minutesRemaining))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // Status
            Text(getStatusText(context.state.status))
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(getStatusColor(context.state.status).opacity(0.2))
                .foregroundColor(getStatusColor(context.state.status))
                .clipShape(Capsule())
        }
        .padding(16)
    }

    private func getCourseIcon(_ status: CourseActivityAttributes.ContentState.CourseStatus) -> String {
        switch status {
        case .upcoming: return "clock"
        case .startingSoon: return "bell.fill"
        case .inProgress: return "book.fill"
        case .ending: return "checkmark.circle.fill"
        }
    }

    private func getCourseColor(_ colorHex: String?) -> Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return .blue
    }

    private func getStatusText(_ status: CourseActivityAttributes.ContentState.CourseStatus) -> String {
        switch status {
        case .upcoming: return "即将开始"
        case .startingSoon: return "准备上课"
        case .inProgress: return "正在上课"
        case .ending: return "即将结束"
        }
    }

    private func getStatusColor(_ status: CourseActivityAttributes.ContentState.CourseStatus) -> Color {
        switch status {
        case .upcoming: return .orange
        case .startingSoon: return .red
        case .inProgress: return .green
        case .ending: return .blue
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 0 {
            return "已开始"
        } else if minutes == 0 {
            return "现在"
        } else if minutes < 60 {
            return "\(minutes)分钟后"
        } else {
            return "\(minutes / 60)小时后"
        }
    }
}
