# Schedule Widget Extension

iOS Widget and Live Activities implementation for NJU Class Schedule app.

## Files Structure

```
ios/ScheduleWidget/
├── ScheduleWidget.swift              # Main widget configuration & TimelineProvider
├── Views/
│   ├── NextCourseView.swift          # Small widget (next course)
│   ├── TodayScheduleView.swift       # Medium widget (today's schedule)
│   ├── TimelineView.swift            # Large widget (full timeline)
│   └── EmptyStateView.swift          # Empty/error states
├── LiveActivity/
│   └── CourseActivityAttributes.swift # Live Activities (iOS 16.1+)
├── Info.plist                         # Widget extension configuration
└── README.md                          # This file
```

## Setup in Xcode

### 1. Add Widget Extension Target

1. Open `Runner.xcworkspace` in Xcode
2. File → New → Target
3. Select **Widget Extension**
4. Name: `ScheduleWidget`
5. Bundle ID: `com.wheretosleepinnju.scheduleapp.ScheduleWidget`
6. Click Finish

### 2. Add Existing Files to Target

Add these files to the ScheduleWidget target:

**From Runner folder:**
- `WidgetDataModels.swift` (right-click → Target Membership → check ScheduleWidget)
- `WidgetDataManager.swift` (right-click → Target Membership → check ScheduleWidget)

**From ScheduleWidget folder:**
- All `.swift` files in this directory

### 3. Configure App Groups

1. Select **ScheduleWidget** target
2. Signing & Capabilities tab
3. Click **+ Capability** → **App Groups**
4. Enable: `group.com.wheretosleepinnju.scheduleapp`

### 4. Update Deployment Target

1. Select **ScheduleWidget** target
2. General tab
3. Set **Minimum Deployments** to iOS 14.0 (or iOS 16.1 for Live Activities)

### 5. Add Frameworks (if needed)

The widget extension needs:
- WidgetKit.framework (automatically added)
- SwiftUI.framework (automatically added)
- ActivityKit.framework (for Live Activities, iOS 16.1+)

## Widget Sizes

### Small (systemSmall)
- Shows next course or current course
- Course name, time, classroom
- Status badge ("正在上课" or "下节课")

### Medium (systemMedium)
- Shows up to 3 courses for today
- List view with time indicators
- Current course highlighted

### Large (systemLarge)
- Full day timeline
- All courses with detailed info
- Visual timeline with current time indicator

## Live Activities (iOS 16.1+)

### Features
- Pre-class reminder notification
- Dynamic Island support
- Lock screen widget
- Real-time countdown

### States
- `upcoming`: 30+ minutes before class
- `starting_soon`: 5-15 minutes before class
- `in_progress`: During class
- `ending`: Last 5 minutes of class

### Starting Live Activity (from Flutter)

```dart
// This will be handled by Flutter MethodChannel
// iOS native code will create the activity using:
// Activity<CourseActivityAttributes>.request(
//     attributes: attributes,
//     contentState: contentState
// )
```

## Data Flow

```
Flutter App
    ↓ MethodChannel
AppDelegate
    ↓ UserDefaults (App Group)
WidgetDataManager
    ↓ Timeline Provider
Widget UI (SwiftUI)
```

## Timeline Refresh Strategy

Widgets automatically refresh:
- At the start of each class
- Every 15 minutes (fallback)
- When app sends new data (via `WidgetCenter.shared.reloadAllTimelines()`)

## Deep Linking

Widgets support URL scheme for navigation:

- `njuschedule://course/{id}` - Open specific course
- `njuschedule://refresh` - Refresh app data

Handle in Flutter:
```dart
// Add URL launcher or custom scheme handler
```

## Customization

### Colors
Course colors are read from `WidgetCourse.color` (HEX format).
Default: Blue (#4A90E2)

### Time Display
Uses `SchoolTimeTemplate` to convert period numbers to actual times.

Example:
- Period 3 at NJU = 09:50-10:35
- Period 3 at SEU = 09:50-10:30 (different template)

## Troubleshooting

### Widget shows "打开应用更新数据"
- App hasn't sent data yet
- Run the Flutter app and trigger data update
- Check AppDelegate logs for "Widget data saved successfully"

### Widget not updating
- Verify App Group capability is enabled on both targets
- Check App Group ID matches: `group.com.wheretosleepinnju.scheduleapp`
- Try force-quitting and reopening the app

### Live Activities not appearing
- Requires iOS 16.1+
- Check `NSSupportsLiveActivities` in Info.plist
- Verify ActivityKit framework is linked

### Colors not displaying
- Ensure course has valid HEX color (e.g., "#4A90E2")
- Check Color extension in NextCourseView.swift

## Testing

### In Xcode
1. Select **ScheduleWidget** scheme
2. Run on simulator or device
3. Widget preview appears
4. Add to home screen from widget gallery

### On Device
1. Long-press home screen
2. Tap **+** button
3. Search "课程表" or "Schedule"
4. Select widget size
5. Add to home screen

### Live Activities
1. Run main app on iOS 16.1+ device
2. Trigger course reminder from Flutter
3. Check Dynamic Island and lock screen

## Performance Considerations

- Timeline entries limited to 20
- Data cached in UserDefaults (max 50KB recommended)
- Widgets update at most once per 15 minutes (system limit)
- Live Activities auto-dismiss after class ends

## Localization

Currently supports:
- Simplified Chinese (primary)
- English (partial)

To add more languages:
1. Add localization in Xcode
2. Create `.strings` files
3. Use `NSLocalizedString` for text

## Known Limitations

- Widgets don't work in iOS simulator (iOS < 16)
- Live Activities require physical device
- Dynamic Island only on iPhone 14 Pro+
- Maximum 20 timeline entries per refresh

## Future Enhancements

- [ ] Lock screen circular widgets
- [ ] Inline lock screen widgets
- [ ] Widget configuration (select specific days)
- [ ] Dark mode color variants
- [ ] Interactive widgets (iOS 17+)
- [ ] StandBy mode support
- [ ] Apple Watch complications

## Resources

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Dynamic Island HIG](https://developer.apple.com/design/human-interface-guidelines/live-activities)
