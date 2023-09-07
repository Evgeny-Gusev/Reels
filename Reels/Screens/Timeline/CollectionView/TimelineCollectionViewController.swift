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
    private var timelineCancellable: AnyCancellable?
    private var playerStatusCancellable: AnyCancellable?
    private var timeObserverToken: Any?
    private let timelineImageProvider = TimelineImageProvider()
    private var isDragging = false {
        didSet {
            if isDragging == oldValue { return }
            if isDragging {
                mediaComposer.player.pause()
                if let timeObserverToken {
                    mediaComposer.player.removeTimeObserver(timeObserverToken)
                    self.timeObserverToken = nil
                }
            } else {
                observePlayTime(mediaComposer.player)
            }
        }
    }
    private lazy var collectionViewHorizontalInset: CGFloat = view.safeAreaLayoutGuide.layoutFrame.size.width / 2
    
    private lazy var timeScaleView: TimeScaleView = {
        let timeScaleView = TimeScaleView(mediaComposer)
        return timeScaleView
    }()
    
    private lazy var timeIndicatorView: UIView = {
       let timeIndicatorView = UIView()
        timeIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        timeIndicatorView.backgroundColor = .gray
        return timeIndicatorView
    }()
        
    init(mediaComposer: MediaComposer) {
        self.mediaComposer = mediaComposer
        let layout = TimelineCollectionViewLayout()
        super.init(collectionViewLayout: layout)
        layout.delegate = self
        collectionView.register(TimelineVideoCollectionViewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = false
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timelineCancellable = mediaComposer.timeline.publisher(for: \.totalDuration)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.collectionView.reloadData()
            })
        timeObserverToken = nil
        observePlayTime(mediaComposer.player)
        playerStatusCancellable?.cancel()
        playerStatusCancellable = mediaComposer.player
            .publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] playerStatus in
                guard let self, playerStatus == .playing, self.isDragging else { return }
                self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
            })
        
        collectionView.contentInset = UIEdgeInsets(top: 100, left: collectionViewHorizontalInset, bottom: 100, right: collectionViewHorizontalInset)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timelineCancellable?.cancel()
        playerStatusCancellable?.cancel()
    }
    
    private func setupSubviews() {
        view.addSubview(timeScaleView)
        view.addSubview(timeIndicatorView)
        let timeScaleHeight: CGFloat = 20
        NSLayoutConstraint.activate([
            timeScaleView.topAnchor.constraint(equalTo: view.topAnchor),
            timeScaleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timeScaleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timeScaleView.heightAnchor.constraint(equalToConstant: timeScaleHeight),
            
            timeIndicatorView.topAnchor.constraint(equalTo: timeScaleView.bottomAnchor),
            timeIndicatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            timeIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeIndicatorView.widthAnchor.constraint(equalToConstant: 2)
        ])
    }
    
    private func observePlayTime(_ player: AVPlayer?) {
        let fps = 60.0
        let time = CMTime(seconds: 1.0 / fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            guard let self else { return }
            self.collectionView.setContentOffset(CGPoint(x: -self.collectionViewHorizontalInset + CGFloat(time.seconds) * 100, y: -100), animated: false)
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaComposer.timeline.videos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(at: indexPath, type: TimelineVideoCollectionViewCell.self)
        Task {
            let timelineImage = await timelineImageProvider.getTimeline(track: mediaComposer.timeline.videos[indexPath.item],
                                                                        indexPath: indexPath,
                                                                        targetSize: CGSize(width: widthForItem(at: indexPath),
                                                                                           height: 60))
            await MainActor.run {
                cell.imageView.image = timelineImage
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected")
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return false
        }
        if cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: false)
            return false
        } else {
            return true
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timeScaleView.updateOffset(scrollView.contentOffset.x)
        if isDragging {
            let seconds = min(
                max(CGFloat.zero, scrollView.contentOffset.x + collectionViewHorizontalInset) / 100,
                mediaComposer.timeline.totalDuration.seconds
            )
            let targetTime = CMTime(seconds: Double(seconds), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let tolerance = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            mediaComposer.player.seek(to: targetTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragging = true
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDragging = false
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isDragging = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelineCollectionViewController: TimelineCollectionViewLayoutDelegate {
    func widthForItem(at indexPath: IndexPath) -> CGFloat {
        var extra: CGFloat = 0
        if let cell = collectionView.cellForItem(at: indexPath) as? TimelineVideoCollectionViewCell, cell.isSelected {
            extra = 30
        }
        return CGFloat(mediaComposer.timeline.videos[indexPath.item].timeRange.duration.seconds * 100) + extra
    }
}
