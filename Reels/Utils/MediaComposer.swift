//
//  MediaComposer.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import AVFoundation
import UIKit

class MediaComposer {
    typealias NewPlayerItemCallback = @MainActor (AVPlayerItem, CMTime) -> ()
    private var onPlayerItem: NewPlayerItemCallback?
    private var assets = [AVAsset]()
    
    init(_ initialAssets: [AVAsset]) {
        self.assets = initialAssets
    }
    
    func addAsset(_ newAsset: AVAsset) {
        addAssets([newAsset])
    }
    
    func addAssets(_ newAssets: [AVAsset]) {
        assets.append(contentsOf: newAssets)
        if let callback = onPlayerItem {
            Task {
                let t = await createPlayerItem()
                await callback(t.0, t.1)
            }
        }
    }
    
    func setOnPlayerItem(_ callback: @escaping NewPlayerItemCallback) {
        onPlayerItem = callback
        Task {
            let t = await createPlayerItem()
            await callback(t.0, t.1)
        }
    }
    
    private func createPlayerItem() async -> (AVPlayerItem, CMTime) {
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
            let addedVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let addedAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try addedVideoTrack!.insertTimeRange(ranges[i], of: videoTracks[i], at: insertionTime)
            } catch {
                print("Couldn't add asset: \(error.localizedDescription)")
            }
            try? addedAudioTrack!.insertTimeRange(ranges[i], of: audioTracks[i], at: insertionTime)
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

        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = videoComposition
        return (playerItem, insertionTime)
    }
}
