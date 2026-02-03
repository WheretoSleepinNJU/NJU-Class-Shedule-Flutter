import Foundation
import WidgetKit

/// 统一的预览数据提供者
/// 所有 Widget 尺寸共享相同的预览数据，实现响应式设计
struct WidgetPreviewData {

    // MARK: - 共享的时间模板
    static let njuTimeTemplate = SchoolTimeTemplate(
        schoolId: "nju",
        schoolName: "南京大学",
        schoolNameEn: "Nanjing University",
        periods: [
            ClassPeriod(startTime: "08:00", endTime: "08:50"),
            ClassPeriod(startTime: "09:00", endTime: "09:50"),
            ClassPeriod(startTime: "10:10", endTime: "11:00"),
            ClassPeriod(startTime: "11:10", endTime: "12:00"),
            ClassPeriod(startTime: "14:00", endTime: "14:50"),
            ClassPeriod(startTime: "15:00", endTime: "15:50"),
            ClassPeriod(startTime: "16:10", endTime: "17:00"),
            ClassPeriod(startTime: "17:10", endTime: "18:00"),
            ClassPeriod(startTime: "18:30", endTime: "19:20"),
            ClassPeriod(startTime: "19:30", endTime: "20:20"),
            ClassPeriod(startTime: "20:30", endTime: "21:20")
        ]
    )

    // MARK: - 共享的课程数据
    static let sampleCourses: [WidgetCourse] = [
        WidgetCourse(
            id: "1",
            name: "计算机组成原理",
            classroom: "非常非常非常长的教室名称",
            teacher: "冯诺曼",
            startPeriod: 1,
            periodCount: 2,
            weekDay: 1,
            color: "4CAF50",
            schoolId: "nju",
            weeks: [1, 2, 3, 4, 5, 6, 7, 8],
            courseType: "必修",
            notes: nil
        ),
        WidgetCourse(
            id: "2",
            name: "数据结构",
            classroom: "非常非常非常长的教室名称",
            teacher: "高德纳",
            startPeriod: 3,
            periodCount: 2,
            weekDay: 1,
            color: "FF9800",
            schoolId: "nju",
            weeks: [1, 2, 3, 4, 5, 6, 7, 8],
            courseType: "必修",
            notes: nil
        ),
        WidgetCourse(
            id: "3",
            name: "操作系统",
            classroom: "逸A-101",
            teacher: "林托瓦",
            startPeriod: 5,
            periodCount: 2,
            weekDay: 1,
            color: "2196F3",
            schoolId: "nju",
            weeks: [1, 2, 3, 4, 5, 6, 7, 8],
            courseType: "必修",
            notes: nil
        ),
        WidgetCourse(
            id: "4",
            name: "软件工程",
            classroom: "教1-208",
            teacher: "马汉顿",
            startPeriod: 7,
            periodCount: 2,
            weekDay: 1,
            color: "9C27B0",
            schoolId: "nju",
            weeks: [1, 2, 3, 4, 5, 6, 7, 8],
            courseType: "必修",
            notes: nil
        ),
        WidgetCourse(
            id: "5",
            name: "计算机网络",
            classroom: "仙I-202",
            teacher: "李博纳",
            startPeriod: 9,
            periodCount: 2,
            weekDay: 1,
            color: "E91E63",
            schoolId: "nju",
            weeks: [1, 2, 3, 4, 5, 6, 7, 8],
            courseType: "必修",
            notes: nil
        ),
        WidgetCourse(
            id: "6",
            name: "人工智能导论",
            classroom: "计科楼-301",
            teacher: "图灵",
            startPeriod: 11,
            periodCount: 2,
            weekDay: 1,
            color: "00BCD4",
            schoolId: "nju",
            weeks: [1, 2, 3, 4, 5, 6, 7, 8],
            courseType: "选修",
            notes: nil
        )
    ]

    private static func previewDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }

    // MARK: - 预览场景

    /// 场景 1：上课前（早上 7:30，今天有 6 门课）
    static func beforeFirstClass() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "2.0",
            timestamp: "2025-01-15T07:30:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            weekSchedule: [:],
            weekCourseCount: 24,
            hasCoursesToday: true,
            hasCoursesTomorrow: false,
            dataSource: "preview",
            totalCourses: 24,
            lastUpdateTime: "2025-01-15T07:30:00Z",
            approachingMinutes: 15,
            tomorrowPreviewHour: 21
        )

        return ScheduleEntry(
            date: previewDate(hour: 7, minute: 30),
            widgetData: widgetData,
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 10), // 今日还有课，但时间较远
            arrivedCourse: nil
        )
    }

    /// 场景 2：即将上课（距离第一门课 10 分钟）
    static func approachingClass() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "2.0",
            timestamp: "2025-01-15T07:50:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            weekSchedule: [:],
            weekCourseCount: 24,
            hasCoursesToday: true,
            hasCoursesTomorrow: false,
            dataSource: "preview",
            totalCourses: 24,
            lastUpdateTime: "2025-01-15T07:50:00Z",
            approachingMinutes: 15,
            tomorrowPreviewHour: 21
        )

        return ScheduleEntry(
            date: previewDate(hour: 7, minute: 50),
            widgetData: widgetData,
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 75), // 10分钟内即将上课，高优先级 (100 - 10*5 = 50，但这里用75)
            arrivedCourse: nil
        )
    }

    /// 场景 3：课间休息（第二门课已结束，距离第三门课还有一段时间）
    static func betweenClasses() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "2.0",
            timestamp: "2025-01-15T13:00:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            weekSchedule: [:],
            weekCourseCount: 24,
            hasCoursesToday: true,
            hasCoursesTomorrow: false,
            dataSource: "preview",
            totalCourses: 24,
            lastUpdateTime: "2025-01-15T13:00:00Z",
            approachingMinutes: 15,
            tomorrowPreviewHour: 21
        )

        return ScheduleEntry(
            date: previewDate(hour: 13, minute: 0),
            widgetData: widgetData,
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 10), // 今日还有课，但不是马上
            arrivedCourse: nil
        )
    }

    /// 场景 4：上课中（正在上第三门课，还有 3 门课）
    static func inClass() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "2.0",
            timestamp: "2025-01-15T14:30:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            weekSchedule: [:],
            weekCourseCount: 24,
            hasCoursesToday: true,
            hasCoursesTomorrow: false,
            dataSource: "preview",
            totalCourses: 24,
            lastUpdateTime: "2025-01-15T14:30:00Z",
            approachingMinutes: 15,
            tomorrowPreviewHour: 21
        )

        return ScheduleEntry(
            date: previewDate(hour: 14, minute: 30),
            widgetData: widgetData,
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 100, duration: 60), // 正在上课，最高优先级
            arrivedCourse: nil
        )
    }

    /// 场景 5：课程结束（今日所有课程已结束）
    static func classesEnded() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "2.0",
            timestamp: "2025-01-15T18:00:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: [],
            tomorrowCourses: Array(sampleCourses.prefix(3)),
            weekSchedule: [:],
            weekCourseCount: 24,
            hasCoursesToday: false,
            hasCoursesTomorrow: true,
            dataSource: "preview",
            totalCourses: 24,
            lastUpdateTime: "2025-01-15T18:00:00Z",
            approachingMinutes: 15,
            tomorrowPreviewHour: 21
        )

        return ScheduleEntry(
            date: previewDate(hour: 18, minute: 0),
            widgetData: widgetData,
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 0), // 课程已结束，不需要显示
            arrivedCourse: nil
        )
    }

    /// 场景 6：明天预览（晚上 21:00 后）
    static func tomorrowPreview() -> ScheduleEntry {
        let tomorrowCourses = Array(sampleCourses.prefix(3))

        let widgetData = WidgetScheduleData(
            version: "2.0",
            timestamp: "2025-01-15T21:30:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: [],
            tomorrowCourses: tomorrowCourses,
            weekSchedule: [:],
            weekCourseCount: 24,
            hasCoursesToday: false,
            hasCoursesTomorrow: true,
            dataSource: "preview",
            totalCourses: 24,
            lastUpdateTime: "2025-01-15T21:30:00Z",
            approachingMinutes: 15,
            tomorrowPreviewHour: 21
        )

        return ScheduleEntry(
            date: previewDate(hour: 21, minute: 30),
            widgetData: widgetData,
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 5), // 明日预览，很低优先级
            arrivedCourse: nil
        )
    }

    /// 场景 7：无数据（需要打开应用）
    static func noData() -> ScheduleEntry {
        return ScheduleEntry(
            date: Date(),
            widgetData: nil,
            errorMessage: "打开应用更新数据",
            relevance: TimelineEntryRelevance(score: 0), // 错误状态，不显示
            arrivedCourse: nil
        )
    }

    /// 场景 8：今日无课
    static func noCourses() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "2.0",
            timestamp: "2025-01-15T10:00:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 6,  // 周六
            semesterName: "2024-2025学年第一学期",
            todayCourses: [],
            tomorrowCourses: [],
            weekSchedule: [:],
            weekCourseCount: 24,
            hasCoursesToday: false,
            hasCoursesTomorrow: false,
            dataSource: "preview",
            totalCourses: 24,
            lastUpdateTime: "2025-01-15T10:00:00Z",
            approachingMinutes: 15,
            tomorrowPreviewHour: 21
        )

        return ScheduleEntry(
            date: previewDate(hour: 10, minute: 0),
            widgetData: widgetData,
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 0), // 今日无课，不需要显示
            arrivedCourse: nil
        )
    }

    // MARK: - Live Activity 预览场景

    /// Live Activity 场景 1：15分钟前（900秒）
    @available(iOS 16.1, *)
    static func liveActivity15MinBefore() -> (CourseActivityAttributes, CourseActivityAttributes.ContentState) {
        let course = sampleCourses[0]  // 计算机组成原理

        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .minute, value: 15, to: now)!
        let endTime = calendar.date(byAdding: .minute, value: 115, to: now)!  // 2小时后

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
            secondsRemaining: 900,  // 15分钟 = 900秒
            motivationalTextLeft: "好好学习",
            motivationalTextRight: "天天向上"
        )

        return (attributes, contentState)
    }

    /// Live Activity 场景 2：5分钟前（300秒）
    @available(iOS 16.1, *)
    static func liveActivity5MinBefore() -> (CourseActivityAttributes, CourseActivityAttributes.ContentState) {
        let course = sampleCourses[1]  // 数据结构

        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .minute, value: 5, to: now)!
        let endTime = calendar.date(byAdding: .minute, value: 105, to: now)!

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
            secondsRemaining: 300,  // 5分钟 = 300秒
            motivationalTextLeft: "放弃幻想",
            motivationalTextRight: "准备斗争"
        )

        return (attributes, contentState)
    }

    /// Live Activity 场景 3：1分钟前（65秒，显示秒数）
    @available(iOS 16.1, *)
    static func liveActivity1MinBefore() -> (CourseActivityAttributes, CourseActivityAttributes.ContentState) {
        let course = sampleCourses[2]  // 操作系统

        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .second, value: 65, to: now)!
        let endTime = calendar.date(byAdding: .minute, value: 100, to: now)!

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
            secondsRemaining: 65,  // 1分5秒
            motivationalTextLeft: "准时到",
            motivationalTextRight: "不迟到"
        )

        return (attributes, contentState)
    }

    /// Live Activity 场景 4：30秒前（即将开始）
    @available(iOS 16.1, *)
    static func liveActivity30SecBefore() -> (CourseActivityAttributes, CourseActivityAttributes.ContentState) {
        let course = sampleCourses[3]  // 软件工程

        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .second, value: 30, to: now)!
        let endTime = calendar.date(byAdding: .minute, value: 100, to: now)!

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
            secondsRemaining: 30,  // 30秒
            motivationalTextLeft: "专注听讲",
            motivationalTextRight: "认真笔记"
        )

        return (attributes, contentState)
    }

    /// Live Activity 场景 5：长课程名测试
    @available(iOS 16.1, *)
    static func liveActivityLongName() -> (CourseActivityAttributes, CourseActivityAttributes.ContentState) {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(byAdding: .minute, value: 10, to: now)!
        let endTime = calendar.date(byAdding: .minute, value: 110, to: now)!

        let attributes = CourseActivityAttributes(
            courseId: "test_long",
            color: "9C27B0"
        )

        let contentState = CourseActivityAttributes.ContentState(
            courseName: "马克思主义基本原理概论与中国特色社会主义理论体系",
            classroom: "仙II-301",
            teacher: "张教授",
            startTime: startTime,
            endTime: endTime,
            secondsRemaining: 600,  // 10分钟
            motivationalTextLeft: "认真学",
            motivationalTextRight: "好好记"
        )

        return (attributes, contentState)
    }
}
