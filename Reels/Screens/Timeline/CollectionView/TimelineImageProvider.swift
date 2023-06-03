//
//  TimelineImageProvider.swift
//  Reels
//
//  Created by Eugene on 20/5/2023.
//

import UIKit
import AVFoundation

#warning("TODO: replace IndexPath with another ID")
actor TimelineImageProvider {
    private var timelineImageCache = MemoryCache<IndexPath, UIImage>()
    private var activeTasks = [IndexPath: Task<UIImage?, Never>]()
    
    func getTimeline(track: TimelineTrack, indexPath: IndexPath, targetSize: CGSize, scale: CGFloat = 1) async -> UIImage? {
        if let cached = timelineImageCache[indexPath] {
            return cached
        }
        
        if let existingTask = activeTasks[indexPath] {
            return await existingTask.value
        }
        
        let task = Task<UIImage?, Never> {
            defer {
                activeTasks[indexPath] = nil
            }
            
            guard let asset = track.assetTrack.asset,
                  let (originalNaturalSize, preferredTransform) = try? await track.assetTrack.load(.naturalSize, .preferredTransform) else { return nil }
            
            let transformedNaturalSize = originalNaturalSize.applying(preferredTransform)
            let naturalSize = CGSize(width: abs(transformedNaturalSize.width), height: (transformedNaturalSize.height))
            let frameWidth = targetSize.height * (naturalSize.width / naturalSize.height)
            let framesCount = Int((targetSize.width / frameWidth).rounded(.up))
            let frameGap = track.timeRange.duration.seconds / Double(framesCount)
            
            var times = [CMTime]()
            for frame in 0..<framesCount {
                times.append(CMTime(seconds: frameGap * Double(frame), preferredTimescale: 100))
            }
            
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            var images: [UIImage?] = Array(repeating: nil, count: times.count)
            for await result in generator.images(for: times) {
                if case let .success(requestedTime, cgImage, _) = result {
                    let index = Int((requestedTime.seconds / frameGap).rounded())
                    images[index] = UIImage(cgImage: cgImage)
                }
            }
            
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let timelineImage = renderer.image { context in
                UIColor.green.setFill()
                context.fill(CGRect(origin: .zero, size: targetSize))
                for (index, image) in images.enumerated() {
                    image?.draw(in: CGRect(x: frameWidth * CGFloat(index), y: 0, width: frameWidth, height: targetSize.height))
                }
            }
            timelineImageCache[indexPath] = timelineImage
            return timelineImage as UIImage?
        }
        
        activeTasks[indexPath] = task
        
        return await task.value
    }
}
