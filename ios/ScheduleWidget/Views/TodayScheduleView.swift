import SwiftUI

/// 今日课程表视图（中等组件）
struct TodayScheduleView: View {
    let courses: [WidgetCourse]
    let currentCourse: WidgetCourse?
    let timeTemplate: SchoolTimeTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                Text("今日课程")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(courses.count)节课")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Course list
            VStack(spacing: 0) {
                ForEach(courses, id: \.id) { course in
                    CourseRow(
                        course: course,
                        timeTemplate: timeTemplate,
                        isCurrent: currentCourse?.id == course.id
                    )
                    if course.id != courses.last?.id {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .padding(.vertical, 8)

            Spacer(minLength: 0)
        }
        .background(Color(UIColor.systemBackground))
    }
}

/// 单个课程行
struct CourseRow: View {
    let course: WidgetCourse
    let timeTemplate: SchoolTimeTemplate?
    let isCurrent: Bool

    var body: some View {
        Link(destination: URL(string: "njuschedule://course/\(course.id)")!) {
            HStack(spacing: 12) {
                // Time indicator
                VStack(alignment: .center, spacing: 2) {
                    if let period = getTimePeriod() {
                        Text(formatTime(period.startTime))
                            .font(.system(size: 13, weight: .semibold))
                        Text(formatTime(period.endTime))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else {
                        Text("第\(course.startPeriod)节")
                            .font(.system(size: 11))
                    }
                }
                .frame(width: 36)

                // Course color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(getCourseColor())
                    .frame(width: 4)

                // Course info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(course.name)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)

                        if isCurrent {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                    }

                    if let classroom = course.classroom {
                        Text(classroom)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isCurrent ? Color.green.opacity(0.05) : Color.clear)
        }
    }

    private func getTimePeriod() -> ClassPeriod? {
        return timeTemplate?.getPeriodRange(
            startPeriod: course.startPeriod,
            periodCount: course.periodCount
        )
    }

    private func getCourseColor() -> Color {
        if let colorHex = course.color {
            return Color(hex: colorHex)
        }
        return .blue
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
