import Foundation

// MARK: - Widget Course Model
struct WidgetCourse: Codable {
    let id: String
    let name: String
    let classroom: String?
    let teacher: String?
    let startPeriod: Int
    let periodCount: Int
    let weekDay: Int
    let color: String?
    let schoolId: String
    let weeks: [Int]
    let courseType: String?
    let notes: String?
}

// MARK: - Class Period Model
struct ClassPeriod: Codable {
    let startTime: String  // "08:00"
    let endTime: String    // "08:50"
}

// MARK: - School Time Template
struct SchoolTimeTemplate: Codable {
    let schoolId: String
    let schoolName: String
    let schoolNameEn: String
    let periods: [ClassPeriod]

    func getPeriod(periodNumber: Int) -> ClassPeriod? {
        guard periodNumber > 0 && periodNumber <= periods.count else { return nil }
        return periods[periodNumber - 1]
    }

    func getPeriodRange(startPeriod: Int, periodCount: Int) -> ClassPeriod? {
        guard startPeriod > 0 && startPeriod <= periods.count else { return nil }
        let endPeriod = startPeriod + periodCount - 1
        guard endPeriod <= periods.count else { return nil }

        return ClassPeriod(
            startTime: periods[startPeriod - 1].startTime,
            endTime: periods[endPeriod - 1].endTime
        )
    }
}

// MARK: - Widget Schedule Data
struct WidgetScheduleData: Codable {
    let version: String
    let timestamp: String
    let schoolId: String
    let schoolName: String
    let timeTemplate: SchoolTimeTemplate
    let currentWeek: Int
    let currentWeekDay: Int
    let semesterName: String
    let todayCourses: [WidgetCourse]
    let tomorrowCourses: [WidgetCourse]
    let weekSchedule: [String: [WidgetCourse]]  // Int keys are strings in JSON
    let weekCourseCount: Int
    let hasCoursesToday: Bool
    let hasCoursesTomorrow: Bool
    let dataSource: String
    let totalCourses: Int
    let lastUpdateTime: String

    // Configuration
    let approachingMinutes: Int?  // 即将上课提前时间（分钟），默认15
    let tomorrowPreviewHour: Int?  // 明日预览开始时间（小时），默认21
}

// MARK: - Live Activity Data
struct LiveActivityData: Codable {
    let activityId: String
    let courseId: String
    let courseName: String
    let classroom: String?
    let teacher: String?
    let startTime: String
    let endTime: String
    let schoolId: String
    let schoolName: String
    let status: String
    let trigger: String
    let progress: Double
    let timeText: String
    let statusText: String?
    let createdAt: String
    let updatedAt: String
    let notificationId: String?
}

// MARK: - Unified Data Package
struct UnifiedDataPackage: Codable {
    let type: String
    let version: String
    let timestamp: String
    let platform: String
    let data: UnifiedData
    let meta: UnifiedMeta

    struct UnifiedData: Codable {
        let widget: WidgetScheduleData?
        let liveActivities: LiveActivities?
        let custom: [String: AnyCodable]?

        struct LiveActivities: Codable {
            let activities: [LiveActivityData]
            let count: Int
            let summary: ActivitySummary?

            struct ActivitySummary: Codable {
                let totalCount: Int
                let upcomingCount: Int?
                let activeCount: Int?
                let hasUpcoming: Bool
                let hasActive: Bool
                let nextActivityTime: String?
                let nextActivityName: String?
            }
        }
    }

    struct UnifiedMeta: Codable {
        let hasWidgetData: Bool
        let hasLiveActivityData: Bool
        let hasCustomData: Bool
        let dataSize: Int
        let compression: String
        let encryption: String?
        let targetPlatform: String?
    }
}

// MARK: - AnyCodable for dynamic JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
