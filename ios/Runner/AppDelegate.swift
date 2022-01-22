import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
//     MobClick.handle(url)
//     UMCommonLogSwift.setUpUMCommonLogManager()
//     UMCommonSwift.setLogEnabled(bFlag: true)
//     UMConfigure.initWithAppkey("5f9e1efa1c520d30739d2737", channel: "umeng")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  //  Converted to Swift 5.5 by Swiftify v5.5.27463 - https://swiftify.com/
  //iOS9以上使用以下方法
  override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      if MobClick.handle(url) {
          return true
      }
      //其它第三方处理
      return true
  }
}
