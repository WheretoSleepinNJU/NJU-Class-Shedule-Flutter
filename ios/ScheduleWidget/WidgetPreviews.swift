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

#Preview("3. Between Classes", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.betweenClasses()
}

#Preview("4. In Class", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.inClass()
}

#Preview("5. Classes Ended", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.classesEnded()
}

#Preview("6. Tomorrow Preview", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.tomorrowPreview()
}

#Preview("7. No Data", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.noData()
}

#Preview("8. No Courses", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    WidgetPreviewData.noCourses()
}

// MARK: - Live Activity Previews
// 使用方法：在 Xcode 中打开此文件，右侧会显示预览画布（Canvas）
// 可以看到所有 Live Activity 的不同状态和布局

@available(iOS 16.1, *)
#Preview("15分钟前", as: .content, using: WidgetPreviewData.liveActivity15MinBefore().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivity15MinBefore().1
}

@available(iOS 16.1, *)
#Preview("5分钟前", as: .content, using: WidgetPreviewData.liveActivity5MinBefore().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivity5MinBefore().1
}

@available(iOS 16.1, *)
#Preview("1分钟前", as: .content, using: WidgetPreviewData.liveActivity1MinBefore().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivity1MinBefore().1
}

@available(iOS 16.1, *)
#Preview("30秒前", as: .content, using: WidgetPreviewData.liveActivity30SecBefore().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivity30SecBefore().1
}

@available(iOS 16.1, *)
#Preview("长课程名", as: .content, using: WidgetPreviewData.liveActivityLongName().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivityLongName().1
}

// MARK: - Dynamic Island Previews

@available(iOS 16.1, *)
#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: WidgetPreviewData.liveActivity15MinBefore().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivity15MinBefore().1
}

@available(iOS 16.1, *)
#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: WidgetPreviewData.liveActivity5MinBefore().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivity5MinBefore().1
}

@available(iOS 16.1, *)
#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: WidgetPreviewData.liveActivity1MinBefore().0) {
    CourseActivityWidget()
} contentStates: {
    WidgetPreviewData.liveActivity1MinBefore().1
}
