//
//  Coordinator.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit
import AVFoundation

class Coordinator {
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        navigationController.pushViewController(GalleryViewController(PHGalleryProvider()) { assets in
            self.navigationController.pushViewController(PlaybackViewController(initialAssets: assets, coordinator: self), animated: true)
        }, animated: false)
    }
}

protocol PlaybackCoordinator: AnyObject {
    func pickAdditionalAsset(callback: @escaping ([AVAsset]) -> ())
}

extension Coordinator: PlaybackCoordinator {
    func pickAdditionalAsset(callback: @escaping ([AVAsset]) -> ()) {
        navigationController.present(GalleryViewController(PHGalleryProvider()) { assets in
            callback(assets)
            self.navigationController.dismiss(animated: true)
        }, animated: true)
    }
}
