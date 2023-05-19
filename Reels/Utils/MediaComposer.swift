//
//  MediaComposer.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import AVFoundation
import UIKit

class MediaComposer {
    private var assets = [AVAsset]()
    private var looper: AVPlayerLooper?
    
    @Published private(set) var timeline = Timeline(totalDuration: .zero, videos: [])
    @Published private(set) var player: AVPlayer? = nil
    
    init(_ initialAssets: [AVAsset]) {
        self.assets = []
        addAssets(initialAssets)
    }
    
    func addAsset(_ newAsset: AVAsset) {
        addAssets([newAsset])
    }
    
    func addAssets(_ newAssets: [AVAsset]) {
        assets.append(contentsOf: newAssets)
        Task {
            await createPlayerItem()
        }
    }
    
    private func createPlayerItem() async {
        var timelineVideoTracks = [TimelineTrack]()
        let composition = AVMutableComposition()
        var videoTracks = [AVAssetTrack]()
        var audioTracks = [AVAssetTrack]()
        var ranges = [CMTimeRange]()
        var transforms = [CGAffineTransform]()
        for asset in assets {
            videoTracks.append(try! await asset.loadTracks(withMediaType: .video)[0])
            audioTracks.append(try! await asset.loadTracks(withMediaType: .audio)[0])
            let (assetTimeRange, preferredTransform) = try! await videoTracks.last!.load(.timeRange, .preferredTransform)
            ranges.append(assetTimeRange)
            transforms.append(preferredTransform)
        }
        
        var insertionTime: CMTime = .zero
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
        for i in videoTracks.indices {
            let addedVideoTrack = composition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: kCMPersistentTrackID_Invalid)
            let addedAudioTrack = composition.addMutableTrack(withMediaType: .audio,
                                                              preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try addedVideoTrack!.insertTimeRange(ranges[i],
                                                     of: videoTracks[i],
                                                     at: insertionTime)
            } catch {
                print("Couldn't add asset: \(error.localizedDescription)")
            }
            timelineVideoTracks.append(TimelineTrack(assetTrack: videoTracks[i],
                                                     duration: ranges[i].duration))
            try? addedAudioTrack!.insertTimeRange(ranges[i],
                                                  of: audioTracks[i],
                                                  at: insertionTime)
            addedVideoTrack?.preferredTransform = transforms[i]
            insertionTime = insertionTime + ranges[i].duration
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: addedVideoTrack!)
            layerInstruction.setTransform(transforms[i], at: .zero)
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
        
        timeline = Timeline(totalDuration: insertionTime, videos: timelineVideoTracks)
        let currentPlayRate = self.player?.rate ?? 1
        self.player?.pause()
        let currentTime = self.player?.currentTime() ?? .zero
        let newPlayerItem = AVPlayerItem(asset: composition)
        newPlayerItem.videoComposition = videoComposition
        let queuePlayer = AVQueuePlayer()
        looper = AVPlayerLooper(player: queuePlayer, templateItem: newPlayerItem)
        self.player = queuePlayer
        
        await MainActor.run {
            self.player?.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero)
            self.player?.rate = currentPlayRate
        }
    }
    
    func togglePlayback() {
        guard let player else { return }
        player.rate == 0 ? player.play() : player.pause()
    }
}

struct Timeline {
    let totalDuration: CMTime
    let videos: [TimelineTrack]
}

struct TimelineTrack {
    let assetTrack: AVAssetTrack
    let duration: CMTime
}
