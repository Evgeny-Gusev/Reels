//
//  MediaComposer.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import AVFoundation

class MediaComposer {
    lazy var playerItem: AVPlayerItem = {
        AVPlayerItem(asset: composition)
    }()
    
    private let composition: AVMutableComposition
    
    init(_ initialAsset: AVAsset) {
        self.composition = AVMutableComposition()
        Task {
            await addAsset(initialAsset)
        }
    }
    
    private func addAsset(_ asset: AVAsset) async {
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let (assetTimeRange, preferredTransform) = try? await videoTrack.load(.timeRange, .preferredTransform) else { return }
        
        async let audioTrack = try? asset.loadTracks(withMediaType: .audio).first
        let addedVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let insertTime = composition.duration
        
        do {
            try addedVideoTrack?.insertTimeRange(assetTimeRange, of: videoTrack, at: insertTime)
            addedVideoTrack?.preferredTransform = preferredTransform
            if let audio = await audioTrack {
                let addedAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try addedAudioTrack?.insertTimeRange(assetTimeRange, of: audio, at: insertTime)
            }
        } catch {
            print("Couldn't add asset:\n \(error.localizedDescription)")
        }
    }
}
