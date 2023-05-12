//
//  GalleryProvider.swift
//  Reels
//
//  Created by Eugene on 11/5/2023.
//

import UIKit
import AVKit

protocol GalleryProvider<VideoID> {
    associatedtype VideoID: Hashable
    
    var videos: [VideoID] { get }
    //    var hasAccess: Bool { get }

    func getImageForItem(at index: Int, targetSize: CGSize, onImage: @escaping (UIImage?) -> ()) -> Int32?
    func cancelRequest(_ id: Int32)
    func getAVAssetForItem(at index: Int) async -> AVAsset?
    func setGalleryUpdateCallback(_ callback: @escaping @MainActor () -> ())
}
