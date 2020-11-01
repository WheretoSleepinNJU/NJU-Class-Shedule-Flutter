import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UMConfigure.initWithAppkey("5f9e1efa1c520d30739d2737", channel: "umeng")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
