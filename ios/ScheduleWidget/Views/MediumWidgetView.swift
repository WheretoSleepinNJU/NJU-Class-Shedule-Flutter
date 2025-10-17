import SwiftUI
import WidgetKit

/// 中等尺寸 Widget 主视图
/// 左侧：显示详细的当前课程（类似小组件）
/// 右侧：显示今日剩余课程列表 或 "我已到达"按钮
struct MediumWidgetView: View {
    let entry: ScheduleEntry

    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：详细课程视图（类似小组件）
            LeftDetailView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 分隔线
            Divider()

            // 右侧：剩余课程列表或按钮
            RightContentView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - 左侧详细视图
private struct LeftDetailView: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 顶部日期栏
            DateHeaderView(
                date: entry.date,
                currentWeek: entry.widgetData?.currentWeek
            )
            .padding(.bottom, 4)

            // 主内容区域（复用小组件的逻辑）
            LeftContentAreaView(entry: entry)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 左侧日期头部
private struct DateHeaderView: View {
    let date: Date
    let currentWeek: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text(weekdayString)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            if let week = currentWeek {
                Text("第 \(week) 周")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
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

// MARK: - 左侧内容区域（根据状态切换）
private struct LeftContentAreaView: View {
    let entry: ScheduleEntry

    var body: some View {
        // 优先检查错误状态
        if let errorMessage = entry.errorMessage {
            ErrorView(message: errorMessage)
        } else {
            let displayState = determineDisplayState()

            switch displayState {
            case .beforeFirstClass(let first, let total):
                LeftBeforeClassView(
                    course: first,
                    totalCount: total,
                    isTomorrow: false,
                    timeTemplate: entry.widgetData?.timeTemplate
                )

            case .approachingClass(let next):
                LeftApproachingClassView(
                    nextCourse: next,
                    timeTemplate: entry.widgetData?.timeTemplate
                )

            case .inClass(let current, let remaining):
                LeftInClassView(
                    currentCourse: current,
                    remainingCount: remaining,
                    timeTemplate: entry.widgetData?.timeTemplate
                )

            case .classesEnded:
                LeftClassesEndedView()

            case .tomorrowPreview(let first, let total):
                LeftBeforeClassView(
                    course: first,
                    totalCount: total,
                    isTomorrow: true,
                    timeTemplate: entry.widgetData?.timeTemplate
                )
            }
        }
    }

    // MARK: - 状态判断逻辑
    private func determineDisplayState() -> LeftDisplayState {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // 1. 晚上 21:00 后显示明日预览
        if currentHour >= 21 {
            if let tomorrow = entry.widgetData?.tomorrowCourses,
               !tomorrow.isEmpty {
                return .tomorrowPreview(
                    first: tomorrow[0],
                    total: tomorrow.count
                )
            }
        }

        // 2. 正在上课
        if let current = entry.currentCourse {
            let remaining = getRemainingCoursesCount()
            return .inClass(current: current, remaining: remaining)
        }

        // 3. 检查是否即将上课（提前时间内，默认15分钟）
        if let next = entry.nextCourse,
           let template = entry.widgetData?.timeTemplate {
            if let minutesUntil = getMinutesUntilCourse(next, template: template),
               minutesUntil > 0 && minutesUntil <= 15 {
                return .approachingClass(next: next)
            }
        }

        // 4. 今日还有课程
        if entry.nextCourse != nil {
            if let remainingCourses = getRemainingCourses() {
                return .beforeFirstClass(
                    first: remainingCourses.0,
                    total: remainingCourses.1
                )
            }
        }

        // 5. 如果今天有课但没有nextCourse，可能是数据问题，显示所有今日课程
        if let todayCourses = entry.widgetData?.todayCourses,
           !todayCourses.isEmpty,
           entry.nextCourse == nil {
            return .beforeFirstClass(
                first: todayCourses[0],
                total: todayCourses.count
            )
        }

        // 6. 今日课程已结束
        return .classesEnded
    }

    // 获取剩余课程（从下一节课开始）
    private func getRemainingCourses() -> (WidgetCourse, Int)? {
        guard let nextCourse = entry.nextCourse,
              let todayCourses = entry.widgetData?.todayCourses else {
            return nil
        }

        guard let nextIndex = todayCourses.firstIndex(where: { $0.id == nextCourse.id }) else {
            return (nextCourse, 1)
        }

        let remainingCount = todayCourses.count - nextIndex
        return (nextCourse, remainingCount)
    }

    // 获取剩余课程数量（包括当前正在上的课）
    private func getRemainingCoursesCount() -> Int {
        guard let currentCourse = entry.currentCourse,
              let todayCourses = entry.widgetData?.todayCourses else {
            return 0
        }

        guard let currentIndex = todayCourses.firstIndex(where: { $0.id == currentCourse.id }) else {
            return 0
        }

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

// MARK: - 左侧显示状态枚举
private enum LeftDisplayState {
    case beforeFirstClass(first: WidgetCourse, total: Int)
    case approachingClass(next: WidgetCourse)
    case inClass(current: WidgetCourse, remaining: Int)
    case classesEnded
    case tomorrowPreview(first: WidgetCourse, total: Int)
}

// MARK: - 左侧视图：上课前/明日预览
private struct LeftBeforeClassView: View {
    let course: WidgetCourse
    let totalCount: Int
    let isTomorrow: Bool
    var timeTemplate: SchoolTimeTemplate? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isTomorrow ? "明天有 \(totalCount) 门课" : "今天有 \(totalCount) 门课")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            DetailedCourseCard(course: course, timeTemplate: timeTemplate)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 左侧视图：即将上课
private struct LeftApproachingClassView: View {
    let nextCourse: WidgetCourse
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("即将上课")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)

            DetailedCourseCard(course: nextCourse, timeTemplate: timeTemplate)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 左侧视图：上课中
private struct LeftInClassView: View {
    let currentCourse: WidgetCourse
    let remainingCount: Int
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("上课中")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green.opacity(0.7))

                Spacer()

                if remainingCount > 0 {
                    Text("还有 \(remainingCount) 门")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            DetailedCourseCard(course: currentCourse, timeTemplate: timeTemplate)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 左侧视图：课程结束
private struct LeftClassesEndedView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)

                Text("今日课程已结束")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }
}

// MARK: - 详细课程卡片（仅显示一门课的完整信息）
private struct DetailedCourseCard: View {
    let course: WidgetCourse
    var timeTemplate: SchoolTimeTemplate? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 课程名
            Text(course.name)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(2)
                .foregroundColor(.primary)

            // 教室 + 教师
            HStack(spacing: 6) {
                if let classroom = course.classroom {
                    Text(classroom)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }

                if let teacher = course.teacher {
                    Text(teacher)
                        .font(.system(size: 11))
                        .lineLimit(1)
                }
            }
            .foregroundColor(.secondary)

            // 时间段
            if let timeRange = getTimeRange() {
                Text(timeRange)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(courseColor.opacity(0.12))
        )
        .overlay(
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
        .widgetURL(URL(string: "njuschedule://course/\(course.id)"))
    }

    private var courseColor: Color {
        if let hex = course.color {
            return Color(hex: hex)
        }
        return .blue
    }

    private func getTimeRange() -> String? {
        guard let template = timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            if course.periodCount > 1 {
                return "第 \(course.startPeriod)-\(course.startPeriod + course.periodCount - 1) 节"
            } else {
                return "第 \(course.startPeriod) 节"
            }
        }

        let startTime = formatTime(period.startTime)
        let endTime = formatTime(period.endTime)
        return "\(startTime) - \(endTime)"
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

// MARK: - 右侧内容视图
private struct RightContentView: View {
    let entry: ScheduleEntry

    var body: some View {
        let displayState = determineRightDisplayState()

        switch displayState {
        case .arrivedButton(let courseId):
            ArrivedButtonView(courseId: courseId)

        case .remainingCourses(let courses):
            RemainingCoursesListView(
                courses: courses,
                timeTemplate: entry.widgetData?.timeTemplate
            )

        case .empty:
            EmptyRightView()
        }
    }

    private func determineRightDisplayState() -> RightDisplayState {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // 晚上21:00后或课程结束，显示空状态
        if currentHour >= 21 || (entry.nextCourse == nil && entry.currentCourse == nil) {
            return .empty
        }

        // 即将上课：显示"我已到达"按钮
        if let next = entry.nextCourse,
           let template = entry.widgetData?.timeTemplate,
           entry.currentCourse == nil {
            if let minutesUntil = getMinutesUntilCourse(next, template: template),
               minutesUntil > 0 && minutesUntil <= 15 {
                return .arrivedButton(courseId: next.id)
            }
        }

        // 获取剩余课程列表
        if let remaining = getRemainingCourses() {
            return .remainingCourses(courses: remaining)
        }

        return .empty
    }

    // 获取剩余课程列表（不包括当前显示在左侧的课程）
    private func getRemainingCourses() -> [WidgetCourse]? {
        guard let todayCourses = entry.widgetData?.todayCourses,
              !todayCourses.isEmpty else {
            return nil
        }

        // 确定从哪门课开始显示
        let startCourse: WidgetCourse?
        if let current = entry.currentCourse {
            startCourse = current
        } else if let next = entry.nextCourse {
            startCourse = next
        } else {
            return nil
        }

        guard let start = startCourse,
              let startIndex = todayCourses.firstIndex(where: { $0.id == start.id }) else {
            return nil
        }

        // 返回除了第一门课之外的所有剩余课程
        let remainingCourses = Array(todayCourses[startIndex...])
        return remainingCourses.count > 1 ? Array(remainingCourses.dropFirst()) : []
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

// MARK: - 右侧显示状态枚举
private enum RightDisplayState {
    case arrivedButton(courseId: String)
    case remainingCourses(courses: [WidgetCourse])
    case empty
}

// MARK: - "我已到达"按钮视图
private struct ArrivedButtonView: View {
    let courseId: String

    var body: some View {
        VStack {
            Spacer()

            Link(destination: URL(string: "njuschedule://arrived/\(courseId)")!) {
                VStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)

                    Text("我已到达")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)
            }

            Spacer()
        }
    }
}

// MARK: - 剩余课程列表视图
private struct RemainingCoursesListView: View {
    let courses: [WidgetCourse]
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            Text("剩余课程")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            // 课程列表 (最多显示4门课，移除ScrollView因为widgets不支持)
            VStack(spacing: 6) {
                ForEach(Array(courses.prefix(4)), id: \.id) { course in
                    CompactCourseRow(
                        course: course,
                        timeTemplate: timeTemplate
                    )
                }
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 紧凑课程行
private struct CompactCourseRow: View {
    let course: WidgetCourse
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        Link(destination: URL(string: "njuschedule://course/\(course.id)")!) {
            HStack(spacing: 6) {
                // 左侧色块
                RoundedRectangle(cornerRadius: 2)
                    .fill(courseColor)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 2) {
                    // 课程名
                    Text(course.name)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    // 时间和地点
                    HStack(spacing: 4) {
                        if let timeRange = getTimeRange() {
                            Text(timeRange)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }

                        if let classroom = course.classroom {
                            Text("·")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)

                            Text(classroom)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(courseColor.opacity(0.08))
            )
        }
    }

    private var courseColor: Color {
        if let hex = course.color {
            return Color(hex: hex)
        }
        return .blue
    }

    private func getTimeRange() -> String? {
        guard let template = timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return "第\(course.startPeriod)节"
        }

        let startTime = formatTime(period.startTime)
        return startTime
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

// MARK: - 右侧空状态视图
private struct EmptyRightView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "moon.stars")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.5))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

