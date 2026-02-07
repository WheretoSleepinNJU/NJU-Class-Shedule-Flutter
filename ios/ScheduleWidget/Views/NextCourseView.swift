import SwiftUI
import WidgetKit

/// 下节课视图（小组件）
struct NextCourseView: View {
    let course: WidgetCourse
    let timeTemplate: SchoolTimeTemplate?
    let isCurrent: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with course color
                if let colorHex = course.color {
                    Color(hex: colorHex)
                        .opacity(0.15)
                } else {
                    Color.blue.opacity(0.15)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Status badge
                    HStack {
                        Image(systemName: isCurrent ? "play.circle.fill" : "clock.fill")
                            .font(.system(size: 12))
                        Text(isCurrent ? "正在上课" : "下节课")
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(isCurrent ? .green : .orange)

                    Spacer()

                    // Course name
                    Text(course.name)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    // Time and location
                    if let period = getTimePeriod() {
                        Label(period.startTime, systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    if let classroom = course.classroom {
                        Label(classroom, systemImage: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .widgetURL(URL(string: "njuschedule://course/\(course.id)"))
    }

    private func getTimePeriod() -> ClassPeriod? {
        return timeTemplate?.getPeriodRange(
            startPeriod: course.startPeriod,
            periodCount: course.periodCount
        )
    }
}

