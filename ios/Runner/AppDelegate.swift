import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var recorder: VideoRecorder?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController
            as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.quantumrobotix/video",
            binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { [weak self]
            call, result in
            guard let self = self else { return }
            switch call.method {
            case "startRecording":
                let args = call.arguments as? [String: Any]
                let w = args?["width"] as? Int ?? 640
                let h = args?["height"] as? Int ?? 480
                do {
                    if self.recorder == nil {
                        self.recorder = VideoRecorder()
                    }

                    try self.recorder!.startRecording(
                        width: w,
                        height: h
                    )
                    result(true)
                } catch {
                    result(FlutterError(
                        code: "START_ERROR",
                        message: error.localizedDescription,
                        details: nil))
                }

            case "addFrame":
                let args = call.arguments as? [String: Any]
                if let bytes = args?["bytes"] as? FlutterStandardTypedData {
                    self.recorder?.addFrame(
                        jpegData: bytes.data)
                }
                result(true)

            case "stopRecording":
                self.recorder?.stopRecording { path in
                    result(path)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Foreground channel — no-op on iOS
        let fgChannel = FlutterMethodChannel(
            name: "com.quantumrobotix/foreground",
            binaryMessenger: controller.binaryMessenger)
        fgChannel.setMethodCallHandler { _, result in
            result(true) // iOS doesn't need foreground service
        }

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions)
    }
}