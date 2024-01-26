import Flutter
import UIKit

public class LatHdrTranscoderV2Plugin: NSObject, FlutterPlugin {
    private let cacheDirName = "_sdr_"

      private var eventSink: FlutterEventSink?


      private func log(text: String) {
  //        print(text)
      }

  public static func register(with registrar: FlutterPluginRegistrar) {
     let channel = FlutterMethodChannel(name: "lat_hdr_transcoder_v2", binaryMessenger: registrar.messenger())
            let instance = LatHdrTranscoderPlugin()
            registrar.addMethodCallDelegate(instance, channel: channel)

            let eventChannel = FlutterEventChannel(name: "lat_hdr_transcoder_v2_event", binaryMessenger: registrar.messenger())
            eventChannel.setStreamHandler(instance.self)
  }
 public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }


    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        log(text: "\(call.method), \(String(describing: call.arguments))")
        switch call.method {
        case "isHDR":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                TranscodeErrorType.invalidArgs.occurs(result: result)
                return
            }

            guard #available(iOS 14.0, *) else {
                TranscodeErrorType.notSupportVersion.occurs(result: result)
                return
            }

            let inputURL = URL(fileURLWithPath: path)
            let isHDR = Transcoder().isHDR(inputURL: inputURL)
            result(isHDR)

        case "clearCache":
            result(clearCache())

        case "transcoding":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                TranscodeErrorType.invalidArgs.occurs(result: result)
                return
            }

            let inputURL = URL(fileURLWithPath: path)
            let outputURL = outputFileURL(inputPath: path)

            guard deleteFileIfExists(url: outputURL) else {
                TranscodeErrorType.existsOutputFile.occurs(result: result)
                return
            }

            Transcoder().transcoding(inputURL: inputURL, outputURL: outputURL) { progress in
                self.log(text: "\(progress)")
                self.eventSink?(progress)
            } completion: { error in
                if let error = error {
                    TranscodeErrorType.failedConvert.occurs(result: result, extra: error.localizedDescription)
                } else {
                    self.eventSink?(1.0)
                    result(outputURL.relativePath)
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }


    private func outputFileURL(inputPath: String) -> URL {
        let inputUrl = URL(fileURLWithPath: inputPath)
        let fileName = inputUrl.deletingPathExtension().lastPathComponent
        let newFileName = fileName + "_sdr"

        let tempDirURL = createTempDirIfNot()
        let newURL = tempDirURL.appendingPathComponent(newFileName).appendingPathExtension("mp4")
        return newURL
    }

    private func clearCache() -> Bool {
        let url = cacheDirURL()

        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                return true
            } catch {
                return false
            }
        }
        return true
    }

    private func createTempDirIfNot() -> URL {
        let url = cacheDirURL()
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        } catch {
            log(text: error.localizedDescription)
            return url
        }
    }

    private func deleteFileIfExists(url: URL) -> Bool {
        let manager = FileManager.default
        guard manager.fileExists(atPath: url.relativePath) else {
            return true
        }

        do {
            try manager.removeItem(atPath: url.relativePath)
            return true
        } catch  {
            log(text: "error \(error)")
            return false
        }

    }

    private func cacheDirURL() -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(cacheDirName, isDirectory: true)
    }

    private func fileExists(url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.relativePath)
    }
}
