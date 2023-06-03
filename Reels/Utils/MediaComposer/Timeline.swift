//
//  Timeline.swift
//  Reels
//
//  Created by Eugene on 19/5/2023.
//

import AVFoundation
import Combine

class Timeline: NSObject {
    @objc dynamic private(set) var totalDuration: CMTime
    private(set) var videos: [TimelineTrack]
    
    weak var delegate: TimelineDelegate? = nil
    
    override init() {
        totalDuration = .zero
        videos = []
    }
    
    func add(_ asset: AVAsset) async {
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let (timeRange, preferredTransform) = try? await videoTrack.load(.timeRange, .preferredTransform) else {
            return
        }

        videos.append(TimelineTrack(asset: asset,
                                    assetTrack: videoTrack,
                                    timeRange: timeRange,
                                    transform: preferredTransform))
        totalDuration = totalDuration + timeRange.duration
        delegate?.timelineDidChange()
    }
}

protocol TimelineDelegate: AnyObject {
    func timelineDidChange()
}

struct TimelineTrack {
    let asset: AVAsset
    let assetTrack: AVAssetTrack
    let timeRange: CMTimeRange
    let transform: CGAffineTransform
}
