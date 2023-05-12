//
//  PHGalleryProvider.swift
//  Reels
//
//  Created by Eugene on 11/5/2023.
//

import Photos
import UIKit

class PHGalleryProvider: GalleryProvider {
    typealias VideoID = String
    
    private(set) var videos = [VideoID]()
    private var assets = [VideoID: PHAsset]()
    private var cache: any CacheService<VideoID, UIImage>
    private let manager = PHImageManager.default()
    private var onGalleryUpdate: (@MainActor () -> ())? = nil
    
    init(cacheService: any CacheService<VideoID, UIImage> = MemoryCache<VideoID, UIImage>()) {
        self.cache = cacheService
        
        Task {
            let authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            guard authorizationStatus == .authorized else {
                //isAccessGranted = false
                return
            }
            
            let fetchResult = PHAsset.fetchAssets(with: .video, options: nil)
            
            fetchResult.enumerateObjects { asset, _, _ in
                self.assets[asset.localIdentifier] = asset
                self.videos.append(asset.localIdentifier)
            }
            
            await onGalleryUpdate?()
        }
    }
    
    func getImageForItem(at index: Int, targetSize: CGSize, onImage: @escaping (UIImage?) -> ()) -> Int32? {
        let id = videos[index]
        guard let asset = assets[id] else { return nil }
        
        if let cached = cache[id] {
            onImage(cached)
            return nil
        }
        
        return manager.requestImage(for: asset,
                                    targetSize: targetSize,
                                    contentMode: .aspectFill,
                                    options: nil,
                                    resultHandler: { [weak self] image, _ in
            if let image {
                self?.cache[id] = image
            }
            onImage(image)
        })
    }
    
    func cancelRequest(_ id: PHImageRequestID) {
        manager.cancelImageRequest(id)
    }

    func getAVAssetForItem(at index: Int) async -> AVAsset? {
        let id = videos[index]
        guard let asset = assets[id] else { return nil }
        return await withCheckedContinuation { continuation in
            manager.requestAVAsset(forVideo: asset, options: nil) { avasset, _, _ in
                continuation.resume(returning: avasset)
            }
        }
    }
    
    func setGalleryUpdateCallback(_ callback: @escaping @MainActor () -> ()) {
        onGalleryUpdate = callback
    }
}
