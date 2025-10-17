import SwiftUI
import WidgetKit

/// 小尺寸 Widget 主视图
/// 显示：日期 + 当前课程（详细）+ 下一节课（简化）
struct SmallWidgetView: View {
    let entry: ScheduleEntry

    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 顶部日期栏（固定在顶部）
            DateHeaderView(
                date: entry.date,
                currentWeek: entry.widgetData?.currentWeek
            )
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 主内容区域
            ContentAreaView(entry: entry)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            containerBackgroundColor
        }
    }

    // 根据渲染模式和颜色方案计算背景颜色
    private var containerBackgroundColor: Color {
        if renderingMode == .fullColor && colorScheme == .dark {
            // StandBy Night Mode: 深色背景
            return Color.black
        }
        // 其他模式：透明背景
        return Color.clear
    }
}

// MARK: - 日期头部
private struct DateHeaderView: View {
    let date: Date
    let currentWeek: Int?

    var body: some View {
        HStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text(weekdayString)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            Spacer()

            if let week = currentWeek {
                Text("第 \(week) 周")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(alignment: .center)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        return formatter.string(from: date)
    }

    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - 内容区域（根据状态切换）
private struct ContentAreaView: View {
    let entry: ScheduleEntry

    var body: some View {
        // 优先检查错误状态
        if let errorMessage = entry.errorMessage {
            ErrorView(message: errorMessage)
        } else {
            let displayState = determineDisplayState()

            switch displayState {
            case .beforeFirstClass(let first, let second, let total):
                BeforeClassView(
                    firstCourse: first,
                    secondCourse: second,
                    totalCount: total,
                    isTomorrow: false,
                    timeTemplate: entry.widgetData?.timeTemplate
                )

            case .approachingClass(let next):
                ApproachingClassView(nextCourse: next, timeTemplate: entry.widgetData?.timeTemplate)

            case .inClass(let current, let next):
                InClassView(
                    currentCourse: current,
                    nextCourse: next,
                    remainingCount: getRemainingCoursesCount(),
                    timeTemplate: entry.widgetData?.timeTemplate
                )

            case .classesEnded:
                ClassesEndedView()

            case .tomorrowPreview(let first, let second, let total):
                BeforeClassView(
                    firstCourse: first,
                    secondCourse: second,
                    totalCount: total,
                    isTomorrow: true,
                    timeTemplate: entry.widgetData?.timeTemplate
                )
            }
        }
    }

    // MARK: - 状态判断逻辑
    private func determineDisplayState() -> DisplayState {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // 1. 晚上 21:00 后显示明日预览
        if currentHour >= 21 {
            if let tomorrow = entry.widgetData?.tomorrowCourses,
               !tomorrow.isEmpty {
                return .tomorrowPreview(
                    first: tomorrow[0],
                    second: tomorrow.count > 1 ? tomorrow[1] : nil,
                    total: tomorrow.count
                )
            }
        }

        // 2. 正在上课
        if let current = entry.currentCourse {
            return .inClass(current: current, next: entry.nextCourse)
        }

        // 3. 检查是否即将上课（提前时间内，默认15分钟）
        if let next = entry.nextCourse,
           let template = entry.widgetData?.timeTemplate {
            if let minutesUntil = getMinutesUntilCourse(next, template: template),
               minutesUntil > 0 && minutesUntil <= 15 {
                return .approachingClass(next: next)
            }
        }

        // 4. 今日还有课程（检查是否有下一节课或未开始的课程）
        if entry.nextCourse != nil {
            // 有下一节课但不在15分钟内，获取剩余课程
            if let remainingCourses = getRemainingCourses() {
                return .beforeFirstClass(
                    first: remainingCourses.0,
                    second: remainingCourses.1,
                    total: remainingCourses.2
                )
            }
        }

        // 5. 如果今天有课但没有nextCourse，可能是数据问题，显示所有今日课程
        if let todayCourses = entry.widgetData?.todayCourses,
           !todayCourses.isEmpty,
           entry.nextCourse == nil {
            return .beforeFirstClass(
                first: todayCourses[0],
                second: todayCourses.count > 1 ? todayCourses[1] : nil,
                total: todayCourses.count
            )
        }

        // 6. 今日课程已结束
        return .classesEnded
    }

    // 获取剩余课程（从下一节课开始）
    private func getRemainingCourses() -> (WidgetCourse, WidgetCourse?, Int)? {
        guard let nextCourse = entry.nextCourse,
              let todayCourses = entry.widgetData?.todayCourses else {
            return nil
        }

        // 找到下一节课在今日课程中的位置
        guard let nextIndex = todayCourses.firstIndex(where: { $0.id == nextCourse.id }) else {
            // 如果找不到，返回nextCourse作为第一门课
            return (nextCourse, nil, 1)
        }

        let remainingCourses = Array(todayCourses[nextIndex...])
        let second = remainingCourses.count > 1 ? remainingCourses[1] : nil

        return (nextCourse, second, remainingCourses.count)
    }

    // 获取剩余课程数量（包括当前正在上的课）
    private func getRemainingCoursesCount() -> Int? {
        guard let currentCourse = entry.currentCourse,
              let todayCourses = entry.widgetData?.todayCourses else {
            return nil
        }

        // 找到当前课程在今日课程中的位置
        guard let currentIndex = todayCourses.firstIndex(where: { $0.id == currentCourse.id }) else {
            return nil
        }

        // 返回从当前课程开始的剩余课程数量
        return todayCourses.count - currentIndex
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

    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
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

// MARK: - 显示状态枚举
private enum DisplayState {
    case beforeFirstClass(first: WidgetCourse, second: WidgetCourse?, total: Int)
    case approachingClass(next: WidgetCourse)
    case inClass(current: WidgetCourse, next: WidgetCourse?)
    case classesEnded
    case tomorrowPreview(first: WidgetCourse, second: WidgetCourse?, total: Int)
}

// MARK: - 1. 上课前/明日预览视图
private struct BeforeClassView: View {
    let firstCourse: WidgetCourse
    let secondCourse: WidgetCourse?
    let totalCount: Int
    let isTomorrow: Bool
    var timeTemplate: SchoolTimeTemplate? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 提示文本
            if isTomorrow {
                Text("明天有 \(totalCount) 门课")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            } else {
                Text("接下来")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.bottom, 8)
            }

            // 第一门课（详细）
            CourseCardView(course: firstCourse, isDetailed: true, timeTemplate: timeTemplate)

            // 第二门课（简化）
            if let second = secondCourse {
                CourseCardView(course: second, isDetailed: false, timeTemplate: timeTemplate)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 2. 即将上课视图（带"我已到达"按钮）
private struct ApproachingClassView: View {
    let nextCourse: WidgetCourse
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("即将上课")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)
                .padding(.bottom, 8)

            // 下一节课（详细）
            CourseCardView(course: nextCourse, isDetailed: true, timeTemplate: timeTemplate)

            Spacer()

            // "我已到达"按钮
            Link(destination: URL(string: "njuschedule://arrived/\(nextCourse.id)")!) {
                HStack {
                    Spacer()
                    Text("我已到达")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - 3. 上课中视图
private struct InClassView: View {
    let currentCourse: WidgetCourse
    let nextCourse: WidgetCourse?
    let remainingCount: Int?  // 剩余课程数量（包括当前课）
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("上课中")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green.opacity(0.7))

                Spacer()

                if let remaining = remainingCount {
                    Text("今天还有 \(remaining) 门")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 8)

            // 当前课程（详细）
            CourseCardView(course: currentCourse, isDetailed: true, timeTemplate: timeTemplate)

            // 下一节课（简化）
            if let next = nextCourse {
                CourseCardView(course: next, isDetailed: false, timeTemplate: timeTemplate)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 4. 课程结束视图
private struct ClassesEndedView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)

                Text("今日课程已结束")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }
}

// MARK: - 课程卡片组件
private struct CourseCardView: View {
    let course: WidgetCourse
    let isDetailed: Bool  // 是否显示详细信息
    var timeTemplate: SchoolTimeTemplate? = nil  // 可选的时间模板

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // 右侧内容
            VStack(alignment: .leading, spacing: 2) {
                // 第一行：课程名
                Text(course.name)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                if isDetailed {
                    // 第二行：教室 + 教师
                    HStack(spacing: 6) {
                        if let classroom = course.classroom {
                            Text(classroom)
                                .font(.system(size: 11, weight: .semibold))
                                .fixedSize()  // 教室不能截断
                        }

                        if let teacher = course.teacher {
                            Text(teacher)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .foregroundColor(.secondary)

                    // 第三行：时间段
                    if let timeRange = getTimeRange() {
                        Text(timeRange)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(courseColor.opacity(0.12))
            )
            .overlay(
                // 左侧色块（对齐圆角矩形，避开圆角部分）
                GeometryReader { geometry in
                    let cornerRadius: CGFloat = 8
                    let cornerInset = cornerRadius * (1 - sqrt(2) / 2)

                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(courseColor)
                            .frame(width: 4)
                            .padding(.vertical, cornerInset)
                        Spacer()
                    }
                    .padding(.leading, -10)
                }
            )
        }
        .contentShape(Rectangle())
        .widgetURL(URL(string: "njuschedule://course/\(course.id)"))
    }

    // 获取课程颜色
    private var courseColor: Color {
        if let hex = course.color {
            return Color(hex: hex)
        }
        return .blue
    }

    // 获取时间范围
    private func getTimeRange() -> String? {
        guard let template = timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            // 如果没有时间模板，返回节次
            if course.periodCount > 1 {
                return "第 \(course.startPeriod)-\(course.startPeriod + course.periodCount - 1) 节"
            } else {
                return "第 \(course.startPeriod) 节"
            }
        }

        // 格式化时间
        let startTime = formatTime(period.startTime)
        let endTime = formatTime(period.endTime)
        return "\(startTime) - \(endTime)"
    }

    private func formatTime(_ timeString: String) -> String {
        // "08:00" -> "8:00"
        let components = timeString.split(separator: ":")
        if components.count == 2,
           let hour = Int(components[0]) {
            return "\(hour):\(components[1])"
        }
        return timeString
    }
}

