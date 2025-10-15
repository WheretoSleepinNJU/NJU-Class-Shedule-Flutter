import SwiftUI

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

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
