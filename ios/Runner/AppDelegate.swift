import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyOverlay: UIView?
  private var secureScreenRequested = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let messenger = engineBridge.pluginRegistry.registrar(
      forPlugin: "SecureScreen"
    )?.messenger() else { return }

    let channel = FlutterMethodChannel(
      name: "id.co.alchemist.beres/secure_screen",
      binaryMessenger: messenger
    )
    let textChannel = FlutterMethodChannel(
      name: "id.co.alchemist.beres/text_recognition",
      binaryMessenger: messenger
    )
    textChannel.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterError(code: "NO_PATH", message: "path is required", details: nil))
        return
      }
      AppDelegate.recognizeText(atPath: path, result: result)
    }

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "enable":
        self?.secureScreenRequested = true
        result(nil)
      case "disable":
        self?.secureScreenRequested = false
        self?.hidePrivacyOverlay()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    guard secureScreenRequested else { return }
    showPrivacyOverlay()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    hidePrivacyOverlay()
  }

  private func showPrivacyOverlay() {
    guard privacyOverlay == nil, let window = window else { return }

    let blur = UIBlurEffect(style: .systemMaterial)
    let overlay = UIVisualEffectView(effect: blur)
    overlay.frame = window.bounds
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(overlay)
    privacyOverlay = overlay
  }

  private static func recognizeText(atPath path: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      result(FlutterError(code: "BAD_IMAGE", message: "could not read the image", details: nil))
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(code: "RECOGNITION_FAILED", message: error.localizedDescription, details: nil))
        }
        return
      }

      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      let width = CGFloat(cgImage.width)
      let height = CGFloat(cgImage.height)

      let lines: [[String: Any]] = observations.compactMap { observation in
        guard let candidate = observation.topCandidates(1).first else { return nil }
        let box = observation.boundingBox
        let top = (1 - box.maxY) * height
        let bottom = (1 - box.minY) * height
        return [
          "text": candidate.string,
          "top": Double(top),
          "bottom": Double(bottom),
          "left": Double(box.minX * width),
        ]
      }

      DispatchQueue.main.async { result(lines) }
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "RECOGNITION_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func hidePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
