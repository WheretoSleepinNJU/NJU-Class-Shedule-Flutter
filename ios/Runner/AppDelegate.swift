import UIKit
import Flutter

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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleSendWidgetData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }

    print("Received widget data: \(args.keys)")

    // Save to UserDefaults (App Group)
    if let appGroup = UserDefaults(suiteName: "group.com.wheretosleepinnju.scheduleapp") {
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
        appGroup.set(jsonData, forKey: "widget_data")
        appGroup.synchronize()
        print("Widget data saved successfully")
        result(true)
      } catch {
        print("Failed to save widget data: \(error)")
        result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
      }
    } else {
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
    if let appGroup = UserDefaults(suiteName: "group.com.wheretosleepinnju.scheduleapp") {
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
    if let appGroup = UserDefaults(suiteName: "group.com.wheretosleepinnju.scheduleapp") {
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
      // WidgetCenter.shared.reloadAllTimelines()
      print("Widget refresh requested (requires WidgetKit)")
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
      "appGroupId": "group.com.wheretosleepinnju.scheduleapp"
    ]
    result(platformInfo)
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
