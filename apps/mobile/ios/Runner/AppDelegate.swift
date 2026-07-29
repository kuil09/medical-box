import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var platformChannel: FlutterMethodChannel?
  private var medicineOcrChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "MedicalBoxPlatformPlugin"
    ) else {
      return
    }
    platformChannel = FlutterMethodChannel(
      name: "medical_box/platform",
      binaryMessenger: registrar.messenger()
    )
    platformChannel?.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup",
            let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path)
      do {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "BACKUP_EXCLUSION_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
    medicineOcrChannel = FlutterMethodChannel(
      name: "medical_box/medicine_ocr",
      binaryMessenger: registrar.messenger()
    )
    medicineOcrChannel?.setMethodCallHandler { [weak self] call, result in
      guard call.method == "recognizeMedicineText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.recognizeMedicineText(at: path, result: result)
    }
  }

  private func recognizeMedicineText(at path: String, result: @escaping FlutterResult) {
    let imageURL = URL(fileURLWithPath: path)
    DispatchQueue.global(qos: .userInitiated).async {
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      request.minimumTextHeight = 0.012

      do {
        let supported = try VNRecognizeTextRequest.supportedRecognitionLanguages(
          for: .accurate,
          revision: request.revision
        )
        let preferred = ["ko-KR", "en-US"].filter(supported.contains)
        guard preferred.contains("ko-KR") else {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "OCR_LANGUAGE_UNAVAILABLE",
                message: "Korean text recognition is unavailable on this device.",
                details: nil
              )
            )
          }
          return
        }
        request.recognitionLanguages = preferred

        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        try handler.perform([request])
        let lines = (request.results ?? []).compactMap { observation -> [String: Any]? in
          guard let candidate = observation.topCandidates(1).first else {
            return nil
          }
          return [
            "text": candidate.string,
            "confidence": Double(candidate.confidence),
          ]
        }
        DispatchQueue.main.async {
          result(lines)
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "OCR_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }
}
