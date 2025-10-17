import SwiftUI
import WidgetKit

/// 统一的 Widget 预览定义
///
/// 使用方法：
/// 1. 打开此文件，Xcode 会在右侧显示预览画布（Canvas）
/// 2. 点击画布底部的 "Variants" 按钮
/// 3. 选择 "Widget Context Variants" 查看所有尺寸的网格视图
/// 4. 或者点击预览右下角的尺寸按钮切换 Small/Medium/Large
///
/// 这样每个场景只需定义一次，即可预览所有 Widget 尺寸
/// 展示响应式设计效果：相同数据，不同尺寸自适应布局

// MARK: - Widget Previews

#Preview("1. Before First Class", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.beforeFirstClass()
}

#Preview("2. Approaching Class", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.approachingClass()
}

#Preview("3. In Class", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.inClass()
}

#Preview("4. Classes Ended", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.classesEnded()
}

#Preview("5. Tomorrow Preview", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.tomorrowPreview()
}

#Preview("6. No Data", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.noData()
}

#Preview("7. No Courses", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.noCourses()
}
