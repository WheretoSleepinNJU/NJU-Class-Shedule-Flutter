# Widget/Live Activity Architecture Refactoring Guide (v1.1)

## 1. Overview
This refactoring decouples the Flutter app (Data Provider) from the iOS Widget (Display Layer).
- **Previous Architecture**: Flutter pre-calculates `currentCourse`/`nextCourse`. Widget is passive.
- **New Architecture**: Flutter sends raw schedule data. iOS Widget calculates state (what to show) at runtime based on `Date()`.
- **Note**: Live Activity implementation is **postponed** (TODO) for a future Server Push implementation.

## 2. Key Principles
1.  **Single Source of Truth**: Flutter provides raw data (`todayCourses`, `tomorrowCourses`, `timeTemplate`).
2.  **Logic Consistency**: Time calculation logic (`getPeriodRange`, `minutesUntil`) MUST be identical in Dart and Swift.
3.  **Autonomous Widget**: The Widget determines "Current State" (In Class, Break, Finished) by itself.
4.  (TODO) **Live Activity**: Postponed.

## 3. Implementation Plan

### Stage 1: Data Model (Dart & Swift)
The `WidgetScheduleData` structure changes significantly.

**Dart Changes**:
- **File**: `lib/core/widget_data/models/widget_schedule_data.dart`
- **Action**:
    - Remove `nextCourse`, `currentCourse`, `todayCourseCount`, `tomorrowCourseCount`.
    - Add `version` (String, default "2.0").
    - Ensure `timeTemplate` is included.
    - Ensure `todayCourses` and `tomorrowCourses` are sorted lists of `WidgetCourse`.

**Swift Changes**:
- **File**: `ios/Runner/WidgetDataModels.swift`
- **Action**:
    - Update `WidgetScheduleData` struct to match the new JSON format.
    - Implement a `LegacyWidgetScheduleData` struct (optional) or `init(from decoder)` logic to handle old data gracefully if needed, OR just force a refresh.

### Stage 2: Flutter Logic (UnifiedDataService)
Stop calculating state.

**File**: `lib/core/widget_data/services/unified_data_service.dart`
- **Remove**: Logic that finds current/next course inside `getWidgetData`.
- **Keep**: Logic that filters courses for today/tomorrow.
- **Comment Out/Remove**: Any Live Activity logic.

### Stage 3: iOS Widget Logic (Timeline & View)
This is the most critical part.

**File**: `ios/ScheduleWidget/ScheduleWidget.swift` (ScheduleEntry)
- **Add Computed Properties**:
    - `currentCourse`: Returns `WidgetCourse?` based on `entry.date` and `timeTemplate`.
    - `nextCourse`: Returns `WidgetCourse?` (upcoming).
    - `displayState`: Returns enum (inClass, break, finished, etc.).
- **Logic**:
    - Use `Calendar.current` to compare `entry.date` with `course.startPeriod` (mapped to time via `timeTemplate`).
    - *Critical*: Ensure time comparison logic matches Dart side.

**File**: `ios/ScheduleWidget/ScheduleWidget.swift` (Provider)
- **Timeline Generation**:
    1.  Create `current` entry.
    2.  Calculate future change points:
        - Start time of next course.
        - End time of next course.
        - Start time of *next next* course.
    3.  Create entries for these specific dates (`Policy.after(date)`).
    4.  Do *not* rely on 15-min intervals. Rely on exact course times.

**File**: `ios/ScheduleWidget/Views/SmallWidgetView.swift`
- Update view to read `entry.currentCourse`/`entry.displayState` instead of static fields.

### Stage 4: Live Activity Management (TODO)
**Deferred to future update.**
- Comment out any existing Live Activity code in `ScheduleWidget` extension entries if they exist, or just leave them alone if they don't block build.
- Do NOT implement `LiveActivityManager` for now.

## 4. Coding Instructions for AI Agent


### General Rules
- **Do not remove** existing imports unless unused.
- **Comments**: Keep comments explaining *why* a calculation is done.
- **Safety**: Always use `if let` or `guard` when parsing JSON or dealing with optional dates.
- **Formatting**: existing code style.

### Specific Tasks

#### Task 1: Update Dart Data Model
1.  Open `lib/core/widget_data/models/widget_schedule_data.dart`.
2.  Remove `nextCourse`, `currentCourse` fields and their constructor/JSON logic.
3.  Add `final String version = '2.0';`.

#### Task 2: Update Swift Data Model
1.  Open `ios/Runner/WidgetDataModels.swift`.
2.  Sync `WidgetScheduleData` struct with Dart changes.

#### Task 3: Implement Widget Logic
1.  Open `ios/ScheduleWidget/ScheduleWidget.swift`.
2.  In `ScheduleEntry`, add functions:
    ```swift
    func currentCourse(at date: Date) -> WidgetCourse? { ... }
    func nextCourse(at date: Date) -> WidgetCourse? { ... }
    ```
3.  Implement `displayState` enum and logic.
4.  In `Provider.getTimeline`, iterate through `todayCourses` to find start/end times and create timeline entries for those specific timestamps.

#### Task 4: Clean up Flutter Service & UI
1.  Open `lib/core/widget_data/services/unified_data_service.dart`.
2.  Simplify `getWidgetData()` to only return raw lists.
3.  Comment out any code related to `findNextCourse` or Live Activity trigger.
4.  Open `lib/Pages/Settings/WidgetSettingsView.dart`.
5.  Hide (comment out or remove) all settings related to Live Activity (e.g., Enable Live Activity, Motivational Text).

### Validation Checklist
- [ ] Widget displays correct course at 08:00 (Start of class).
- [ ] Widget displays correct "Break" status at 08:50 (End of class).
- [ ] Timeline contains entries for all course transitions.
- [ ] App compiles on both Android (Dart only check) and iOS.
- [ ] Live Activity code and Settings UI are commented out or hidden.
