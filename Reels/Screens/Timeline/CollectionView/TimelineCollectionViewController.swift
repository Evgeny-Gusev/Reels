//
//  TimelineCollectionViewController.swift
//  Reels
//
//  Created by Eugene on 19/5/2023.
//

import UIKit
import AVFoundation
import Combine

class TimelineCollectionViewController: UICollectionViewController {
    private var mediaComposer: MediaComposer
    private var timelineCancellable: AnyCancellable? = nil
    
    private lazy var timeScaleView: TimeScaleView = {
        let timeScaleView = TimeScaleView(mediaComposer)
        return timeScaleView
    }()
    
    init(mediaComposer: MediaComposer) {
        self.mediaComposer = mediaComposer
        let layout = TimelineCollectionViewLayout()
        super.init(collectionViewLayout: layout)
        layout.delegate = self
        collectionView.register(TimelineVideoCollectionViewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timelineCancellable = mediaComposer.$timeline.receive(on: DispatchQueue.main).sink { _ in
            self.collectionView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timelineCancellable?.cancel()
    }
    
    private func setupSubviews() {
        view.addSubview(timeScaleView)
        let timeScaleHeight: CGFloat = 20
        NSLayoutConstraint.activate([
            timeScaleView.topAnchor.constraint(equalTo: view.topAnchor),
            timeScaleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timeScaleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timeScaleView.heightAnchor.constraint(equalToConstant: timeScaleHeight)
        ])
    }
    
    private func getTimeline(track: TimelineTrack, targetSize: CGSize, scale: CGFloat = 1) async -> UIImage? {
        guard let asset = track.assetTrack.asset,
              let (originalNaturalSize, preferredTransform) = try? await track.assetTrack.load(.naturalSize, .preferredTransform) else { return nil }
        
        let transformedNaturalSize = originalNaturalSize.applying(preferredTransform)
        let naturalSize = CGSize(width: abs(transformedNaturalSize.width), height: (transformedNaturalSize.height))
        let frameWidth = targetSize.height * (naturalSize.width / naturalSize.height)
        let framesCount = Int((targetSize.width / frameWidth).rounded(.up))
        
        let frameGap = track.duration.seconds / Double(framesCount)
        
        var times = [CMTime]()
        for frame in 0..<framesCount {
            times.append(CMTime(seconds: frameGap * Double(frame), preferredTimescale: 100))
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        for await result in generator.images(for: times) {
            if case let .success(requestedTime, cgImage, _) = result {
                let index = Int((requestedTime.seconds / frameGap).rounded())
                let uiImage = UIImage(cgImage: cgImage)
                uiImage.draw(in: CGRect(x: frameWidth * CGFloat(index), y: 0, width: frameWidth, height: targetSize.height))
            }
        }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaComposer.timeline.videos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(at: indexPath, type: TimelineVideoCollectionViewCell.self)
        if indexPath.row == 0 {
            cell.imageView.backgroundColor = .blue
        }
        Task {
            let timelineImage = await getTimeline(track: mediaComposer.timeline.videos[indexPath.item],
                                                  targetSize: CGSize(width: widthForItem(at: indexPath),
                                                                     height: 60))
            await MainActor.run {
                cell.imageView.image = timelineImage
            }
        }
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timeScaleView.updateOffset(scrollView.contentOffset.x)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelineCollectionViewController: TimelineCollectionViewLayoutDelegate {
    func widthForItem(at indexPath: IndexPath) -> CGFloat {
        return CGFloat(mediaComposer.timeline.videos[indexPath.item].duration.seconds * 100)
    }
}

