# iOS Widget Best Practices Implementation Guide

> **Based on Official Apple Documentation & WWDC Sessions**
> References: WWDC20 Session 10103, WWDC21 Session 10048, WidgetKit & RelevanceKit Documentation

---

## Table of Contents

1. [Timeline & Refresh Strategy](#timeline--refresh-strategy)
2. [Layout & Spacing Guidelines](#layout--spacing-guidelines)
3. [Relevance & Smart Stack Optimization](#relevance--smart-stack-optimization)
4. [App Groups & Data Sharing](#app-groups--data-sharing)
5. [View Composition & Architecture](#view-composition--architecture)
6. [Performance Optimization](#performance-optimization)
7. [Implementation Checklist](#implementation-checklist)

---

## Timeline & Refresh Strategy

### Official Guidelines (Apple WWDC21)

#### Widget Refresh Budget
- **Production Environment**: 40-70 refreshes per day for frequently viewed widgets
- **Translates to**: ~15-60 minute intervals
- **Development**: No refresh limit when running from Xcode debugger
- **Minimum Interval**: 5 minutes between `getTimeline()` calls

#### Reload Policies

Apple provides three Timeline reload policies:

```swift
// 1. .atEnd - Continuous content (Calendar, Reminders, Photos)
Timeline(entries: entries, policy: .atEnd)
// Best for: Endless content that always has next state
// System requests new timeline immediately after last entry

// 2. .after(Date) - Unpredictable content (Weather, Stocks, News)
Timeline(entries: entries, policy: .after(nextRefreshDate))
// Best for: Content that needs specific timing
// Widget won't refresh until specified date

// 3. .never - Event-driven (Music, Notes, TV)
Timeline(entries: entries, policy: .never)
// Best for: Content that only changes via app interaction
// Requires explicit WidgetCenter.shared.reloadTimelines(ofKind:) call
```

#### Timeline Entry Best Practices

**1. Populate Timelines Generously**
```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [ScheduleEntry] = []

    // ✅ GOOD: Provide multiple future entries
    for i in 0..<10 {
        let futureDate = Calendar.current.date(byAdding: .hour, value: i, to: Date())!
        let entry = ScheduleEntry(date: futureDate, ...)
        entries.append(entry)
    }

    // ❌ BAD: Single entry forces frequent reloads
    // let entry = ScheduleEntry(date: Date(), ...)
    // entries = [entry]

    completion(Timeline(entries: entries, policy: .after(futureDate)))
}
```

**2. Keep Intervals as Large as Possible**
- Entries should be **at least 5 minutes apart**
- Prefer 15-30 minute intervals when possible
- Use event-driven updates (class start times) rather than arbitrary intervals

**3. Use SwiftUI's Built-in Time Updates**
```swift
// ✅ GOOD: System handles updates automatically
Text(courseEndTime, style: .timer)
Text(courseStartTime, style: .relative)

// ❌ BAD: Manual countdown requires frequent timeline entries
Text("还剩 \(minutesRemaining) 分钟")
```

### Our Implementation Strategy

For the course schedule widget, we should:

```swift
// IMPROVED: Generate timeline entries for each state transition
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let entry = loadEntry()
    var entries: [ScheduleEntry] = [entry]

    // Add entries for upcoming state transitions
    let transitionDates = calculateStateTransitions(entry: entry)

    for transitionDate in transitionDates {
        let futureEntry = loadEntry() // Would calculate state at that time
        entries.append(futureEntry)
    }

    // Calculate next refresh based on next significant event
    let nextRefresh = transitionDates.first ??
                      Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

    let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
    completion(timeline)
}

// Generate state transition times:
// - Course start times
// - 15 minutes before class (approaching state)
// - Course end times
// - 21:00 (tomorrow preview)
private func calculateStateTransitions(entry: ScheduleEntry) -> [Date] {
    var transitions: [Date] = []

    // Add 15 min before next class
    if let nextCourse = entry.nextCourse,
       let template = entry.widgetData?.timeTemplate,
       let period = template.getPeriodRange(...) {
        if let startTime = parseTime(period.startTime),
           let approachingTime = Calendar.current.date(
               byAdding: .minute,
               value: -15,
               to: startTime
           ) {
            transitions.append(approachingTime)
            transitions.append(startTime) // Course start
        }
    }

    // Add course end time
    if let currentCourse = entry.currentCourse,
       let template = entry.widgetData?.timeTemplate,
       let period = template.getPeriodRange(...) {
        if let endTime = parseTime(period.endTime) {
            transitions.append(endTime)
        }
    }

    // Add 21:00 for tomorrow preview
    let calendar = Calendar.current
    if let tomorrowPreviewTime = calendar.date(
        bySettingHour: 21,
        minute: 0,
        second: 0,
        of: Date()
    ) {
        transitions.append(tomorrowPreviewTime)
    }

    return transitions.filter { $0 > Date() }.sorted()
}
```

### Manual Refresh Triggers

**Budget Exemptions** (don't count against daily limit):
- App in foreground
- Active audio/navigation session
- Widget performs an App Intent

**When to Call WidgetCenter.reloadTimelines()**:
```swift
// ✅ GOOD: User-initiated data changes
func updateCourseData() {
    saveToAppGroup()
    WidgetCenter.shared.reloadTimelines(ofKind: "ScheduleWidget")
}

// ✅ GOOD: External data source updated
func didReceiveHealthKitUpdate() {
    cacheData() // Prevent placeholder when locked
    WidgetCenter.shared.reloadAllTimelines()
}

// ❌ BAD: Arbitrary frequent calls
Timer.scheduledTimer(withTimeInterval: 60) { _ in
    WidgetCenter.shared.reloadAllTimelines() // Wastes budget!
}
```

---

## Layout & Spacing Guidelines

### Official Apple Margins (WWDC20)

#### Standard Layouts
- **Default margin**: **16pt** from all edges
- Ensures consistency when placed next to other widgets
- Use for text, labels, and standard content

#### Graphical Layouts
- **Tighter margin**: **11pt** from all edges
- For layouts with circles, inset platters, or graphical shapes
- Background shapes can extend closer to edges

#### Corner Radius Alignment
- Shape corners should appear **concentric** with widget's corner radius
- Maintain visual harmony with system widgets

### SwiftUI Implementation

```swift
// ✅ RECOMMENDED: Use system padding
VStack(alignment: .leading, spacing: 8) {
    // Content
}
.padding(16) // Standard margin

// For graphical backgrounds
VStack {
    // Content with background
}
.padding(11) // Tighter margin for shapes
```

### Widget Size Dimensions

| Family | Size (pt) | Typical Use |
|--------|-----------|-------------|
| systemSmall | 155×155 | Single glanceable metric |
| systemMedium | 329×155 | Horizontal list or comparison |
| systemLarge | 329×345 | Detailed view with multiple items |

### Layout Best Practices

**1. Design Unique Layouts Per Size**
```swift
struct ScheduleWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ScheduleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry) // ✅ Dedicated view
        case .systemMedium:
            MediumWidgetView(entry: entry) // ✅ Different layout
        case .systemLarge:
            LargeWidgetView(entry: entry) // ✅ Optimized for space
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}

// ❌ BAD: Scaling small layout to larger sizes
// .scaleEffect(family == .systemLarge ? 2.0 : 1.0)
```

**2. Limit Information Density (Small Widget)**
- **Maximum**: 4 pieces of information
- Focus on most essential data
- More info = less glanceable

**3. Typography**
- Use **SF Pro** or San Francisco variants
- Leverage system font sizes for consistency
- Support Dynamic Type where appropriate

```swift
// ✅ GOOD: System font with semantic sizing
Text(courseName)
    .font(.system(size: 14, weight: .semibold))

// Even better: Use Text styles
Text(courseName)
    .font(.headline)
```

**4. Avoid Redundant Content**
- ❌ Don't include app name (shown by system)
- ❌ Don't include app icon in content area
- ❌ Don't use "Last updated" timestamps for time-based data
- ✅ Deep link directly to relevant content

---

## Relevance & Smart Stack Optimization

### TimelineEntryRelevance

**Purpose**: Helps Smart Stack prioritize which widget to rotate to top

```swift
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetScheduleData?
    let relevance: TimelineEntryRelevance? // ADD THIS

    // ... existing properties
}
```

### Relevance Score Strategy

**Official Guidance** (WWDC21):
- Pick a schema and **keep it consistent** across all updates
- Scores are **relative** to past and future timeline entries
- Zero (0) = don't rotate to this widget
- Positive values = eligible for Smart Rotate

**Example: Flight Tracking Widget**
- Before flight: score = 0
- As flight approaches: score = 100
- After departure: score = 0

**Our Course Schedule Implementation**:

```swift
// Calculate relevance based on time until class
private func calculateRelevance(for entry: ScheduleEntry) -> TimelineEntryRelevance? {
    let now = Date()

    // If currently in class: High relevance
    if entry.currentCourse != nil {
        return TimelineEntryRelevance(score: 100, duration: 60) // Very important
    }

    // If approaching class (within 15 min): Very high relevance
    if let nextCourse = entry.nextCourse,
       let template = entry.widgetData?.timeTemplate,
       let period = template.getPeriodRange(...),
       let startTime = parseTime(period.startTime) {

        let minutesUntil = Calendar.current.dateComponents(
            [.minute],
            from: now,
            to: startTime
        ).minute ?? 999

        if minutesUntil <= 15 && minutesUntil > 0 {
            // Score increases as class approaches
            let score = Float(100 - (minutesUntil * 5)) // 100 at 0min, 25 at 15min
            return TimelineEntryRelevance(score: score)
        }

        // Next class exists but not imminent
        if minutesUntil > 15 && minutesUntil <= 120 {
            let score = Float(20) // Moderate relevance
            return TimelineEntryRelevance(score: score)
        }
    }

    // Today has courses but not soon
    if !entry.todayCourses.isEmpty {
        return TimelineEntryRelevance(score: 10) // Low relevance
    }

    // No classes or ended
    return TimelineEntryRelevance(score: 0) // Don't rotate
}
```

**Usage**:
```swift
return ScheduleEntry(
    date: Date(),
    widgetData: data,
    nextCourse: data.nextCourse,
    currentCourse: data.currentCourse,
    todayCourses: data.todayCourses,
    errorMessage: nil,
    relevance: calculateRelevance(for: entry) // ✅ ADD THIS
)
```

### Refresh Strategy for Smart Stack

**Avoid Near-Immediate Reloads**:
```swift
// ❌ BAD: All devices reload at same time
let nextRefresh = Calendar.current.date(
    bySettingHour: 14,
    minute: 0,
    second: 0,
    of: Date()
)!

// ✅ GOOD: Add random jitter to distribute load
let jitter = Int.random(in: 0..<300) // 0-5 min random
let nextRefresh = Calendar.current.date(
    byAdding: .second,
    value: jitter,
    to: baseRefreshTime
)!
```

---

## App Groups & Data Sharing

### Setup Requirements

**1. Enable App Groups for BOTH Targets**
- Main app target
- Widget extension target
- Use **same App Group ID**: `group.top.idealclover.wheretosleepinnju`

**2. Use Suite Name Consistently**

```swift
// ✅ GOOD: Shared constant
let appGroupId = "group.top.idealclover.wheretosleepinnju"

// Main App
if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
    sharedDefaults.set(data, forKey: "widget_data")
}

// Widget Extension
if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
    if let data = sharedDefaults.data(forKey: "widget_data") {
        // Use data
    }
}
```

**3. Replace UserDefaults.standard Entirely**

```swift
// ❌ BAD: Using standard defaults
UserDefaults.standard.set(value, forKey: "key")

// ✅ GOOD: Always use shared suite
class AppGroupDefaults {
    static let shared = UserDefaults(
        suiteName: "group.top.idealclover.wheretosleepinnju"
    )!
}

AppGroupDefaults.shared.set(value, forKey: "key")
```

### Data Sharing Best Practices

**1. Use Codable for Complex Data**

```swift
struct WidgetScheduleData: Codable {
    let schoolName: String
    let currentWeek: Int
    let todayCourses: [WidgetCourse]
    // ...
}

// Encoding
let encoder = JSONEncoder()
if let encoded = try? encoder.encode(widgetData) {
    sharedDefaults.set(encoded, forKey: "widget_data")
}

// Decoding
let decoder = JSONDecoder()
if let data = sharedDefaults.data(forKey: "widget_data"),
   let decoded = try? decoder.decode(WidgetScheduleData.self, from: data) {
    // Use decoded data
}
```

**2. Create Shared Manager**

```swift
// ✅ GOOD: Single source of truth
class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let appGroupId = "group.top.idealclover.wheretosleepinnju"

    func saveWidgetData(_ data: WidgetScheduleData) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            defaults.set(encoded, forKey: "widget_data")

            // Trigger widget reload
            WidgetCenter.shared.reloadTimelines(ofKind: "ScheduleWidget")
        }
    }

    func loadWidgetData() -> WidgetScheduleData? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: "widget_data") else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(WidgetScheduleData.self, from: data)
    }
}
```

**3. Handle TestFlight/Production Issues**

Common problem: Data disappears in TestFlight
- **Cause**: Entitlement issue - App Group not in provisioning profile
- **Fix**: Verify App Group is enabled in both Debug AND Release configurations
- **Verify**: Check Signing & Capabilities tab for both targets

---

## View Composition & Architecture

### SwiftUI Best Practices

**1. Break Down Large Views**
```swift
// ❌ BAD: Monolithic view
struct SmallWidgetView: View {
    var body: some View {
        VStack {
            // 200 lines of code...
        }
    }
}

// ✅ GOOD: Decomposed components
struct SmallWidgetView: View {
    var body: some View {
        VStack {
            DateHeaderView(date: date, week: week)
            ContentAreaView(entry: entry)
        }
    }
}

private struct DateHeaderView: View { /* ... */ }
private struct ContentAreaView: View { /* ... */ }
```

**2. Create Reusable Components**

```swift
// ✅ Reusable course card used in multiple sizes
struct CourseCardView: View {
    let course: WidgetCourse
    let style: CardStyle

    enum CardStyle {
        case detailed  // Shows all info
        case compact   // Minimal info
    }
}

// Used in both Small and Medium widgets
SmallWidgetView: CourseCardView(course: current, style: .detailed)
MediumWidgetView: CourseCardView(course: remaining[0], style: .compact)
```

**3. Use Environment for Adaptation**

```swift
struct AdaptiveWidgetView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        content
            .containerBackground(for: .widget) {
                // Adapt background to rendering mode
                backgroundForCurrentMode
            }
    }

    private var backgroundForCurrentMode: Color {
        if renderingMode == .fullColor && colorScheme == .dark {
            return Color.black // StandBy mode
        }
        return Color.clear // Default
    }
}
```

### Architecture Patterns

For widgets, **simple is better**:
- ✅ Use straightforward Model-View pattern
- ✅ Keep logic in TimelineProvider
- ✅ Views should be mostly declarative
- ❌ Don't over-engineer with complex MVVM/Redux for widgets

```swift
// ✅ GOOD: Simple, clear separation
// TimelineProvider = Data logic
// WidgetViews = Presentation
// Shared Models = Data structures

struct Provider: TimelineProvider {
    func getTimeline(...) {
        // Business logic here
        let entry = calculateCurrentState()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct WidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        // Pure presentation
    }
}
```

---

## Performance Optimization

### Timeline Provider Optimization

**1. Use Snapshot for Quick Display**
```swift
func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
    if context.isPreview {
        // ✅ GOOD: Use sample data for preview
        completion(sampleEntry)
    } else {
        // Load real data
        completion(loadEntry())
    }
}
```

**2. Cache Data When Locked**

Problem: Some data sources (HealthKit) unavailable when device locked
Solution: Cache last known good data

```swift
func loadEntry() -> ScheduleEntry {
    let widgetData = WidgetDataManager.shared.loadWidgetData()

    if let data = widgetData {
        // ✅ Cache for next time
        WidgetDataManager.shared.cacheLastKnown(data)
        return createEntry(from: data)
    } else {
        // ✅ Fallback to cache if available
        if let cached = WidgetDataManager.shared.loadCachedData() {
            return createEntry(from: cached)
        }
        return placeholderEntry()
    }
}
```

**3. Minimize Timeline Provider Work**

```swift
func getTimeline(...) {
    // ❌ BAD: Heavy computation
    let allCourses = fetchAllCoursesFromDatabase() // 1000s of records
    let processed = processComplexAlgorithm(allCourses)

    // ✅ GOOD: Pre-computed in main app
    let todayData = WidgetDataManager.shared.loadWidgetData() // Already filtered
}
```

### View Performance

**1. Avoid Expensive Rendering**
```swift
// ❌ BAD: Complex calculations in body
var body: some View {
    Text(calculateComplexMetric()) // Called on every render
}

// ✅ GOOD: Pre-compute in Timeline
let entry = ScheduleEntry(
    date: Date(),
    displayMetric: calculateComplexMetric() // Computed once
)

var body: some View {
    Text(entry.displayMetric)
}
```

**2. Use Placeholder Wisely**
```swift
func placeholder(in context: Context) -> ScheduleEntry {
    return ScheduleEntry(
        date: Date(),
        widgetData: nil, // Simple, no data loading
        nextCourse: nil,
        currentCourse: nil,
        todayCourses: [],
        errorMessage: nil
    )
}
```

---

## Implementation Checklist

### Timeline & Refresh
- [ ] Generate multiple timeline entries (not just one)
- [ ] Use `.after(Date)` with calculated next significant event
- [ ] Entries are at least 5 minutes apart
- [ ] Avoid near-immediate reload times (add jitter)
- [ ] Use Text(.timer) for automatic countdown

### Relevance & Smart Stack
- [ ] Add `relevance` property to TimelineEntry
- [ ] Calculate relevance scores based on course timing
- [ ] High score (100) during class or within 15 min
- [ ] Low/zero score when no relevant courses
- [ ] Consistent scoring schema across all entries

### Layout & Design
- [ ] Use 16pt margins for standard layouts
- [ ] Use 11pt margins for graphical backgrounds
- [ ] Unique layout per widget family (Small/Medium/Large)
- [ ] Limit Small widget to 4 pieces of information
- [ ] Corner radius aligned concentrically
- [ ] No app name/icon in content area
- [ ] Support Dark Mode with containerBackground

### App Groups & Data
- [ ] App Groups enabled for both targets
- [ ] Same App Group ID in both
- [ ] UserDefaults(suiteName:) used consistently
- [ ] Codable for complex data structures
- [ ] Shared WidgetDataManager class
- [ ] Reload widgets after data save

### View Architecture
- [ ] Decompose large views into smaller components
- [ ] Create reusable components (e.g., CourseCardView)
- [ ] Use @Environment for adaptation
- [ ] Simple Model-View pattern (no over-engineering)
- [ ] Views are primarily declarative

### Performance
- [ ] Use sample data in placeholder/snapshot
- [ ] Cache data for locked device scenarios
- [ ] Pre-compute complex metrics in timeline provider
- [ ] Minimize work in getTimeline()
- [ ] Test on actual device (not just simulator)

### Testing
- [ ] Test refresh behavior over 24 hour period
- [ ] Verify Smart Stack rotation works
- [ ] Test with device locked
- [ ] Verify App Group data sharing
- [ ] Test all three widget sizes
- [ ] Test Dark Mode
- [ ] Test in StandBy mode (iOS 17+)

---

## References

### Official Apple Documentation
- [WidgetKit Overview](https://developer.apple.com/documentation/widgetkit)
- [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- [TimelineProvider Protocol](https://developer.apple.com/documentation/widgetkit/timelineprovider)
- [TimelineEntryRelevance](https://developer.apple.com/documentation/widgetkit/timelineentryrelevance)
- [RelevanceKit Framework](https://developer.apple.com/documentation/RelevanceKit)

### WWDC Sessions
- **WWDC20 Session 10103**: Design great widgets
  - Margins (16pt/11pt)
  - Layout principles
  - Typography guidelines
- **WWDC21 Session 10048**: Principles of great widgets
  - Timeline strategies
  - Relevance scoring
  - Reload policies
  - Budget management
- **WWDC20 Session 10194**: Add configuration and intelligence to your widgets
- **WWDC24**: Latest WidgetKit updates and control widgets

### Community Resources
- [SwiftSenpai: Widget Refresh Guide](https://swiftsenpai.com/development/refreshing-widget/)
- [Medium: App Groups Data Sharing](https://michael-kiley.medium.com/sharing-object-data-between-an-ios-app-and-its-widget-a0a1af499c31)
- [Use Your Loaf: WidgetKit for iOS](https://useyourloaf.com/blog/widgetkit-for-ios-getting-started/)

---

**Document Version**: 1.0
**Last Updated**: 2025-01-17
**Based on**: iOS 17+ WidgetKit APIs, WWDC 2020-2024 Sessions
