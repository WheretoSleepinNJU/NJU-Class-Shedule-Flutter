import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    if !condition() { fatalError("FAIL: \(name)") }
    checks += 1
    print("PASS: \(name)")
}
let fixture: [String: Any] = [
    "version": "2.1", "timestamp": "2026-10-19T12:00:00.123456+08:00",
    "lastUpdateTime": "2026-10-19T12:00:00.123456+08:00",
    "schoolId": "qa", "schoolName": "QA", "semesterName": "QA",
    "timeTemplate": ["schoolId": "qa", "schoolName": "QA", "schoolNameEn": "QA", "periods": [["startTime": "08:00", "endTime": "08:50"]]],
    "currentWeek": 1, "currentWeekDay": 1,
    "todayCourses": [], "tomorrowCourses": [], "weekSchedule": [:],
    "weekCourseCount": 0, "hasCoursesToday": false, "hasCoursesTomorrow": false,
    "dataSource": "sqlite", "totalCourses": 4
]
func course(_ id: String, day: Int, weeks: [Int]) -> [String: Any] {
    ["id": id, "name": id, "startPeriod": 1, "periodCount": 1,
     "weekDay": day, "schoolId": "qa", "weeks": weeks]
}
func decode(_ values: [String: Any]) -> WidgetScheduleData {
    try! JSONDecoder().decode(WidgetScheduleData.self, from: JSONSerialization.data(withJSONObject: values))
}
func date(_ text: String) -> Date { parseWidgetISODate(text)! }
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
var values = fixture
let monday = course("ThisWeek", day: 1, weeks: [1])
let nextWeek = course("NextWeek", day: 1, weeks: [2])
let tuesday = course("Tuesday", day: 2, weeks: [1, 2])
let unscheduled = course("EmptyWeeks", day: 1, weeks: [])
values["todayCourses"] = [monday, nextWeek, unscheduled]
values["semesterCourses"] = [monday, nextWeek, tuesday, unscheduled]
let source = decode(values)
let same = source.normalized(at: date("2026-10-19T13:00:00+08:00"), calendar: calendar)
check(same.todayCourses.map(\.id) == ["ThisWeek"], "same-day snapshot excludes other weeks and empty weeks (#71)")
let midnight = same.normalized(at: date("2026-10-20T00:00:00+08:00"), calendar: calendar)
check(midnight.todayCourses.map(\.id) == ["Tuesday"], "future midnight entry uses target day's courses (#76)")
check(midnight.currentWeek == 1 && midnight.currentWeekDay == 2, "midnight retains correct week")
let week2 = source.normalized(at: date("2026-10-26T00:00:00+08:00"), calendar: calendar)
check(week2.todayCourses.map(\.id) == ["NextWeek"], "seven-day-old payload resolves next-week-only course")
check(week2.currentWeek == 2, "week increments after seven days")
let again = week2.normalized(at: date("2026-10-26T10:00:00+08:00"), calendar: calendar)
check(again.currentWeek == 2, "re-normalizing a timeline does not advance week twice")
let sunday = source.normalized(at: date("2026-10-25T23:59:00+08:00"), calendar: calendar)
check(sunday.tomorrowCourses.map(\.id) == ["NextWeek"], "Sunday preview filters by next week")
check(sunday.normalized(at: date("2026-10-26T00:00:00+08:00"), calendar: calendar).todayCourses.map(\.id) == ["NextWeek"], "Sunday-to-Monday future entry")
values.removeValue(forKey: "semesterCourses")
values["weekSchedule"] = ["1": [monday], "2": [tuesday]]
let legacy = decode(values)
check(legacy.normalized(at: date("2026-10-20T00:00:00+08:00"), calendar: calendar).todayCourses.map(\.id) == ["Tuesday"], "legacy empty tomorrow snapshot falls back to weekly data")
check(legacy.normalized(at: date("2026-10-26T00:00:00+08:00"), calendar: calendar).requiresRefresh, "incomplete old-week data requests refresh")
check(!source.normalized(at: date("2026-10-21T12:00:00+08:00"), calendar: calendar).requiresRefresh, "known empty day is valid")
check(parseWidgetISODate("2026-10-19T12:00:00.123456") != nil, "Dart local microsecond timestamp")
check(parseWidgetISODate("2026-10-19T04:00:00.123456Z") != nil, "UTC microsecond timestamp")
var shortValues = fixture
shortValues["todayCourses"] = [monday]
shortValues["timeTemplate"] = ["schoolId": "qa", "schoolName": "QA", "schoolNameEn": "QA", "periods": [["startTime": "08:00", "endTime": "08:02"]]]
let boundaries = decode(shortValues).transitionDates(after: date("2026-10-19T07:59:00+08:00"), calendar: calendar)
check(boundaries.contains(date("2026-10-19T08:00:00+08:00")), "short course start is scheduled")
check(boundaries.contains(date("2026-10-19T08:02:00+08:00")), "end within five minutes is never discarded")
check(boundaries.contains(date("2026-10-20T00:00:00+08:00")), "timeline retains midnight transition")
print("\(checks) widget calendar checks passed")
