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
    
    private lazy var bottomBarContainerView: UIView = {
        let bottomBarContainerView = UIView()
        bottomBarContainerView.translatesAutoresizingMaskIntoConstraints = false
        bottomBarContainerView.backgroundColor = .background
        return bottomBarContainerView
    }()
    
    private lazy var bottomSafeAreaCamouflageView: UIView = {
        let bottomSafeAreaCamouflageView = UIView()
        bottomSafeAreaCamouflageView.translatesAutoresizingMaskIntoConstraints = false
        bottomSafeAreaCamouflageView.backgroundColor = .background
        return bottomSafeAreaCamouflageView
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
    
    private lazy var timelineCollectionViewController: TimelineCollectionViewController = {
        let collectionViewController = TimelineCollectionViewController(mediaComposer: mediaComposer)
        collectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        return collectionViewController
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
    
    private func setupViews() {
        addChild(timelineCollectionViewController)
        view.addSubview(timelineCollectionViewController.view)
        timelineCollectionViewController.didMove(toParent: self)
        
        view.addSubview(playbackView)
        view.addSubview(middleToolBarView)
        view.addSubview(bottomBarContainerView)
        view.addSubview(bottomSafeAreaCamouflageView)
        
        let middleBarHeight: CGFloat = 40
        let totalHeight = availableScreenHeight
        let collectionViewHeight = totalHeight * (1 - playbackCollapsedMultiplier) - middleBarHeight
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
            
            bottomSafeAreaCamouflageView.topAnchor.constraint(equalTo: bottomBarContainerView.bottomAnchor),
            bottomSafeAreaCamouflageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSafeAreaCamouflageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSafeAreaCamouflageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            middleToolBarView.topAnchor.constraint(equalTo: playbackView.bottomAnchor),
            middleToolBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            middleToolBarView.bottomAnchor.constraint(equalTo: timelineCollectionViewController.view.topAnchor),
            middleToolBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            middleToolBarView.heightAnchor.constraint(equalToConstant: middleBarHeight),
            
            timelineCollectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timelineCollectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineCollectionViewController.view.heightAnchor.constraint(equalToConstant: collectionViewHeight)
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
