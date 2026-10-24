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
    var semesterCourses: [WidgetCourse]? = nil
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

// MARK: - Calendar projection shared by snapshots and future timeline entries
extension WidgetScheduleData {
    /// Keep every course boundary: dropping nearby transitions can freeze an
    /// ended class until the next distant entry or the following day.
    func transitionDates(after now: Date, calendar: Calendar = .current) -> [Date] {
        var dates = Set<Date>()
        func time(_ value: String) -> Date? {
            let parts = value.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
            return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: now)
        }
        for course in todayCourses {
            guard let period = timeTemplate.getPeriodRange(startPeriod: course.startPeriod, periodCount: course.periodCount) else { continue }
            if let start = time(period.startTime) {
                dates.insert(start)
                dates.insert(start.addingTimeInterval(-Double(approachingMinutes ?? 15) * 60))
            }
            if let end = time(period.endTime) { dates.insert(end) }
        }
        if let preview = calendar.date(bySettingHour: tomorrowPreviewHour ?? 21, minute: 0, second: 0, of: now) { dates.insert(preview) }
        if let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) { dates.insert(midnight) }
        return dates.filter { $0 > now }.sorted()
    }

    var requiresRefresh: Bool {
        dataSource == "empty" || dataSource == "stale"
    }

    func normalized(at date: Date, calendar: Calendar = .current) -> WidgetScheduleData {
        let sourceDate = parseWidgetISODate(timestamp) ?? parseWidgetISODate(lastUpdateTime)
        let dayShift = sourceDate.map {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: $0),
                                    to: calendar.startOfDay(for: date)).day ?? 0
        } ?? 0
        let weekday = ((calendar.component(.weekday, from: date) + 5) % 7) + 1
        // floor, rather than integer truncation, also handles a clock moved back.
        let week = currentWeek + Int(floor(Double(currentWeekDay - 1 + dayShift) / 7))
        let tomorrowDay = weekday == 7 ? 1 : weekday + 1
        let tomorrowWeek = weekday == 7 ? week + 1 : week
        // Older payloads may have an empty tomorrow snapshot. Merge available
        // candidates before filtering; never let an empty snapshot hide a course.
        let candidates = semesterCourses ??
            (weekSchedule.values.flatMap { $0 } + todayCourses + tomorrowCourses)
        func courses(day: Int, week: Int) -> [WidgetCourse] {
            var ids = Set<String>()
            return candidates.filter {
                $0.weekDay == day && $0.weeks.contains(week) && ids.insert($0.id).inserted
            }.sorted { $0.startPeriod == $1.startPeriod ? $0.id < $1.id : $0.startPeriod < $1.startPeriod }
        }
        let today = courses(day: weekday, week: week)
        let tomorrow = courses(day: tomorrowDay, week: tomorrowWeek)
        let schedule = Dictionary(uniqueKeysWithValues: (1...7).map {
            (String($0), courses(day: $0, week: week))
        })
        // A legacy weekly snapshot cannot prove that a different week is empty.
        let incomplete = sourceDate == nil ||
            (semesterCourses == nil && week != currentWeek && totalCourses > 0)
        let formatter = ISO8601DateFormatter()
        return WidgetScheduleData(
            version: version, timestamp: formatter.string(from: date),
            schoolId: schoolId, schoolName: schoolName, timeTemplate: timeTemplate,
            currentWeek: week, currentWeekDay: weekday, semesterName: semesterName,
            todayCourses: today, tomorrowCourses: tomorrow, weekSchedule: schedule,
            weekCourseCount: schedule.values.reduce(0) { $0 + $1.count },
            hasCoursesToday: !today.isEmpty, hasCoursesTomorrow: !tomorrow.isEmpty,
            dataSource: incomplete ? "stale" : dataSource, totalCourses: totalCourses,
            lastUpdateTime: lastUpdateTime, approachingMinutes: approachingMinutes,
            tomorrowPreviewHour: tomorrowPreviewHour, semesterCourses: semesterCourses)
    }
}

func parseWidgetISODate(_ value: String) -> Date? {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = iso.date(from: value) { return date }
    iso.formatOptions = [.withInternetDateTime]
    if let date = iso.date(from: value) { return date }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
        formatter.dateFormat = format
        if let date = formatter.date(from: value) { return date }
    }
    return nil
}
