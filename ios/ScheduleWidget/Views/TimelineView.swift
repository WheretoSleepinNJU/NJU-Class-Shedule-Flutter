import SwiftUI

/// 时间轴视图（大组件）
struct TimelineView: View {
    let courses: [WidgetCourse]
    let currentCourse: WidgetCourse?
    let timeTemplate: SchoolTimeTemplate?
    let currentWeek: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(getCurrentDateString())
                        .font(.system(size: 16, weight: .semibold))
                    Text("第\(currentWeek)周")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // 移除ScrollView，使用固定布局（最多显示5门课）
            VStack(spacing: 8) {
                ForEach(Array(courses.prefix(5)), id: \.id) { course in
                    TimelineCourseCard(
                        course: course,
                        timeTemplate: timeTemplate,
                        isCurrent: currentCourse?.id == course.id
                    )
                }
            }
            .padding(12)

            Spacer(minLength: 0)
        }
    }

    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
}

/// 时间轴课程卡片
struct TimelineCourseCard: View {
    let course: WidgetCourse
    let timeTemplate: SchoolTimeTemplate?
    let isCurrent: Bool

    var body: some View {
        Link(destination: URL(string: "njuschedule://course/\(course.id)")!) {
            HStack(spacing: 12) {
                // Time column
                VStack(spacing: 4) {
                    if let period = getTimePeriod() {
                        Text(period.startTime)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(period.endTime)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text("第\(course.startPeriod)节")
                            .font(.system(size: 12))
                    }
                }
                .frame(width: 50)

                // Course card
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(course.name)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)

                        if isCurrent {
                            Capsule()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        }

                        Spacer()
                    }

                    if let teacher = course.teacher {
                        Label(teacher, systemImage: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    if let classroom = course.classroom {
                        Label(classroom, systemImage: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(getCourseColor().opacity(isCurrent ? 0.2 : 0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(getCourseColor(), lineWidth: isCurrent ? 2 : 1)
                )
            }
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
}
