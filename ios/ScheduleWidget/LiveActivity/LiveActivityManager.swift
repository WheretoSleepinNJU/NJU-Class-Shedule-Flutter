import Foundation
import ActivityKit
import WidgetKit

/// Live Activity 管理器
/// 负责创建、更新和关闭 Live Activity
@available(iOS 16.1, *)
class LiveActivityManager {

    /// 单例
    static let shared = LiveActivityManager()

    private init() {}

    /// 当前活动的 Live Activity
    private var currentActivity: Activity<CourseActivityAttributes>?

    // MARK: - Public Methods

    /// 根据课程数据调度 Live Activity
    /// 应该在 Widget Timeline 更新时调用
    func scheduleLiveActivity(
        nextCourse: WidgetCourse?,
        currentCourse: WidgetCourse?,
        userConfig: LiveActivityConfig
    ) {
        // 检查是否有来自主应用的关闭请求
        checkAndHandleEndRequest()

        // 如果未启用，直接返回
        guard userConfig.isEnabled else {
            endCurrentActivity()
            return
        }

        // 如果正在上课，关闭 Live Activity
        if currentCourse != nil {
            endCurrentActivity()
            return
        }

        // 如果有下一节课，检查是否需要创建 Live Activity
        if let course = nextCourse {
            scheduleForCourse(course, config: userConfig)
        } else {
            // 没有下一节课，关闭现有的 Live Activity
            endCurrentActivity()
        }
    }

    /// 处理"我已到达"按钮点击
    func handleArrivedAction(courseId: String) {
        // 验证是否是当前 Live Activity 的课程
        if currentActivity?.attributes.courseId == courseId {
            endCurrentActivity()
        }
    }

    // MARK: - Private Methods

    /// 为特定课程调度 Live Activity
    private func scheduleForCourse(_ course: WidgetCourse, config: LiveActivityConfig) {
        let now = Date()

        // 计算课程开始时间
        guard let timeTemplate = loadTimeTemplate(),
              let period = timeTemplate.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            print("⚠️ [LiveActivity] No time template found")
            return
        }

        let startTime = parseTime(period.startTime) ?? now
        let endTime = parseTime(period.endTime) ?? now

        // 计算提前时间（分钟转秒）
        let minutesBefore = TimeInterval(config.minutesBefore * 60)
        let triggerTime = startTime.addingTimeInterval(-minutesBefore)

        // 计算距离上课还有多少秒
        let secondsRemaining = Int(startTime.timeIntervalSince(now))

        // 判断是否应该创建 Live Activity
        if now >= triggerTime && now < startTime {
            // 在触发窗口内，创建或更新 Live Activity
            if currentActivity == nil || currentActivity?.attributes.courseId != course.id {
                // 需要创建新的 Live Activity
                startLiveActivity(
                    course: course,
                    startTime: startTime,
                    endTime: endTime,
                    secondsRemaining: max(0, secondsRemaining),
                    config: config
                )
            } else {
                // 更新现有的 Live Activity（更新倒计时）
                updateLiveActivity(secondsRemaining: max(0, secondsRemaining))
            }
        } else if now >= startTime {
            // 已经上课了，关闭 Live Activity
            endCurrentActivity()
        } else {
            // 还没到触发时间，不做任何操作
            // iOS 会在下次 Timeline 刷新时重新检查
            print("ℹ️ [LiveActivity] Too early, will trigger at \(triggerTime)")
        }
    }

    /// 创建新的 Live Activity
    private func startLiveActivity(
        course: WidgetCourse,
        startTime: Date,
        endTime: Date,
        secondsRemaining: Int,
        config: LiveActivityConfig
    ) {
        // 先关闭现有的
        endCurrentActivity()

        let attributes = CourseActivityAttributes(
            courseId: course.id,
            color: course.color
        )

        let contentState = CourseActivityAttributes.ContentState(
            courseName: course.name,
            classroom: course.classroom,
            teacher: course.teacher,
            startTime: startTime,
            endTime: endTime,
            secondsRemaining: secondsRemaining,
            motivationalTextLeft: config.textLeft,
            motivationalTextRight: config.textRight
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )

            currentActivity = activity
            print("✅ [LiveActivity] Started for course: \(course.name)")
        } catch {
            print("❌ [LiveActivity] Failed to start: \(error)")
        }
    }

    /// 更新 Live Activity 的倒计时
    private func updateLiveActivity(secondsRemaining: Int) {
        guard let activity = currentActivity else { return }

        Task {
            var updatedState = activity.contentState
            updatedState.secondsRemaining = secondsRemaining

            await activity.update(using: updatedState)
            print("🔄 [LiveActivity] Updated countdown: \(secondsRemaining)s")
        }
    }

    /// 关闭当前的 Live Activity
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(dismissalPolicy: .immediate)
            print("🛑 [LiveActivity] Ended")
        }

        currentActivity = nil
    }

    // MARK: - Helper Methods

    /// 检查并处理来自主应用的关闭请求
    private func checkAndHandleEndRequest() {
        let defaults = UserDefaults(suiteName: "group.com.flwfdd.mergeSchedule")

        guard let requestedCourseId = defaults?.string(forKey: "liveActivityEndRequest"),
              let requestTime = defaults?.object(forKey: "liveActivityEndRequestTime") as? Date else {
            return
        }

        // 只处理最近5秒内的请求，避免处理过期的请求
        let now = Date()
        guard now.timeIntervalSince(requestTime) < 5 else {
            return
        }

        // 如果请求的课程与当前活动匹配，则关闭
        if currentActivity?.attributes.courseId == requestedCourseId {
            endCurrentActivity()

            // 清除请求标记
            defaults?.removeObject(forKey: "liveActivityEndRequest")
            defaults?.removeObject(forKey: "liveActivityEndRequestTime")
            defaults?.synchronize()

            print("✅ [LiveActivity] Handled end request for course: \(requestedCourseId)")
        }
    }

    /// 加载时间模板
    private func loadTimeTemplate() -> SchoolTimeTemplate? {
        let defaults = UserDefaults(suiteName: "group.com.flwfdd.mergeSchedule")
        guard let jsonString = defaults?.string(forKey: "widgetTimeTemplate"),
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(SchoolTimeTemplate.self, from: jsonData)
    }

    /// 解析时间字符串为今天的 Date
    private func parseTime(_ timeString: String) -> Date? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0

        return calendar.date(from: dateComponents)
    }
}

/// Live Activity 用户配置
struct LiveActivityConfig {
    let isEnabled: Bool
    let minutesBefore: Int  // 使用与小组件相同的"即将上课提醒时间"
    let textLeft: String
    let textRight: String

    /// 从 SharedPreferences 加载配置
    static func load() -> LiveActivityConfig {
        let defaults = UserDefaults(suiteName: "group.com.flwfdd.mergeSchedule")

        return LiveActivityConfig(
            isEnabled: defaults?.bool(forKey: "flutter.liveActivityEnabled") ?? true,
            minutesBefore: defaults?.integer(forKey: "flutter.widgetApproachingMinutes") ?? 15,  // 使用小组件的配置
            textLeft: defaults?.string(forKey: "flutter.liveActivityTextLeft") ?? "好好学习",
            textRight: defaults?.string(forKey: "flutter.liveActivityTextRight") ?? "天天向上"
        )
    }
}
