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
                // MARK: - Expanded View (展开态)
                // 遵循 Widget 设计精神：清晰的信息层级，课程色彩点缀
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        // 课程图标（使用课程颜色）
                        ZStack {
                            Circle()
                                .fill(getCourseColor(context.attributes.color).opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: getCourseIcon(context.state.status))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(getCourseColor(context.attributes.color))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            // 课程名称（主信息，粗体）
                            Text(context.state.courseName)
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            // 教室·教师（次要信息，教室不能截断）
                            HStack(spacing: 4) {
                                if let classroom = context.state.classroom {
                                    Text(classroom)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .fixedSize()  // 教室绝对不能截断
                                }

                                if let teacher = context.state.teacher {
                                    Text("·")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)

                                    Text(teacher)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        // 状态标签（带颜色背景胶囊）
                        Text(getStatusText(context.state.status))
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(getStatusColor(context.state.status).opacity(0.15))
                            .foregroundColor(getStatusColor(context.state.status))
                            .clipShape(Capsule())

                        // 倒计时（单色数字）
                        Text(formatMinutes(context.state.minutesRemaining))
                            .font(.system(size: 16, weight: .bold))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // 时间段信息
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Text("\(formatTime(context.state.startTime)) - \(formatTime(context.state.endTime))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        // "我已到达"按钮（仅在即将上课时显示）
                        if context.state.status == .startingSoon || context.state.status == .upcoming {
                            Link(destination: URL(string: "njuschedule://arrived/\(context.attributes.courseId)")!) {
                                Text("我已到达")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(getCourseColor(context.attributes.color).opacity(0.15))
                                    .foregroundColor(getCourseColor(context.attributes.color))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // MARK: - Compact Leading (紧凑态左侧)
                // 显示状态图标 + 课程颜色
                Image(systemName: getCourseIcon(context.state.status))
                    .foregroundColor(getCourseColor(context.attributes.color))
            } compactTrailing: {
                // MARK: - Compact Trailing (紧凑态右侧)
                // 显示教室（绝对不能截断）
                if let classroom = context.state.classroom {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(classroom)
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()  // 教室绝对不能截断

                        // 倒计时（小字）
                        Text(formatMinutesShort(context.state.minutesRemaining))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                } else {
                    // 如果没有教室，显示倒计时
                    Text(formatMinutesShort(context.state.minutesRemaining))
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                }
            } minimal: {
                // MARK: - Minimal (最小态)
                // 使用课程颜色的图标
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
/// 遵循 Widget 设计精神：课程卡片风格 + 清晰的信息层级
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CourseActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：状态标签
            HStack {
                Text(getStatusText(context.state.status))
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(getStatusColor(context.state.status).opacity(0.15))
                    .foregroundColor(getStatusColor(context.state.status))
                    .clipShape(Capsule())

                Spacer()

                // 倒计时
                Text(formatMinutes(context.state.minutesRemaining))
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.primary)
            }

            // 课程信息卡片（模仿 Widget 的课程卡片风格）
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    // 课程名称（主信息，粗体）
                    Text(context.state.courseName)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    // 教室·教师（次要信息）
                    HStack(spacing: 4) {
                        if let classroom = context.state.classroom {
                            Label {
                                Text(classroom)
                                    .font(.system(size: 13, weight: .semibold))
                                    .fixedSize()  // 教室绝对不能截断
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                        }

                        if let teacher = context.state.teacher {
                            if context.state.classroom != nil {
                                Text("·")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Label {
                                Text(teacher)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } icon: {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    // 时间段
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))

                        Text("\(formatTime(context.state.startTime)) - \(formatTime(context.state.endTime))")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.leading, 12)
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getCourseColor(context.attributes.color).opacity(0.12))
                )
                .overlay(
                    // 左侧色条（模仿 Widget 风格）
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(getCourseColor(context.attributes.color))
                            .frame(width: 4)
                        Spacer()
                    }
                )
            }
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

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
