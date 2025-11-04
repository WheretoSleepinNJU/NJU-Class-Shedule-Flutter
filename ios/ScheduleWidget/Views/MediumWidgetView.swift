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
        HStack(spacing: 16) {
            // 左侧：详细课程视图（类似小组件）
            LeftDetailView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 分隔线
            Divider()

            // 右侧：剩余课程列表或按钮
            RightContentView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 10)
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
        VStack(alignment: .leading, spacing: 2) {
            // 顶部日期栏
            DateHeaderView(
                date: entry.date,
                currentWeek: entry.widgetData?.currentWeek
            )
            .padding(.bottom, 2)

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

// MARK: - 左侧内容区域（根据状态切换）
private struct LeftContentAreaView: View {
    let entry: ScheduleEntry

    var body: some View {
        // 优先检查错误状态
        if let errorMessage = entry.errorMessage {
            ErrorView(message: errorMessage)
        } else {
            // 使用 entry 中显式设置的 displayState
            switch entry.displayState {
            case .beforeFirstClass:
                if let remainingCourses = getRemainingCourses() {
                    LeftBeforeClassView(
                        course: remainingCourses.0,
                        totalCount: remainingCourses.1,
                        isTomorrow: false,
                        isBetweenClasses: false,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LeftClassesEndedView()
                }

            case .betweenClasses:
                // 课间状态：显示"接下来"
                if let remainingCourses = getRemainingCourses() {
                    LeftBeforeClassView(
                        course: remainingCourses.0,
                        totalCount: remainingCourses.1,
                        isTomorrow: false,
                        isBetweenClasses: true,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LeftClassesEndedView()
                }

            case .approachingClass:
                if let next = entry.nextCourse {
                    LeftApproachingClassView(
                        nextCourse: next,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LeftClassesEndedView()
                }

            case .inClass:
                if let current = entry.currentCourse {
                    LeftInClassView(
                        currentCourse: current,
                        remainingCount: getRemainingCoursesCount(),
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LeftClassesEndedView()
                }

            case .classesEnded:
                LeftClassesEndedView()

            case .tomorrowPreview:
                if let tomorrowCourses = entry.widgetData?.tomorrowCourses, !tomorrowCourses.isEmpty {
                    LeftBeforeClassView(
                        course: tomorrowCourses[0],
                        totalCount: tomorrowCourses.count,
                        isTomorrow: true,
                        isBetweenClasses: false,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LeftClassesEndedView()
                }

            case .error:
                if let errorMessage = entry.errorMessage {
                    ErrorView(message: errorMessage)
                } else {
                    ErrorView(message: "发生错误")
                }
            }
        }
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
}

// MARK: - 左侧视图：上课前/课间/明日预览
private struct LeftBeforeClassView: View {
    let course: WidgetCourse
    let totalCount: Int
    let isTomorrow: Bool
    let isBetweenClasses: Bool  // 是否是课间状态
    var timeTemplate: SchoolTimeTemplate? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(promptText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            DetailedCourseCard(course: course, timeTemplate: timeTemplate)

            Spacer(minLength: 0)
        }
    }

    private var promptText: String {
        if isTomorrow {
            return "明天有 \(totalCount) 门课"
        } else if isBetweenClasses {
            return "接下来"
        } else {
            return "今天有 \(totalCount) 门课"
        }
    }
}

// MARK: - 左侧视图：即将上课
private struct LeftApproachingClassView: View {
    let nextCourse: WidgetCourse
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("接下来")
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
        VStack(alignment: .leading, spacing: adaptiveSpacing) {
            // 课程名 - 允许换行显示，最多2行
            Text(course.name)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)  // 允许垂直方向自动扩展
                .foregroundColor(.primary)

            // 教室 · 教师
            HStack(alignment: .top, spacing: 3) {
                if let classroom = course.classroom {
                    Text(classroom)
                        .font(.system(size: calculateClassroomFontSize(classroom), weight: .semibold))
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let teacher = course.teacher {
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text(teacher)
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .foregroundColor(.secondary)

            // 时间段
            if let timeRange = getTimeRange() {
                Text(timeRange)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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

    // 自适应间距：根据课程名称长度动态调整
    private var adaptiveSpacing: CGFloat {
        // 如果课程名称较长（可能换行），使用较小的间距保持整体紧凑
        return course.name.count > 12 ? 3 : 5
    }

    private var courseColor: Color {
        if let hex = course.color {
            return Color(hex: hex).enhancedForWidget()
        }
        return .blue.enhancedForWidget()
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
    
    // 根据教室名称长度计算字体大小
    private func calculateClassroomFontSize(_ classroom: String) -> CGFloat {
        if classroom.count > 15 {
            return 8
        } else if classroom.count > 10 {
            return 9
        }
        return 10
    }
}

// MARK: - 右侧内容视图
private struct RightContentView: View {
    let entry: ScheduleEntry

    var body: some View {
        // 使用 entry.displayState 来决定右侧显示内容
        switch entry.displayState {
        case .tomorrowPreview:
            // 明日预览：显示明天的课程列表
            if let tomorrowCourses = entry.widgetData?.tomorrowCourses, !tomorrowCourses.isEmpty {
                // 跳过第一门（左侧已显示），显示剩余课程
                let remainingCourses = Array(tomorrowCourses.dropFirst())
                if !remainingCourses.isEmpty {
                    RemainingCoursesListView(
                        courses: remainingCourses,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    EmptyRightView()
                }
            } else {
                EmptyRightView()
            }

        case .approachingClass:
            // 即将上课：显示"我已到达"按钮
            if let nextCourse = entry.nextCourse {
                ArrivedButtonView(courseId: nextCourse.id)
            } else {
                EmptyRightView()
            }

        case .classesEnded, .error:
            // 课程结束或错误：显示空状态
            EmptyRightView()
                .padding(.top)

        default:
            // 其他状态：显示剩余课程列表
            if let remaining = getRemainingCourses(), !remaining.isEmpty {
                RemainingCoursesListView(
                    courses: remaining,
                    timeTemplate: entry.widgetData?.timeTemplate
                )
            } else {
                // 没有剩余课程（可能只有一节课，或者最后一节课）
                LastCourseView()
            }
        }
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
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            // 课程列表 (最多显示3门课)
            VStack(spacing: 4) {
                ForEach(Array(courses.prefix(3)), id: \.id) { course in
                    CompactCourseRow(
                        course: course,
                        timeTemplate: timeTemplate
                    )
                }
            }

            // 如果还有更多课程，显示提示
            if courses.count > 3 {
                Text("还有 \(courses.count - 3) 门课……")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .center)
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
            VStack(alignment: .leading, spacing: 1) {
                // 课程名
                Text(course.name)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                // 时间、地点、教师
                HStack(spacing: 3) {
                    if let timeRange = getTimeRange() {
                        Text(timeRange)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }

                    if let classroom = course.classroom {
                        Text("·")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)

                        Text(classroom)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    if let teacher = course.teacher {
                        Text("·")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)

                        Text(teacher)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(courseColor.opacity(0.08))
            )
            .overlay(
                // 左侧色块（对齐圆角矩形，避开圆角部分）
                GeometryReader { geometry in
                    let cornerRadius: CGFloat = 5
                    let cornerInset = cornerRadius * (1 - sqrt(2) / 2)

                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(courseColor)
                            .frame(width: 3)
                            .padding(.vertical, cornerInset)
                        Spacer()
                    }
                    .padding(.leading, -6)
                }
            )
        }
    }

    private var courseColor: Color {
        if let hex = course.color {
            return Color(hex: hex).enhancedForWidget()
        }
        return .blue.enhancedForWidget()
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
    
    // 根据教室名称长度计算字体大小
    private func calculateClassroomFontSize(_ classroom: String) -> CGFloat {
        if classroom.count > 15 {
            return 8
        } else if classroom.count > 10 {
            return 9
        }
        return 10
    }
}

// MARK: - 右侧空状态视图（课程已全部结束）
private struct EmptyRightView: View {
    var body: some View {
        VStack(spacing: 6) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.6))

            Text("好好休息吧")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 右侧最后一节课视图
private struct LastCourseView: View {
    var body: some View {
        VStack(spacing: 6) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.6))

            Text("这就是全部啦")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

