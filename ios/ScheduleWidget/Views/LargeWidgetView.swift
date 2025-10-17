import SwiftUI
import WidgetKit

/// 大尺寸 Widget 主视图
/// 显示：日期 + 当前/强调课程（详细大字）+ 所有其他课程（紧凑）
struct LargeWidgetView: View {
    let entry: ScheduleEntry

    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 顶部日期栏
            DateHeaderView(
                date: entry.date,
                currentWeek: entry.widgetData?.currentWeek
            )
            .padding(.horizontal, 12)

            // 主内容区域
            LargeContentAreaView(entry: entry)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            containerBackgroundColor
        }
    }

    private var containerBackgroundColor: Color {
        if renderingMode == .fullColor && colorScheme == .dark {
            return Color.black
        }
        return Color.clear
    }
}

// MARK: - 日期头部
private struct DateHeaderView: View {
    let date: Date
    let currentWeek: Int?

    var body: some View {
        HStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(dateString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(weekdayString)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            Spacer()

            if let week = currentWeek {
                Text("第 \(week) 周")
                    .font(.system(size: 13, weight: .medium))
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

// MARK: - 大尺寸内容区域
private struct LargeContentAreaView: View {
    let entry: ScheduleEntry

    var body: some View {
        if let errorMessage = entry.errorMessage {
            LargeErrorView(message: errorMessage)
        } else {
            switch entry.displayState {
            case .beforeFirstClass:
                // 上课前：显示从第一节课开始的剩余课程
                if let remaining = getRemainingCourses() {
                    LargeBeforeClassView(
                        courses: remaining.courses,
                        emphasizedCourse: remaining.emphasizedCourse,
                        isBetweenClasses: false,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LargeClassesEndedView()
                }

            case .betweenClasses:
                // 课间：显示"接下来"和剩余课程
                if let remaining = getRemainingCourses() {
                    LargeBeforeClassView(
                        courses: remaining.courses,
                        emphasizedCourse: remaining.emphasizedCourse,
                        isBetweenClasses: true,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LargeClassesEndedView()
                }

            case .approachingClass:
                if let next = entry.nextCourse,
                   let todayCourses = entry.widgetData?.todayCourses {
                    LargeApproachingClassView(
                        nextCourse: next,
                        allCourses: todayCourses,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LargeClassesEndedView()
                }

            case .inClass:
                if let current = entry.currentCourse,
                   let todayCourses = entry.widgetData?.todayCourses {
                    LargeInClassView(
                        currentCourse: current,
                        allCourses: todayCourses,
                        timeTemplate: entry.widgetData?.timeTemplate
                    )
                } else {
                    LargeClassesEndedView()
                }

            case .classesEnded:
                LargeClassesEndedView()

            case .tomorrowPreview:
                if let tomorrowCourses = entry.widgetData?.tomorrowCourses, !tomorrowCourses.isEmpty {
                    LargeBeforeClassView(
                        courses: tomorrowCourses,
                        emphasizedCourse: tomorrowCourses[0],
                        isBetweenClasses: false,
                        timeTemplate: entry.widgetData?.timeTemplate,
                        isTomorrow: true
                    )
                } else {
                    LargeClassesEndedView()
                }

            case .error:
                LargeErrorView(message: entry.errorMessage ?? "发生错误")
            }
        }
    }

    // 获取剩余课程（从下一节课开始）
    private func getRemainingCourses() -> (courses: [WidgetCourse], emphasizedCourse: WidgetCourse)? {
        guard let nextCourse = entry.nextCourse,
              let todayCourses = entry.widgetData?.todayCourses else {
            return nil
        }

        // 找到下一节课在今日课程中的位置
        guard let nextIndex = todayCourses.firstIndex(where: { $0.id == nextCourse.id }) else {
            // 如果找不到，返回nextCourse作为唯一课程
            return ([nextCourse], nextCourse)
        }

        let remainingCourses = Array(todayCourses[nextIndex...])
        return (remainingCourses, nextCourse)
    }
}

// MARK: - 1. 上课前/课间/明日预览视图
private struct LargeBeforeClassView: View {
    let courses: [WidgetCourse]
    let emphasizedCourse: WidgetCourse
    var isBetweenClasses: Bool = false  // 是否是课间状态
    var timeTemplate: SchoolTimeTemplate? = nil
    var isTomorrow: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 提示文本
            Text(promptText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            // 强调的第一门课（详细大字）
            LargeDetailedCourseCard(course: emphasizedCourse, timeTemplate: timeTemplate)

            // 其他课程（紧凑列表）
            if courses.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(courses.dropFirst(), id: \.id) { course in
                        LargeCompactCourseCard(course: course, timeTemplate: timeTemplate)
                    }
                }
            }
        }
    }

    private var promptText: String {
        if isTomorrow {
            return "明天有 \(courses.count) 门课"
        } else if isBetweenClasses {
            return "接下来"
        } else {
            return "今天有 \(courses.count) 门课"
        }
    }
}

// MARK: - 2. 即将上课视图
private struct LargeApproachingClassView: View {
    let nextCourse: WidgetCourse
    let allCourses: [WidgetCourse]
    let timeTemplate: SchoolTimeTemplate?

    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("接下来")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.orange)

                // 下一节课（详细大字）
                LargeDetailedCourseCard(course: nextCourse, timeTemplate: timeTemplate)

                // 其他课程（紧凑列表，最多显示4门）
                if let remainingCourses = getRemainingCourses() {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(remainingCourses, id: \.id) { course in
                            LargeCompactCourseCard(course: course, timeTemplate: timeTemplate)
                                .opacity(getOpacityForIndex(index: remainingCourses.firstIndex(where: { $0.id == course.id }) ?? 0))
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // "我已到达"按钮贴底（根据渲染模式决定是否需要遮罩）
            if needsGradientMask {
                ZStack(alignment: .bottom) {
                    // 渐变遮罩（仅在StandBy等全色模式下显示）
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            backgroundColor.opacity(0.8),
                            backgroundColor
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 50)

                    arrivedButton
                }
            } else {
                arrivedButton
            }
        }
    }

    private var arrivedButton: some View {
        Link(destination: URL(string: "njuschedule://arrived/\(nextCourse.id)")!) {
            HStack {
                Spacer()
                Text("我已到达")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.15))
            .foregroundColor(.accentColor)
            .cornerRadius(10)
        }
    }

    // 是否需要渐变遮罩（仅在StandBy等全色模式下需要）
    private var needsGradientMask: Bool {
        return renderingMode == .fullColor
    }

    // 背景颜色（适配深色模式）
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    // 计算课程的透明度（第3-4门课逐渐变透明）
    private func getOpacityForIndex(index: Int) -> Double {
        if index < 2 {
            return 1.0  // 前两门完全不透明
        } else if index == 2 {
            return 0.7  // 第三门70%透明度
        } else {
            return 0.4  // 第四门40%透明度
        }
    }

    private func getRemainingCourses() -> [WidgetCourse]? {
        guard let nextIndex = allCourses.firstIndex(where: { $0.id == nextCourse.id }),
              nextIndex + 1 < allCourses.count else {
            return nil
        }
        // 最多显示4门后续课程（加上当前强调的课程，总共5门）
        let remaining = Array(allCourses[(nextIndex + 1)...])
        return Array(remaining.prefix(4))
    }
}

// MARK: - 3. 上课中视图
private struct LargeInClassView: View {
    let currentCourse: WidgetCourse
    let allCourses: [WidgetCourse]
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("上课中")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.green.opacity(0.7))

                Spacer()

                if let remaining = getRemainingCount() {
                    Text("今天还有 \(remaining) 门")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // 当前课程（详细大字）
            LargeDetailedCourseCard(course: currentCourse, timeTemplate: timeTemplate)

            // 其他课程（紧凑列表）
            if let remainingCourses = getRemainingCourses() {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(remainingCourses, id: \.id) { course in
                        LargeCompactCourseCard(course: course, timeTemplate: timeTemplate)
                    }
                }
            }
        }
    }

    private func getRemainingCourses() -> [WidgetCourse]? {
        guard let currentIndex = allCourses.firstIndex(where: { $0.id == currentCourse.id }),
              currentIndex + 1 < allCourses.count else {
            return nil
        }
        return Array(allCourses[(currentIndex + 1)...])
    }

    private func getRemainingCount() -> Int? {
        guard let currentIndex = allCourses.firstIndex(where: { $0.id == currentCourse.id }) else {
            return nil
        }
        return allCourses.count - currentIndex
    }
}

// MARK: - 4. 课程结束视图
private struct LargeClassesEndedView: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("今日课程已结束")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }
}

// MARK: - 错误视图
private struct LargeErrorView: View {
    let message: String

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }
}

// MARK: - 详细课程卡片（强调显示，大字体）
private struct LargeDetailedCourseCard: View {
    let course: WidgetCourse
    var timeTemplate: SchoolTimeTemplate? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                // 第一行：课程名 + 开始时间（右对齐）
                HStack(alignment: .firstTextBaseline) {
                    Text(course.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if let startTime = getStartTime() {
                        Text(startTime)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                // 第二行：教室·教师 + 结束时间（右对齐）
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 3) {
                        if let classroom = course.classroom {
                            Text(classroom)
                                .font(.system(size: 13, weight: .semibold))
                                .fixedSize()
                        }

                        if let teacher = course.teacher {
                            Text("·")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Text(teacher)
                                .font(.system(size: 13))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .foregroundColor(.secondary)

                    Spacer(minLength: 8)

                    if let endTime = getEndTime() {
                        Text(endTime)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(courseColor.opacity(0.12))
            )
            .overlay(
                GeometryReader { geometry in
                    let cornerRadius: CGFloat = 12
                    let cornerInset = cornerRadius * (1 - sqrt(2) / 2)

                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(courseColor)
                            .frame(width: 5)
                            .padding(.vertical, cornerInset)
                        Spacer()
                    }
                    .padding(.leading, -12)
                }
            )
        }
        .contentShape(Rectangle())
        .widgetURL(URL(string: "njuschedule://course/\(course.id)"))
    }

    private var courseColor: Color {
        if let hex = course.color {
            return Color(hex: hex)
        }
        return .blue
    }

    private func getStartTime() -> String? {
        guard let template = timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return "第\(course.startPeriod)节"
        }
        return formatTime(period.startTime)
    }

    private func getEndTime() -> String? {
        guard let template = timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return nil
        }
        return formatTime(period.endTime)
    }

    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        if components.count == 2, let hour = Int(components[0]) {
            return "\(hour):\(components[1])"
        }
        return timeString
    }
}

// MARK: - 紧凑课程卡片（其他课程）
private struct LargeCompactCourseCard: View {
    let course: WidgetCourse
    var timeTemplate: SchoolTimeTemplate? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                // 第一行：课程名 + 开始时间（右对齐）
                HStack(alignment: .firstTextBaseline) {
                    Text(course.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if let startTime = getStartTime() {
                        Text(startTime)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                // 第二行：教室·教师 + 结束时间（右对齐）
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 3) {
                        if let classroom = course.classroom {
                            Text(classroom)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .fixedSize()
                        }

                        if let teacher = course.teacher {
                            Text("·")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)

                            Text(teacher)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    Spacer(minLength: 8)

                    if let endTime = getEndTime() {
                        Text(endTime)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(courseColor.opacity(0.08))
            )
            .overlay(
                GeometryReader { geometry in
                    let cornerRadius: CGFloat = 8
                    let cornerInset = cornerRadius * (1 - sqrt(2) / 2)

                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(courseColor)
                            .frame(width: 3)
                            .padding(.vertical, cornerInset)
                        Spacer()
                    }
                    .padding(.leading, -8)
                }
            )
        }
        .contentShape(Rectangle())
        .widgetURL(URL(string: "njuschedule://course/\(course.id)"))
    }

    private var courseColor: Color {
        if let hex = course.color {
            return Color(hex: hex)
        }
        return .blue
    }

    private func getStartTime() -> String? {
        guard let template = timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return "第\(course.startPeriod)节"
        }
        return formatTime(period.startTime)
    }

    private func getEndTime() -> String? {
        guard let template = timeTemplate,
              let period = template.getPeriodRange(
                  startPeriod: course.startPeriod,
                  periodCount: course.periodCount
              ) else {
            return nil
        }
        return formatTime(period.endTime)
    }

    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        if components.count == 2, let hour = Int(components[0]) {
            return "\(hour):\(components[1])"
        }
        return timeString
    }
}
