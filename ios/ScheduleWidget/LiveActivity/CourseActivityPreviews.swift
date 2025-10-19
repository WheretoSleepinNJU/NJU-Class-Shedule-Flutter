import SwiftUI
import WidgetKit

// MARK: - Live Activity Previews
// 使用方法：在 Xcode 中打开此文件，右侧会显示预览画布（Canvas）
// 可以看到所有 Live Activity 的不同状态和布局

#if DEBUG
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
#endif
