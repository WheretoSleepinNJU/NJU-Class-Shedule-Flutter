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
            classroom: "仙II-308",
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
            classroom: "仙II-410",
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

    // MARK: - 预览场景

    /// 场景 1：上课前（早上 7:30，今天有 6 门课）
    static func beforeFirstClass() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "1.0",
            timestamp: "2025-01-15T07:30:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            nextCourse: sampleCourses[0],
            currentCourse: nil,
            weekSchedule: [:],
            todayCourseCount: 6,
            tomorrowCourseCount: 0,
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
            date: Date(),
            widgetData: widgetData,
            nextCourse: sampleCourses[0],
            currentCourse: nil,
            todayCourses: sampleCourses,
            errorMessage: nil,
            displayState: .beforeFirstClass
        )
    }

    /// 场景 2：即将上课（距离第一门课 10 分钟）
    static func approachingClass() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "1.0",
            timestamp: "2025-01-15T07:50:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            nextCourse: sampleCourses[0],
            currentCourse: nil,
            weekSchedule: [:],
            todayCourseCount: 6,
            tomorrowCourseCount: 0,
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
            date: Date(),
            widgetData: widgetData,
            nextCourse: sampleCourses[0],
            currentCourse: nil,
            todayCourses: sampleCourses,
            errorMessage: nil,
            displayState: .approachingClass
        )
    }

    /// 场景 3：课间休息（第二门课已结束，距离第三门课还有一段时间）
    static func betweenClasses() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "1.0",
            timestamp: "2025-01-15T13:00:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            nextCourse: sampleCourses[2],  // 第三门课是下一门
            currentCourse: nil,
            weekSchedule: [:],
            todayCourseCount: 6,
            tomorrowCourseCount: 0,
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
            date: Date(),
            widgetData: widgetData,
            nextCourse: sampleCourses[2],
            currentCourse: nil,
            todayCourses: sampleCourses,
            errorMessage: nil,
            displayState: .betweenClasses
        )
    }

    /// 场景 4：上课中（正在上第三门课，还有 3 门课）
    static func inClass() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "1.0",
            timestamp: "2025-01-15T14:30:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: sampleCourses,
            tomorrowCourses: [],
            nextCourse: sampleCourses[3],
            currentCourse: sampleCourses[2],
            weekSchedule: [:],
            todayCourseCount: 6,
            tomorrowCourseCount: 0,
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
            date: Date(),
            widgetData: widgetData,
            nextCourse: sampleCourses[3],
            currentCourse: sampleCourses[2],
            todayCourses: sampleCourses,
            errorMessage: nil,
            displayState: .inClass
        )
    }

    /// 场景 5：课程结束（今日所有课程已结束）
    static func classesEnded() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "1.0",
            timestamp: "2025-01-15T18:00:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: [],
            tomorrowCourses: Array(sampleCourses.prefix(3)),
            nextCourse: nil,
            currentCourse: nil,
            weekSchedule: [:],
            todayCourseCount: 0,
            tomorrowCourseCount: 3,
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
            date: Date(),
            widgetData: widgetData,
            nextCourse: nil,
            currentCourse: nil,
            todayCourses: [],
            errorMessage: nil,
            displayState: .classesEnded
        )
    }

    /// 场景 6：明天预览（晚上 21:00 后）
    static func tomorrowPreview() -> ScheduleEntry {
        let tomorrowCourses = Array(sampleCourses.prefix(3))

        let widgetData = WidgetScheduleData(
            version: "1.0",
            timestamp: "2025-01-15T21:30:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 1,
            semesterName: "2024-2025学年第一学期",
            todayCourses: [],
            tomorrowCourses: tomorrowCourses,
            nextCourse: nil,
            currentCourse: nil,
            weekSchedule: [:],
            todayCourseCount: 0,
            tomorrowCourseCount: 3,
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
            date: Date(),
            widgetData: widgetData,
            nextCourse: nil,
            currentCourse: nil,
            todayCourses: [],
            errorMessage: nil,
            displayState: .tomorrowPreview
        )
    }

    /// 场景 7：无数据（需要打开应用）
    static func noData() -> ScheduleEntry {
        return ScheduleEntry(
            date: Date(),
            widgetData: nil,
            nextCourse: nil,
            currentCourse: nil,
            todayCourses: [],
            errorMessage: "打开应用更新数据",
            displayState: .error
        )
    }

    /// 场景 8：今日无课
    static func noCourses() -> ScheduleEntry {
        let widgetData = WidgetScheduleData(
            version: "1.0",
            timestamp: "2025-01-15T10:00:00Z",
            schoolId: "nju",
            schoolName: "南京大学",
            timeTemplate: njuTimeTemplate,
            currentWeek: 5,
            currentWeekDay: 6,  // 周六
            semesterName: "2024-2025学年第一学期",
            todayCourses: [],
            tomorrowCourses: [],
            nextCourse: nil,
            currentCourse: nil,
            weekSchedule: [:],
            todayCourseCount: 0,
            tomorrowCourseCount: 0,
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
            date: Date(),
            widgetData: widgetData,
            nextCourse: nil,
            currentCourse: nil,
            todayCourses: [],
            errorMessage: nil,
            displayState: .classesEnded
        )
    }
}
