import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var liveActivityChannel: LiveActivityChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for ActivityKit push tokens. Live Activities use APNs
    // independently of regular notification permission, but the app must
    // still register for remote notifications so APNs accepts the
    // per-activity push tokens emitted by `pushTokenUpdates`.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LiveActivityChannel")
    if let messenger = registrar?.messenger() {
      liveActivityChannel = LiveActivityChannel(messenger: messenger)
    }
  }
}
