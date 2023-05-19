//
//  TimelineViewController.swift
//  Reels
//
//  Created by Eugene on 15/5/2023.
//

import UIKit
import Combine
import AVFoundation

class TimelineViewController: UIViewController {
    
    enum State {
        case fullscreenPreview
        case timelineOverview
    }
    
    private let mediaComposer: MediaComposer
    private var timelineCancellable: AnyCancellable? = nil
    private weak var coordinator: (any PlaybackCoordinator)?
    private var playbackHeightConstraint: NSLayoutConstraint!
    private let bottomBarHeight: CGFloat = 40
    private let playbackCollapsedMultiplier: CGFloat = 0.5
    private var state: State = .fullscreenPreview {
        didSet {
            if state != oldValue {
                updateBottomBar()
                animateStateChange()
                playbackView.setOverlaysHidden(state == .timelineOverview)
            }
        }
    }
    
    private lazy var playbackView: PlaybackView = {
        let playbackView = PlaybackView(mediaComposer)
        playbackView.delegate = self
        return playbackView
    }()
    
    private lazy var timeScaleView: TimeScaleView = {
        let timeScaleView = TimeScaleView(mediaComposer)
        return timeScaleView
    }()
    
    private lazy var bottomBarContainerView: UIView = {
        let bottomBarContainerView = UIView()
        bottomBarContainerView.translatesAutoresizingMaskIntoConstraints = false
        bottomBarContainerView.backgroundColor = .background
        return bottomBarContainerView
    }()
    
    private lazy var playbackBottomBarView: PlaybackBottomBarView = {
        let playbackBottomBarView = PlaybackBottomBarView()
        playbackBottomBarView.delegate = self
        return playbackBottomBarView
    }()
    
    private lazy var timelineBottomBarView: TimelineBottomBarView = {
       let timelineBottomBarView = TimelineBottomBarView()
        timelineBottomBarView.delegate = self
        return timelineBottomBarView
    }()
    
    private lazy var middleToolBarView: MiddleToolBarView = {
        let middleToolBarView = MiddleToolBarView(mediaComposer)
        middleToolBarView.delegate = self
        return middleToolBarView
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = TimelineCollectionViewLayout()
        layout.delegate = self
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(TimelineVideoCollectionViewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
        return collectionView
    }()
    
    init(_ mediaComposer: MediaComposer, coordinator: any PlaybackCoordinator) {
        self.mediaComposer = mediaComposer
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
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
    
    private func setupViews() {
        view.addSubview(playbackView)
        view.addSubview(timeScaleView)
        view.addSubview(collectionView)
        view.addSubview(middleToolBarView)
        view.addSubview(bottomBarContainerView)
        
        let middleBarHeight: CGFloat = 40
        let timeScaleHeight: CGFloat = 20
        let totalHeight = availableScreenHeight
        let collectionViewHeight = totalHeight * (1 - playbackCollapsedMultiplier) - middleBarHeight - timeScaleHeight
        let playbackMultiplier: CGFloat = state == .fullscreenPreview ? 1 : playbackCollapsedMultiplier
        
        playbackHeightConstraint = playbackView.heightAnchor.constraint(equalToConstant: totalHeight * playbackMultiplier)
        
        NSLayoutConstraint.activate([
            playbackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playbackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playbackHeightConstraint,
            playbackView.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            bottomBarContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBarContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBarContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBarContainerView.heightAnchor.constraint(equalToConstant: bottomBarHeight),
            
            middleToolBarView.topAnchor.constraint(equalTo: playbackView.bottomAnchor),
            middleToolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            middleToolBarView.bottomAnchor.constraint(equalTo: timeScaleView.topAnchor),
            middleToolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            middleToolBarView.heightAnchor.constraint(equalToConstant: middleBarHeight),
            
            timeScaleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timeScaleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timeScaleView.heightAnchor.constraint(equalToConstant: timeScaleHeight),
            
            collectionView.topAnchor.constraint(equalTo: timeScaleView.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: collectionViewHeight)
        ])
        
        updateBottomBar()
    }
    
    private var availableScreenHeight: CGFloat {
        return (navigationController?.view.safeAreaLayoutGuide.layoutFrame.size.height ?? view.safeAreaLayoutGuide.layoutFrame.size.height) - bottomBarHeight
    }
    
    private func updateBottomBar() {
        bottomBarContainerView.subviews.forEach { $0.removeFromSuperview() }
        let bottomBar: UIView
        switch state {
        case .fullscreenPreview:
            bottomBar = playbackBottomBarView
        case .timelineOverview:
            bottomBar = timelineBottomBarView
        }
        bottomBarContainerView.addSubview(bottomBar)
        NSLayoutConstraint.activate([
            bottomBar.topAnchor.constraint(equalTo: bottomBarContainerView.topAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: bottomBarContainerView.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomBarContainerView.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: bottomBarContainerView.leadingAnchor)
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
    
    private func animateStateChange() {
        let multiplier: CGFloat = state == .fullscreenPreview ? 1 : playbackCollapsedMultiplier
        playbackHeightConstraint.constant = availableScreenHeight * multiplier
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelineViewController: PlaybackBottomBarViewDelegate {
    func editPressed() {
        state = .timelineOverview
    }
    
    func proceedPressed() {
        // TODO
    }
}

extension TimelineViewController: TimelineBottomBarViewDelegate {
    func addClipPressed() {
        coordinator?.pickAdditionalAsset { assets in
            self.mediaComposer.addAssets(assets)
        }
    }
}

extension TimelineViewController: MiddleToolBarViewDelegate {
    func expandPlayback() {
        state = .fullscreenPreview
    }
}

extension TimelineViewController: PlaybackViewDelegate {
    func playbackPressed() {
        switch state {
        case .fullscreenPreview:
            mediaComposer.togglePlayback()
        case .timelineOverview:
            state = .fullscreenPreview
        }
    }
    
    func closePressed() {
        navigationController?.popViewController(animated: true)
    }
}

extension TimelineViewController: TimelineCollectionViewLayoutDelegate {
    func widthForItem(at indexPath: IndexPath) -> CGFloat {
        return CGFloat(mediaComposer.timeline.videos[indexPath.item].duration.seconds * 100)
    }
}

extension TimelineViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaComposer.timeline.videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
}

extension TimelineViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timeScaleView.updateOffset(scrollView.contentOffset.x)
    }
}

class TimelineVideoCollectionViewCell: UICollectionViewCell, ReusableItem {
    @UseAutoLayout var imageView = UIImageView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        addSubview(imageView)
        imageView.backgroundColor = .red
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }
}
