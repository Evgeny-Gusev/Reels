//
//  MediaComposer.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import AVFoundation
import UIKit

class MediaComposer {
    private(set) var timeline = Timeline()
    private(set) var player = AVPlayer(playerItem: nil)
    
    init(_ initialAssets: [AVAsset]) {
        timeline.delegate = self
        addAssets(initialAssets)
    }
    
    func addAsset(_ newAsset: AVAsset) {
        addAssets([newAsset])
    }
    
    func addAssets(_ newAssets: [AVAsset]) {
        Task {
            for asset in newAssets {
                await timeline.add(asset)
            }
        }
    }
    
    private func generateComposition() async {
        let mutableComposition = AVMutableComposition()
        
        let mutableVideoTracks = [
            mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!,
            mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        ]
        let mutableAudioTracks = [
            mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!,
            mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        ]
        
        var insertionTime: CMTime = .zero
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
        for (index, track) in timeline.videos.enumerated() {
            guard let videoTrack = try? await track.asset.loadTracks(withMediaType: .video).first,
                  let audioTrack = try? await track.asset.loadTracks(withMediaType: .audio).first else {
                continue
            }
            let alternatingIndex = index % mutableVideoTracks.count
            do {
                try mutableVideoTracks[alternatingIndex].insertTimeRange(track.timeRange,
                                                          of: videoTrack,
                                                          at: insertionTime)
            } catch {
                print("Couldn't add asset: \(error.localizedDescription)")
                continue
            }
            try? mutableAudioTracks[alternatingIndex].insertTimeRange(track.timeRange,
                                                                      of: audioTrack,
                                                                      at: insertionTime)
            
            insertionTime = insertionTime + track.timeRange.duration
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableVideoTracks[alternatingIndex])
            layerInstruction.setTransform(track.transform, at: .zero)
            layerInstruction.setOpacity(0, at: insertionTime)
            instructions.append(layerInstruction)
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: insertionTime)
        mainInstruction.layerInstructions = instructions
                
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: 1080, height: 1920)
        
        let currentTime = player.currentTime()
        let newPlayerItem = AVPlayerItem(asset: mutableComposition)
        newPlayerItem.videoComposition = videoComposition
        if currentTime != .invalid {
            let tolerance = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            newPlayerItem.seek(to: currentTime,
                               toleranceBefore: tolerance,
                               toleranceAfter: tolerance,
                               completionHandler: nil)
        }
        player.replaceCurrentItem(with: newPlayerItem)
    }
    
    func togglePlayback() {
        player.rate == 0 ? player.play() : player.pause()
    }
}

extension MediaComposer: TimelineDelegate {
    func timelineDidChange() {
        Task {
            await generateComposition()
        }
    }
}
