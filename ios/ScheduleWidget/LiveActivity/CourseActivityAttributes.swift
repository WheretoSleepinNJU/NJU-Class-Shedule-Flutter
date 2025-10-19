import ActivityKit
import WidgetKit
import SwiftUI

/// 课程 Live Activity 属性
@available(iOS 16.1, *)
struct CourseActivityAttributes: ActivityAttributes {
    /// 动态内容（会更新）
    /// 简化设计：只有一个状态，显示距离上课的倒计时
    /// Live Activity 在课前 N 分钟创建，上课时或用户点击"我已到达"后自动关闭
    public struct ContentState: Codable, Hashable {
        var courseName: String
        var classroom: String?
        var teacher: String?
        var startTime: Date
        var endTime: Date
        var secondsRemaining: Int  // 距离上课还有多少秒（用于精确倒计时）
        var motivationalTextLeft: String?  // 左侧励志文本（可选）
        var motivationalTextRight: String?  // 右侧励志文本（可选）
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
                // 所有内容放在 bottom 区域，leading 和 trailing 显示用户自定义励志文本
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.motivationalTextLeft ?? "好好学习")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.motivationalTextRight ?? "天天向上")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // 直接复用 Lock Screen 布局
                    LockScreenLiveActivityView(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Leading (紧凑态左侧)
                // 显示课程名称（允许2行换行）
                Text(context.state.courseName)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)  // 允许垂直方向扩展以容纳换行
                    .multilineTextAlignment(.leading)
                    .padding()
            } compactTrailing: {
                // MARK: - Compact Trailing (紧凑态右侧)
                // 显示教室 + 倒计时
                if let classroom = context.state.classroom {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(classroom)
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()  // 教室绝对不能截断

                        // 倒计时（简化显示）
                        Text(formatSecondsCompact(context.state.secondsRemaining))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                } else {
                    // 如果没有教室，显示倒计时
                    Text(formatSecondsCompact(context.state.secondsRemaining))
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                }
            } minimal: {
                // MARK: - Minimal (最小态)
                // 显示教室（允许换行和缩小，连字符替换为空格以改善换行）
                Text(formatClassroomForMinimal(context.state.classroom ?? context.state.courseName))
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    // MARK: - Helper Functions

    /// 格式化教室名以改善换行（将连字符替换为空格）
    private func formatClassroomForMinimal(_ classroom: String) -> String {
        return classroom.replacingOccurrences(of: "-", with: " ")
    }

    private func getCourseColor(_ colorHex: String?) -> Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return .blue
    }

    /// 格式化秒数为倒计时显示（展开态使用）
    /// 例如：900秒 -> "15:00"，65秒 -> "1:05"
    private func formatSeconds(_ seconds: Int) -> String {
        if seconds <= 0 {
            return "0:00"
        }

        let minutes = seconds / 60
        let secs = seconds % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// 格式化秒数为紧凑显示（紧凑态使用）
    /// 例如：900秒 -> "15分"，65秒 -> "1分"
    private func formatSecondsCompact(_ seconds: Int) -> String {
        if seconds <= 0 {
            return "即将"
        }

        let minutes = seconds / 60

        if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours)小时"
        } else if minutes > 0 {
            return "\(minutes)分"
        } else {
            return "\(seconds)秒"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/// 锁屏 Live Activity 视图
/// 与展开的 Dynamic Island 相同的布局：左侧课程详情，右侧倒计时+按钮
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CourseActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：课程详情卡片（与 Dynamic Island 展开态相同）
            VStack(alignment: .leading, spacing: 5) {
                // 课程名 - 允许换行显示，最多2行
                Text(context.state.courseName)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)

                // 教室 · 教师
                HStack(spacing: 3) {
                    if let classroom = context.state.classroom {
                        Text(classroom)
                            .font(.system(size: 12, weight: .semibold))
                            .fixedSize()  // 教室绝对不能截断
                    }

                    if let teacher = context.state.teacher {
                        Text("·")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(teacher)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .foregroundColor(.secondary)

                // 时间段
                Text("\(formatTime(context.state.startTime)) - \(formatTime(context.state.endTime))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(getCourseColor(context.attributes.color).opacity(0.12))
            )
            .overlay(
                // 左侧色条（与 Widget 完全一致的设计）
                GeometryReader { geometry in
                    let cornerRadius: CGFloat = 8
                    let cornerInset = cornerRadius * (1 - sqrt(2) / 2)

                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(getCourseColor(context.attributes.color))
                            .frame(width: 4)
                            .padding(.vertical, cornerInset)
                        Spacer()
                    }
                    .padding(.leading, -8)
                }
            )
            .padding(.horizontal, 4)  // 给色条留出呼吸空间

            // 右侧：倒计时 + "我已到达"按钮
            VStack(spacing: 12) {
                // 倒计时（大号显示，带秒数）
                VStack(spacing: 2) {
                    Text("还有")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(formatSeconds(context.state.secondsRemaining))
                        .font(.system(size: 22, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                }

                // "我已到达"按钮
                Link(destination: URL(string: "njuschedule://arrived/\(context.attributes.courseId)")!) {
                    Text("我已到达")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(getCourseColor(context.attributes.color).opacity(0.15))
                        .foregroundColor(getCourseColor(context.attributes.color))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
    }

    private func getCourseColor(_ colorHex: String?) -> Color {
        if let hex = colorHex {
            return Color(hex: hex)
        }
        return .blue
    }

    private func formatSeconds(_ seconds: Int) -> String {
        if seconds <= 0 {
            return "0:00"
        }

        let minutes = seconds / 60
        let secs = seconds % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
