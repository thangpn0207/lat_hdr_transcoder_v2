import Foundation
import Flutter

enum TranscodeErrorType: Int {
    case invalidArgs
    case notSupportVersion
    case existsOutputFile
    case failedConvert

    var code: String {
        return "\(self.rawValue)"
    }

    func message(extra: String?) -> String {
        switch self {
        case .invalidArgs:
            return "argument are not valid"
        case .notSupportVersion:
            return "iOS version is not supported"
        case .existsOutputFile:
            return "output file exists: \(String(describing: extra))"
        case .failedConvert:
            return "failed convert error: \(String(describing: extra))"
        }
    }

    func occurs(result: @escaping FlutterResult, extra: String? = nil) {
        result(FlutterError(code: self.code, message: self.message(extra: extra), details: nil))
    }
}