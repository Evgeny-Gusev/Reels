//
//  GalleryViewController.swift
//  Reels
//
//  Created by Eugene on 11/5/2023.
//

import UIKit
import AVKit

class GalleryViewController: UIViewController {
    private let galleryProvider: any GalleryProvider
    private let itemsPerRow = 3
    private var imageLoadingRequests = [IndexPath: Int32]()
    private let onSelection: @MainActor ([AVAsset]) -> ()
    private lazy var thumbnailSize = {
        let itemWidth = view.bounds.width / CGFloat(itemsPerRow)
        return CGSize(width: itemWidth, height: itemWidth * 16 / 9)
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(GalleryThumbnailCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    init(_ galleryProvider: any GalleryProvider, _ onSelection: @MainActor @escaping ([AVAsset]) -> ()) {
        self.galleryProvider = galleryProvider
        self.onSelection = onSelection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        galleryProvider.setGalleryUpdateCallback { [weak self] in
            self?.collectionView.reloadData()
        }
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return thumbnailSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let requestId = imageLoadingRequests[indexPath] {
            galleryProvider.cancelRequest(requestId)
            imageLoadingRequests[indexPath] = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Task {
            guard let asset = await galleryProvider.getAVAssetForItem(at: indexPath.item) else { return }
            onSelection([asset])
        }
    }
}

extension GalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryProvider.videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(at: indexPath, type: GalleryThumbnailCollectionViewCell.self)
        imageLoadingRequests[indexPath] = galleryProvider.getImageForItem(at: indexPath.item,
                                                                          targetSize: thumbnailSize,
                                                                          onImage: { [weak cell] image in
            DispatchQueue.main.async { cell?.imageView.image = image }
        })
        return cell
    }
}
