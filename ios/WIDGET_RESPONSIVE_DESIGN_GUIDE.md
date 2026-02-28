# Widget Responsive Design Best Practices

> Modern approaches for adaptive widget layouts in SwiftUI (iOS 16+)

---

## Table of Contents

1. [Padding & Safe Areas in Widgets](#padding--safe-areas-in-widgets)
2. [Adaptive Layout Patterns](#adaptive-layout-patterns)
3. [Xcode Preview Best Practices](#xcode-preview-best-practices)
4. [Modern SwiftUI Techniques](#modern-swiftui-techniques)
5. [Practical Examples](#practical-examples)

---

## Padding & Safe Areas in Widgets

### containerBackground & Content Margins (iOS 17+)

**Important Change:** Widgets no longer use traditional safe areas. Instead, they use **content margins**.

#### Key Differences:

```swift
// ❌ OLD WAY (iOS 14-16): Manual padding
var body: some View {
    VStack {
        // Content
    }
    .padding(16)  // Manual padding everywhere
    .background(Color.clear)
}

// ✅ NEW WAY (iOS 17+): containerBackground handles margins automatically
var body: some View {
    VStack {
        // Content - no manual padding needed!
    }
    .containerBackground(for: .widget) {
        Color.clear
    }
}
```

#### How containerBackground Works:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Course Name")
        Text("Classroom")
    }
    // System automatically applies appropriate content margins
    .containerBackground(for: .widget) {
        // Background extends edge-to-edge
        backgroundView
    }
}
```

**What Happens:**
- Background extends to widget edges
- Content is automatically inset with system margins (~16pt)
- No need for manual `.padding()` in most cases
- Consistent with system widgets

---

### Accessing System Content Margins

If you need to know the current margins:

```swift
struct MyWidgetView: View {
    @Environment(\.widgetContentMargins) var margins

    var body: some View {
        Text("Margins: \(margins.leading), \(margins.trailing)")
    }
}
```

---

### Disabling Content Margins (Edge-to-Edge)

For full-bleed graphics or backgrounds:

```swift
// In your widget configuration
struct ScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()  // ✅ Removes default margins
    }
}
```

Then selectively add padding where needed:

```swift
var body: some View {
    VStack {
        // This will touch edges
        Image("backgroundImage")
            .resizable()

        VStack {
            // This has custom padding
            Text("Content")
        }
        .padding(20)  // Custom padding for content
    }
    .containerBackground(for: .widget) {
        Color.clear
    }
}
```

---

### Best Practice: Let System Handle Margins

```swift
// ✅ RECOMMENDED: Trust containerBackground
var body: some View {
    VStack(alignment: .leading, spacing: 8) {
        DateHeaderView()
        CourseListView()
    }
    .containerBackground(for: .widget) {
        backgroundForCurrentMode
    }
}

// ⚠️ ONLY add manual padding for specific spacing needs
var body: some View {
    VStack(spacing: 0) {
        HeaderView()
            .padding(.bottom, 12)  // Extra spacing between sections

        ContentView()
    }
    .containerBackground(for: .widget) {
        Color.clear
    }
}
```

---

## Adaptive Layout Patterns

### Pattern 1: Environment-Based Switch (Traditional)

**Use When:** You need completely different layouts for each size

```swift
struct ScheduleWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ScheduleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}
```

**Pros:**
- ✅ Complete control over each size
- ✅ Easy to understand and maintain
- ✅ No layout calculations needed

**Cons:**
- ❌ Code duplication across views
- ❌ Need separate view files

---

### Pattern 2: ViewThatFits (iOS 16+) - Modern Approach

**Use When:** You want automatic layout adaptation based on available space

```swift
struct AdaptiveCourseCard: View {
    let course: WidgetCourse

    var body: some View {
        ViewThatFits {
            // Try detailed view first
            DetailedCourseView(course: course)

            // Fall back to compact if doesn't fit
            CompactCourseView(course: course)

            // Last resort: minimal view
            MinimalCourseView(course: course)
        }
    }
}

private struct DetailedCourseView: View {
    let course: WidgetCourse

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.name)
                .font(.headline)
            Text(course.classroom ?? "")
                .font(.subheadline)
            Text(course.teacher ?? "")
                .font(.caption)
            Text(timeRange)
                .font(.caption)
        }
    }
}

private struct CompactCourseView: View {
    let course: WidgetCourse

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(course.name)
                .font(.headline)
            Text(course.classroom ?? "")
                .font(.subheadline)
        }
    }
}
```

**How It Works:**
- ViewThatFits tries each child view in order
- Picks the first one that fits in available space
- Automatic, no manual calculations
- Great for varying content lengths

**Pros:**
- ✅ Automatic adaptation
- ✅ No size calculations
- ✅ Handles dynamic content naturally
- ✅ Works across all widget sizes

**Cons:**
- ⚠️ iOS 16+ only
- ⚠️ Less explicit control
- ⚠️ Can't mix-and-match parts of layouts

---

### Pattern 3: Conditional Modifiers

**Use When:** Same layout structure, different styling/spacing

```swift
struct CourseCardView: View {
    let course: WidgetCourse
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(course.name)
                .font(titleFont)
                .lineLimit(titleLineLimit)

            if showDetails {
                Text(course.classroom ?? "")
                    .font(.caption)
            }
        }
        .padding(cardPadding)
    }

    // Adaptive properties
    private var spacing: CGFloat {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 6
        case .systemLarge: return 8
        default: return 4
        }
    }

    private var titleFont: Font {
        family == .systemSmall ? .caption : .headline
    }

    private var titleLineLimit: Int {
        family == .systemSmall ? 2 : 3
    }

    private var showDetails: Bool {
        family != .systemSmall
    }

    private var cardPadding: CGFloat {
        family == .systemSmall ? 8 : 12
    }
}
```

**Pros:**
- ✅ Single view definition
- ✅ Shared layout logic
- ✅ Easy to maintain

**Cons:**
- ⚠️ Can become complex with many conditionals
- ⚠️ Not suitable for very different layouts

---

### Pattern 4: Adaptive Stack with ViewThatFits

**Use When:** You want HStack for larger sizes, VStack for smaller

```swift
struct CourseInfoView: View {
    let course: WidgetCourse

    var body: some View {
        ViewThatFits {
            // Try horizontal layout first (for medium/large)
            HStack(spacing: 12) {
                CourseIcon(course: course)
                CourseDetails(course: course)
                Spacer()
                TimeInfo(course: course)
            }

            // Fall back to vertical (for small)
            VStack(spacing: 8) {
                HStack {
                    CourseIcon(course: course)
                    Text(course.name)
                    Spacer()
                }
                CourseDetails(course: course)
                TimeInfo(course: course)
            }
        }
    }
}
```

**Result:**
- Medium/Large widgets: Horizontal layout
- Small widget: Vertical layout
- Automatic decision based on space

---

### Pattern 5: Data-Driven Adaptation

**Use When:** Different sizes show different amounts of data

```swift
struct CourseListView: View {
    @Environment(\.widgetFamily) var family
    let courses: [WidgetCourse]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(displayedCourses, id: \.id) { course in
                CourseRow(course: course)
            }
        }
    }

    private var displayedCourses: [WidgetCourse] {
        let limit: Int
        switch family {
        case .systemSmall: limit = 2
        case .systemMedium: limit = 4
        case .systemLarge: limit = 8
        default: limit = 2
        }
        return Array(courses.prefix(limit))
    }
}
```

---

## Xcode Preview Best Practices

### Modern #Preview Macro (Xcode 15+)

#### Pattern 1: Multiple Size Previews

```swift
// Small Widget Preview
#Preview("小组件", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    // Multiple timeline entries
    ScheduleEntry.beforeClass
    ScheduleEntry.approaching
    ScheduleEntry.inClass
    ScheduleEntry.classEnded
}

// Medium Widget Preview
#Preview("中组件", as: .systemMedium) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry.sampleWithMultipleCourses
}

// Large Widget Preview
#Preview("大组件", as: .systemLarge) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry.sampleFullDay
}
```

**Features:**
- ✅ Live preview of all sizes
- ✅ Interactive timeline scrubbing
- ✅ Animation preview between states
- ✅ No need to run on device

---

#### Pattern 2: State-Based Previews

```swift
// Preview specific states
#Preview("即将上课", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: Date(),
        currentCourse: nil,
        nextCourse: sampleCourse,
        minutesUntil: 10  // 10 minutes until class
    )
}

#Preview("上课中", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: Date(),
        currentCourse: sampleCourse,
        nextCourse: sampleCourse2,
        minutesUntil: nil
    )
}

#Preview("今日无课", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: Date(),
        currentCourse: nil,
        nextCourse: nil,
        todayCourses: []
    )
}
```

**Benefits:**
- ✅ Test all edge cases visually
- ✅ No need to mock real data
- ✅ Fast iteration

---

#### Pattern 3: Preview with Timeline Provider

```swift
#Preview("使用 Timeline Provider", as: .systemMedium) {
    ScheduleWidget()
} timelineProvider: {
    Provider()  // Uses your actual timeline provider
}
```

**When to Use:**
- Testing actual timeline generation logic
- Verifying timeline policies
- Debugging refresh behavior

---

### Preview Data Organization

Create a dedicated file for preview data:

```swift
// PreviewData.swift
extension ScheduleEntry {
    static var sampleBeforeClass: ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            widgetData: .sample,
            nextCourse: .sample1,
            currentCourse: nil,
            todayCourses: [.sample1, .sample2],
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 20)
        )
    }

    static var sampleApproaching: ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            widgetData: .sample,
            nextCourse: .sample1,
            currentCourse: nil,
            todayCourses: [.sample1, .sample2],
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 80)
        )
    }

    static var sampleInClass: ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            widgetData: .sample,
            nextCourse: .sample2,
            currentCourse: .sample1,
            todayCourses: [.sample1, .sample2],
            errorMessage: nil,
            relevance: TimelineEntryRelevance(score: 100)
        )
    }

    static var sampleError: ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            widgetData: nil,
            nextCourse: nil,
            currentCourse: nil,
            todayCourses: [],
            errorMessage: "打开应用更新数据",
            relevance: nil
        )
    }
}

extension WidgetCourse {
    static var sample1: WidgetCourse {
        WidgetCourse(
            id: "sample1",
            name: "计算机网络",
            classroom: "仙II-220",
            teacher: "张三",
            startPeriod: 3,
            periodCount: 2,
            weekday: 3,
            color: "#4A90E2"
        )
    }

    static var sample2: WidgetCourse {
        WidgetCourse(
            id: "sample2",
            name: "数据结构与算法",
            classroom: "教一-207",
            teacher: "李四",
            startPeriod: 6,
            periodCount: 2,
            weekday: 3,
            color: "#E24A4A"
        )
    }

    static var sampleLongName: WidgetCourse {
        WidgetCourse(
            id: "sample3",
            name: "马克思主义基本原理概论与中国特色社会主义理论体系",
            classroom: "仙II-301",
            teacher: "王五",
            startPeriod: 1,
            periodCount: 3,
            weekday: 1,
            color: "#50C878"
        )
    }
}
```

---

### Interactive Preview Controls

```swift
#Preview("交互式预览", as: .systemMedium) {
    ScheduleWidget()
} timeline: {
    let now = Date()

    // Entry 1: Before class
    ScheduleEntry.beforeClass

    // Entry 2: 5 seconds later - approaching
    ScheduleEntry(
        date: now.addingTimeInterval(5),
        currentCourse: nil,
        nextCourse: .sample1
        // ...
    )

    // Entry 3: 10 seconds later - in class
    ScheduleEntry(
        date: now.addingTimeInterval(10),
        currentCourse: .sample1,
        nextCourse: .sample2
        // ...
    )
}
```

**In Canvas:**
- Click timeline entries to jump to that state
- Click Play button to watch transitions
- See animations between states
- Verify layout at each point

---

## Modern SwiftUI Techniques

### 1. ViewThatFits for Text Overflow

```swift
struct AdaptiveText: View {
    let text: String

    var body: some View {
        ViewThatFits {
            // Try full text first
            Text(text)
                .lineLimit(1)

            // Fall back to truncated
            Text(text)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.caption)

            // Last resort: abbreviate
            Text(abbreviate(text))
                .font(.caption2)
        }
    }

    func abbreviate(_ text: String) -> String {
        String(text.prefix(10)) + "..."
    }
}
```

---

### 2. Adaptive Spacing with Environment

```swift
struct CourseList: View {
    @Environment(\.widgetFamily) var family
    let courses: [WidgetCourse]

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(courses, id: \.id) { course in
                CourseRow(course: course)
            }
        }
    }

    private var spacing: CGFloat {
        switch family {
        case .systemSmall: return 6
        case .systemMedium: return 8
        case .systemLarge: return 10
        @unknown default: return 6
        }
    }
}
```

---

### 3. Conditional View Modifiers Extension

```swift
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Usage
Text(course.name)
    .if(family == .systemSmall) { view in
        view.font(.caption)
    }
    .if(family != .systemSmall) { view in
        view.font(.headline)
    }
```

---

## Practical Examples

### Example 1: Fully Adaptive Course Card

```swift
struct AdaptiveCourseCard: View {
    let course: WidgetCourse
    @Environment(\.widgetFamily) var family

    var body: some View {
        ViewThatFits {
            // Detailed version (try first)
            detailedLayout

            // Compact version (fallback)
            compactLayout
        }
        .padding(cardPadding)
        .background(backgroundColor)
        .cornerRadius(8)
    }

    private var detailedLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                colorIndicator
                Text(course.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
            }

            HStack(spacing: 8) {
                Label(course.classroom ?? "", systemImage: "mappin")
                    .font(.caption)
                Label(course.teacher ?? "", systemImage: "person")
                    .font(.caption)
            }

            Text(timeRange)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 8) {
            colorIndicator
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.caption)
                    .lineLimit(1)
                Text(course.classroom ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var colorIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(hex: course.color ?? "#4A90E2"))
            .frame(width: 4, height: indicatorHeight)
    }

    private var cardPadding: CGFloat {
        family == .systemSmall ? 8 : 12
    }

    private var indicatorHeight: CGFloat {
        family == .systemSmall ? 24 : 32
    }

    private var backgroundColor: Color {
        Color(hex: course.color ?? "#4A90E2")
            .opacity(0.12)
    }

    private var timeRange: String {
        // Calculate from course.startPeriod and periodCount
        "08:00 - 09:50"
    }
}
```

---

### Example 2: Responsive List with Preview

```swift
struct CourseListView: View {
    @Environment(\.widgetFamily) var family
    let courses: [WidgetCourse]

    var body: some View {
        VStack(spacing: itemSpacing) {
            ForEach(displayedCourses, id: \.id) { course in
                ViewThatFits {
                    // Try horizontal layout
                    HStack {
                        CourseIcon(course: course)
                        CourseDetails(course: course)
                        Spacer()
                        TimeLabel(course: course)
                    }

                    // Fallback to vertical
                    VStack(alignment: .leading) {
                        HStack {
                            CourseIcon(course: course)
                            Text(course.name)
                                .font(.caption)
                        }
                        TimeLabel(course: course)
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var displayedCourses: [WidgetCourse] {
        Array(courses.prefix(maxCourses))
    }

    private var maxCourses: Int {
        switch family {
        case .systemSmall: return 2
        case .systemMedium: return 4
        case .systemLarge: return 8
        @unknown default: return 2
        }
    }

    private var itemSpacing: CGFloat {
        family == .systemSmall ? 4 : 8
    }
}

// Previews
#Preview("小 - 2门课", as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: Date(),
        todayCourses: [.sample1, .sample2]
    )
}

#Preview("中 - 4门课", as: .systemMedium) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: Date(),
        todayCourses: [.sample1, .sample2, .sample1, .sample2]
    )
}

#Preview("大 - 8门课", as: .systemLarge) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: Date(),
        todayCourses: Array(repeating: [.sample1, .sample2], count: 4).flatMap { $0 }
    )
}
```

---

## Summary: Best Practices

### ✅ DO

1. **Use `containerBackground` for widget backgrounds** - Handles margins automatically
2. **Use ViewThatFits for adaptive content** - Automatic, no calculations
3. **Create multiple #Preview variants** - Test all sizes and states
4. **Extract preview data to dedicated file** - Reusable sample data
5. **Use environment values for adaptation** - `@Environment(\.widgetFamily)`
6. **Trust system margins** - Don't fight with manual padding
7. **Test on actual devices** - Canvas doesn't show all rendering issues

### ❌ DON'T

1. **Don't add manual padding everywhere** - Let containerBackground handle it
2. **Don't use GeometryReader unnecessarily** - Prefer ViewThatFits
3. **Don't ignore edge cases in previews** - Test long names, no data, errors
4. **Don't duplicate layout code** - Share components across sizes when possible
5. **Don't use .ignoresSafeArea in widgets** - Doesn't work, use contentMarginsDisabled
6. **Don't hard-code dimensions** - Use relative spacing and adaptive fonts

---

## Quick Reference

| Technique | iOS Version | Use Case | Complexity |
|-----------|-------------|----------|------------|
| `@Environment(\.widgetFamily)` | 14+ | Different layouts per size | Simple |
| `ViewThatFits` | 16+ | Automatic space-based adaptation | Simple |
| `containerBackground` | 17+ | Widget backgrounds with auto margins | Simple |
| Conditional modifiers | 14+ | Same layout, different styling | Medium |
| `#Preview` macro | Xcode 15+ | Modern previews with timeline | Simple |
| Data-driven adaptation | 14+ | Different data amounts per size | Medium |

---

**Document Version:** 1.0
**Last Updated:** 2025-01-17
**Target:** iOS 16+ (ViewThatFits), iOS 17+ (containerBackground)
**Xcode:** 15+ (for #Preview macro)
