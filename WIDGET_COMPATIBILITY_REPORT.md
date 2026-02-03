# Widget Compatibility Fixes Report

**Branch:** `fix/widget-conflicts-review`  
**Date:** 2026-02-03  
**Status:** ✅ Fixed & Verified

## Executive Summary

Following the merge of the new iOS Widget architecture (PR#1) and the parallel development of HarmonyOS widgets, a review was conducted to identify and resolve compatibility issues. This document details the fixes applied to ensure both implementations coexist correctly and data pipelines function as expected.

## 🛠 Fixes Applied

### 1. iOS Refresh Linkage (Critical)
**Issue:** The main app UI (e.g., `CourseTableView.dart`) calls `WidgetHelper.refreshWidget()` to update widgets. The previous implementation for iOS in `WidgetHelper` was empty, causing widget refresh actions triggered by user interactions (switching weeks, tables) to have no effect on the new iOS widgets.
**Fix:** 
- Modified `lib/Utils/WidgetHelper.dart`.
- The `_updateIOSWidget` method now calls `WidgetRefreshHelper.manualRefresh()`.
- This bridges the legacy call site to the new `UnifiedDataService`, ensuring the main app correctly triggers updates for the new iOS widget architecture.

### 2. Live Activity Data Structure Mismatch
**Issue:** The Flutter side sends Live Activity data as a map containing an `activities` list: `{'activities': [...], ...}`. However, `AppDelegate.swift` was saving the entire map to UserDefaults. The iOS reader (`WidgetDataManager`) expected an array of objects directly (`[LiveActivityData]`), resulting in decoding failures.
**Fix:** 
- Updated `ios/Runner/AppDelegate.swift`.
- In `handleSendLiveActivityData`, the code now extracts the `activities` array from the arguments before saving it to UserDefaults (`live_activity_data` key).

### 3. Native Bridge Platform Detection
**Issue:** `NativeDataBridge.dart` had a hardcoded return value of `'ios'` for `_getCurrentPlatform()`, which would cause issues if the code were run on HarmonyOS or Android in the future.
**Fix:** 
- Updated `lib/core/widget_data/communication/native_data_bridge.dart`.
- Implemented dynamic platform detection using `dart:io`'s `Platform` class.
- Added support for `ohos` (HarmonyOS) and others.

### 4. App Group ID Safety
**Issue:** The App Group ID was defined in two separate places (`AppConstants.swift` and `ScheduleWidget.swift`), creating a risk of drift if one is changed but not the other.
**Fix:** 
- Added strict warning comments in both `ios/Runner/AppConstants.swift` and `ios/ScheduleWidget/ScheduleWidget.swift`.
- Explicitly stated that changes in one file must be reflected in the other.

## 🔍 Validation Status

| Component | Status | Notes |
|-----------|--------|-------|
| **iOS Widget Refresh** | ✅ Fixed | `WidgetHelper` now triggers `UnifiedDataService`. |
| **Logic Isolation** | ✅ Verified | HarmonyOS (`wheretosleepinnju/widget`) and iOS (`com.wheretosleepinnju/widget_data`) channels remain separate. |
| **Data Integrity** | ✅ Secured | Live Activity data format now matches between Reader and Writer. |
| **Maintainability** | ✅ Improved | Platform detection and App Group ID comments added. |

## 📝 Recommendations for Future Merges
- **Unified Constants:** Consider using a build-time configuration or a shared code generation step to synchronize the App Group ID between the main app and extension targets.
- **Channel unification:** Eventually migrate HarmonyOS implementation to use `com.wheretosleepinnju/widget_data` and `UnifiedDataService` to reduce code duplication.
