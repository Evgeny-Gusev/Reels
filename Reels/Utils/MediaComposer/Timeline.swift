//
//  Timeline.swift
//  Reels
//
//  Created by Eugene on 19/5/2023.
//

import AVFoundation

struct Timeline {
    let totalDuration: CMTime
    let videos: [TimelineTrack]
}

struct TimelineTrack {
    let assetTrack: AVAssetTrack
    let duration: CMTime
}
