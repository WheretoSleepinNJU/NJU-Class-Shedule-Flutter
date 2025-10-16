import UIKit
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var widgetDataChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up widget data method channel
    setupWidgetDataChannel()

//     MobClick.handle(url)
//     UMCommonLogSwift.setUpUMCommonLogManager()
//     UMCommonSwift.setLogEnabled(bFlag: true)
//     UMConfigure.initWithAppkey("5f9e1afa1c520d30739d2737", channel: "umeng")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupWidgetDataChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("Failed to get FlutterViewController")
      return
    }

    widgetDataChannel = FlutterMethodChannel(
      name: "com.wheretosleepinnju/widget_data",
      binaryMessenger: controller.binaryMessenger
    )

    widgetDataChannel?.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call, result: result)
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "sendWidgetData":
      handleSendWidgetData(call, result: result)
    case "sendLiveActivityData":
      handleSendLiveActivityData(call, result: result)
    case "sendUnifiedDataPackage":
      handleSendUnifiedDataPackage(call, result: result)
    case "refreshWidgets":
      handleRefreshWidgets(result: result)
    case "refreshLiveActivities":
      handleRefreshLiveActivities(result: result)
    case "getPlatformInfo":
      handleGetPlatformInfo(result: result)
    case "debugReadWidgetData":
      handleDebugReadWidgetData(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleSendWidgetData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("📱 [AppDelegate] ========== Widget Data Request ==========")

    guard let args = call.arguments as? [String: Any] else {
      print("❌ [AppDelegate] Invalid arguments type")
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }

    print("✅ [AppDelegate] Received arguments with keys: \(args.keys)")
    print("📊 [AppDelegate] Timestamp: \(args["timestamp"] ?? "N/A")")
    print("📊 [AppDelegate] Platform: \(args["platform"] ?? "N/A")")

    // Extract the actual widget data from the 'data' field
    guard let widgetData = args["data"] as? [String: Any] else {
      print("❌ [AppDelegate] Missing 'data' field in arguments")
      result(FlutterError(code: "INVALID_DATA", message: "Missing 'data' field", details: nil))
      return
    }

    print("✅ [AppDelegate] Widget data extracted successfully")
    print("📊 [AppDelegate] Widget data keys: \(widgetData.keys)")

    // Log key data fields
    if let todayCourses = widgetData["todayCourses"] as? [[String: Any]] {
      print("📚 [AppDelegate] Today's courses count: \(todayCourses.count)")
    }
    if let currentCourse = widgetData["currentCourse"] as? [String: Any],
       let courseName = currentCourse["name"] as? String {
      print("📖 [AppDelegate] Current course: \(courseName)")
    }
    if let nextCourse = widgetData["nextCourse"] as? [String: Any],
       let courseName = nextCourse["name"] as? String {
      print("📖 [AppDelegate] Next course: \(courseName)")
    }

    // Save to UserDefaults (App Group)
    let appGroupId = "group.top.idealclover.wheretosleepinnju"
    print("🔐 [AppDelegate] Attempting to access App Group: \(appGroupId)")

    if let appGroup = UserDefaults(suiteName: appGroupId) {
      print("✅ [AppDelegate] App Group accessed successfully")

      do {
        let jsonData = try JSONSerialization.data(withJSONObject: widgetData, options: [])
        let dataSize = jsonData.count
        print("📦 [AppDelegate] JSON serialized successfully, size: \(dataSize) bytes")

        appGroup.set(jsonData, forKey: "widget_data")
        appGroup.set(Date(), forKey: "last_update_time")

        let syncSuccess = appGroup.synchronize()
        print("💾 [AppDelegate] UserDefaults synchronize: \(syncSuccess ? "✅ Success" : "⚠️ Failed")")

        // Verify data was saved
        if let savedData = appGroup.data(forKey: "widget_data") {
          print("✅ [AppDelegate] Data verified in UserDefaults: \(savedData.count) bytes")
        } else {
          print("⚠️ [AppDelegate] Warning: Could not verify saved data")
        }

        // Trigger widget refresh immediately
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
          print("🔄 [AppDelegate] Widget refresh triggered via WidgetCenter")
        } else {
          print("⚠️ [AppDelegate] WidgetKit not available (iOS < 14)")
        }

        print("✅ [AppDelegate] ========== Widget Data Saved Successfully ==========")
        result(true)
      } catch {
        print("❌ [AppDelegate] JSON serialization failed: \(error)")
        print("❌ [AppDelegate] Error details: \(error.localizedDescription)")
        result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
      }
    } else {
      print("❌ [AppDelegate] Failed to access App Group: \(appGroupId)")
      print("⚠️ [AppDelegate] Make sure App Groups capability is enabled")
      result(FlutterError(code: "APP_GROUP_ERROR", message: "Failed to access App Group", details: nil))
    }
  }

  private func handleSendLiveActivityData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }

    print("Received live activity data: \(args.keys)")

    // Save to UserDefaults (App Group)
    if let appGroup = UserDefaults(suiteName: "group.top.idealclover.wheretosleepinnju") {
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
        appGroup.set(jsonData, forKey: "live_activity_data")
        appGroup.synchronize()
        print("Live activity data saved successfully")
        result(true)
      } catch {
        print("Failed to save live activity data: \(error)")
        result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
      }
    } else {
      result(FlutterError(code: "APP_GROUP_ERROR", message: "Failed to access App Group", details: nil))
    }
  }

  private func handleSendUnifiedDataPackage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }

    print("Received unified data package")

    // Save to UserDefaults (App Group)
    if let appGroup = UserDefaults(suiteName: "group.top.idealclover.wheretosleepinnju") {
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
        appGroup.set(jsonData, forKey: "unified_data_package")
        appGroup.set(Date(), forKey: "last_update_time")
        appGroup.synchronize()
        print("Unified data package saved successfully")
        result(true)
      } catch {
        print("Failed to save unified data package: \(error)")
        result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
      }
    } else {
      result(FlutterError(code: "APP_GROUP_ERROR", message: "Failed to access App Group", details: nil))
    }
  }

  private func handleRefreshWidgets(result: @escaping FlutterResult) {
    // Trigger widget refresh
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
      print("Widget refresh triggered successfully")
      result(true)
    } else {
      result(FlutterError(code: "UNSUPPORTED", message: "Widgets require iOS 14+", details: nil))
    }
  }

  private func handleRefreshLiveActivities(result: @escaping FlutterResult) {
    // Trigger Live Activities refresh
    if #available(iOS 16.1, *) {
      print("Live Activities refresh requested (requires ActivityKit)")
      result(true)
    } else {
      result(FlutterError(code: "UNSUPPORTED", message: "Live Activities require iOS 16.1+", details: nil))
    }
  }

  private func handleGetPlatformInfo(result: @escaping FlutterResult) {
    let platformInfo: [String: Any] = [
      "platform": "ios",
      "version": UIDevice.current.systemVersion,
      "model": UIDevice.current.model,
      "supportsWidgets": true,
      "supportsLiveActivities": true,
      "appGroupId": "group.top.idealclover.wheretosleepinnju"
    ]
    result(platformInfo)
  }

  private func handleDebugReadWidgetData(result: @escaping FlutterResult) {
    print("🔍 [AppDelegate] ========== Debug: Reading Widget Data ==========")

    let appGroupId = "group.top.idealclover.wheretosleepinnju"
    guard let appGroup = UserDefaults(suiteName: appGroupId) else {
      print("❌ [AppDelegate] Failed to access App Group")
      result(FlutterError(code: "APP_GROUP_ERROR", message: "Cannot access App Group", details: nil))
      return
    }

    print("✅ [AppDelegate] App Group accessed")

    // Check if data exists
    guard let jsonData = appGroup.data(forKey: "widget_data") else {
      print("❌ [AppDelegate] No data found in App Group")
      print("🔍 [AppDelegate] Available keys:")
      for (key, _) in appGroup.dictionaryRepresentation() {
        print("   - \(key)")
      }
      result(FlutterError(code: "NO_DATA", message: "No widget_data found", details: nil))
      return
    }

    print("✅ [AppDelegate] Data found: \(jsonData.count) bytes")

    // Try to parse and return the data
    do {
      let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
      if let dict = jsonObject as? [String: Any] {
        print("✅ [AppDelegate] Data parsed successfully")
        print("📊 [AppDelegate] Keys: \(dict.keys)")

        if let todayCourses = dict["todayCourses"] as? [[String: Any]] {
          print("📚 [AppDelegate] Today's courses: \(todayCourses.count)")
        }

        result(dict)
      } else {
        print("❌ [AppDelegate] Data is not a dictionary")
        result(FlutterError(code: "INVALID_FORMAT", message: "Data is not a dictionary", details: nil))
      }
    } catch {
      print("❌ [AppDelegate] Failed to parse JSON: \(error)")
      result(FlutterError(code: "PARSE_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  //友盟测试：iOS9以上使用以下方法
//   override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//       if MobClick.handle(url) {
//           return true
//       }
//       //其它第三方处理
//       return true
//   }
}
