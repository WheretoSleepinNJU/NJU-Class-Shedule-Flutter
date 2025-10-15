# iOS Widget & Live Activities Setup Guide

This guide explains how to set up iOS Widgets and Live Activities for the NJU Class Schedule app.

## Overview

The implementation consists of:
- **Flutter Side**: Data packaging and communication (`lib/core/widget_data/`)
- **iOS Side**: Data reception and storage (`ios/Runner/`)

## Files Added

### Flutter Side
- `lib/core/widget_data/models/` - Data models
- `lib/core/widget_data/communication/native_data_bridge.dart` - MethodChannel bridge
- `lib/core/widget_data/services/unified_data_service.dart` - Data service
- `lib/core/widget_data/exporters/unified_exporter.dart` - Platform exporters

### iOS Side
- `ios/Runner/AppDelegate.swift` - MethodChannel handler (updated)
- `ios/Runner/WidgetDataModels.swift` - Swift data models
- `ios/Runner/WidgetDataManager.swift` - Data management utility

## Setup Instructions

### 1. Configure App Groups in Xcode

App Groups allow data sharing between the main app and widget extensions.

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** and add **App Groups**
5. Enable (or create) an App Group with ID: `group.com.wheretosleepinnju.scheduleapp`

### 2. Add WidgetDataModels.swift to Xcode Project

The file has been created but needs to be added to the Xcode project:

1. In Xcode, right-click on the `Runner` folder
2. Select **Add Files to "Runner"...**
3. Navigate to `ios/Runner/WidgetDataModels.swift`
4. Check **Copy items if needed**
5. Ensure **Runner** target is selected
6. Click **Add**

Repeat for `WidgetDataManager.swift`.

### 3. Create Widget Extension (Future Step)

To create actual widgets:

1. In Xcode: **File** → **New** → **Target**
2. Select **Widget Extension**
3. Name it (e.g., "ScheduleWidget")
4. Add the same App Group capability
5. Import `WidgetDataModels.swift` and `WidgetDataManager.swift`
6. Use `WidgetDataManager.shared.loadWidgetData()` to load data

### 4. Update Info.plist (if needed)

The App Group ID is already configured in the code. No Info.plist changes are required unless you want to customize the group ID.

## Usage from Flutter

### Initialize Service

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_app/core/widget_data/services/unified_data_service.dart';

final prefs = await SharedPreferences.getInstance();
final service = UnifiedDataService(preferences: prefs);
```

### Send Data to iOS

```dart
// Update widget data
await service.updateWidgetData();

// Or send platform-specific data
await service.sendToNative(
  widgetData: await service.getWidgetData(),
  liveActivities: await service.getLiveActivityData(),
);
```

### Export Platform-Specific Data

```dart
final iosData = await service.exportPlatformData(platform: 'ios');
print(iosData); // Contains iOS-specific metadata
```

## Data Flow

```
┌─────────────────┐
│  Flutter App    │
│  (Dart)         │
└────────┬────────┘
         │
         │ MethodChannel
         ▼
┌─────────────────┐
│  AppDelegate    │
│  (Swift)        │
└────────┬────────┘
         │
         │ Save to UserDefaults
         ▼
┌─────────────────┐
│  App Group      │
│  Shared Storage │
└────────┬────────┘
         │
         │ Load from UserDefaults
         ▼
┌─────────────────┐
│  Widget         │
│  Extension      │
└─────────────────┘
```

## Data Models

### WidgetCourse
```swift
struct WidgetCourse {
    let id: String
    let name: String
    let classroom: String?
    let teacher: String?
    let startPeriod: Int      // 1-based period number
    let periodCount: Int      // Duration in periods
    let weekDay: Int          // 1-7
    let schoolId: String      // For time template lookup
    let weeks: [Int]          // Active weeks
}
```

### SchoolTimeTemplate
```swift
struct SchoolTimeTemplate {
    let schoolId: String
    let schoolName: String
    let periods: [ClassPeriod]  // Array of time periods
}
```

### WidgetScheduleData
Complete widget data package including:
- Today's courses
- Tomorrow's courses
- Next course
- Current course
- Weekly schedule
- School time template
- Metadata

## Testing

### Test Data Reception

Add this to your Flutter code:

```dart
import 'package:your_app/core/widget_data/communication/native_data_bridge.dart';

final bridge = NativeDataBridge();

// Test platform info
final info = await bridge.getPlatformInfo();
print('Platform: ${info}');

// Test data sending
final testData = WidgetScheduleData(
  version: '1.0',
  timestamp: DateTime.now(),
  schoolId: 'nju',
  schoolName: '南京大学',
  timeTemplate: SchoolTimeTemplate.nanjingUniversity,
  // ... other fields
);

final success = await bridge.sendWidgetData(testData);
print('Data sent: $success');
```

### Check iOS Logs

In Xcode:
1. Run the app on a simulator or device
2. Open **Debug** → **Debug Area** → **Activate Console**
3. Send data from Flutter
4. Look for log messages:
   - "Received widget data: ..."
   - "Widget data saved successfully"

## Multi-School Support

The system supports multiple schools with different class schedules:

```dart
// Nanjing University (50-minute classes)
SchoolTimeTemplate.nanjingUniversity

// Southeast University (45-minute classes)
SchoolTimeTemplate.southeastUniversity
```

Each school has its own time period definitions. Courses store `startPeriod` (not absolute times), allowing the same course data to work across different schools.

## Troubleshooting

### "Failed to access App Group"
- Ensure App Group capability is enabled in Xcode
- Verify the App Group ID matches: `group.com.wheretosleepinnju.scheduleapp`
- Check that both Runner and Widget Extension have the capability

### "No data found for key"
- Check that Flutter successfully sent the data
- Verify iOS logs show "Data saved successfully"
- Use `WidgetDataManager.shared.printAllData()` for debugging

### Widget not updating
- Ensure the Widget Extension has the same App Group capability
- Call `WidgetCenter.shared.reloadAllTimelines()` after saving data
- Check Widget timeline provider implementation

## Next Steps

1. **Create Widget Extension**: Follow Step 3 above
2. **Design Widget UI**: Use SwiftUI to create widget views
3. **Implement TimelineProvider**: Define how widgets update
4. **Add Live Activities**: For iOS 16.1+ course reminders
5. **Test on Device**: Widgets don't work in simulator (iOS <16)

## Resources

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Live Activities Documentation](https://developer.apple.com/documentation/activitykit)
- [App Groups Guide](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

## Notes

- Widgets require iOS 14.0+
- Live Activities require iOS 16.1+
- Dynamic Island requires iPhone 14 Pro+
- App Groups require proper provisioning profiles for production builds
