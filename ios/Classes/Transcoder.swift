import AVFoundation
import CoreImage

class Transcoder {

    @available(iOS 14.0, *)
    func isHDR(inputURL: URL) -> Bool {
        let asset = AVURLAsset(url: inputURL)
        let hdrTracks = asset.tracks(withMediaCharacteristic: .containsHDRVideo)
        var isHdr = false
        for track in hdrTracks {
            isHdr = track.hasMediaCharacteristic(.containsHDRVideo)
            if isHdr {
                break
            }
        }
        return isHdr
    }

    func transcoding(inputURL: URL, outputURL: URL, progression: @escaping (Double) -> Void, completion: @escaping (Error?) -> Void){
        let asset = AVURLAsset(url: inputURL)

        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        guard let session = exportSession else {
            completion(NSError(domain: Bundle.main.bundleIdentifier!, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"]))
            return
        }

        var progress = 0.0
        progression(progress)
        let progressTimer: Timer = Timer(timeInterval: 0.1, repeats: true, block: { timer in
            let value = Double(session.progress)
            guard progress != value else { return }
            progress = value
            progression(progress)
        })
        RunLoop.main.add(progressTimer, forMode: .common)

        session.outputURL = outputURL
        session.outputFileType = AVFileType.mp4
        session.shouldOptimizeForNetworkUse = true
        session.exportAsynchronously {
            switch session.status {
            case .exporting:
                break
            case .waiting:
                break
            case .completed:
                progressTimer.invalidate();
                completion(nil)
            case .failed:
                progressTimer.invalidate();
                completion(session.error)
            case .cancelled:
                progressTimer.invalidate();
                completion(NSError(domain: Bundle.main.bundleIdentifier!, code: 0, userInfo: [NSLocalizedDescriptionKey: "Export session cancelled"]))
            default:
                progressTimer.invalidate();
                completion(NSError(domain: Bundle.main.bundleIdentifier!, code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"]))
            }
        }
    }


}