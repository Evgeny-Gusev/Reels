//
//  PlaybackViewController.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit
import AVKit
import Combine

class PlaybackViewController: UIViewController {
    private let composer: MediaComposer
    private let queuePlayer: AVQueuePlayer
    private let looper: AVPlayerLooper
    
    private lazy var playerView: UIView = {
        let playerView = UIView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.backgroundColor = .background
        playerView.layer.addSublayer(AVPlayerLayer(player: queuePlayer))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePLayback))
        playerView.addGestureRecognizer(tapGestureRecognizer)
        return playerView
    }()
    
    private lazy var bottomToolBar: UIView = {
        let verticalPadding: CGFloat = 10
        let horizontalPadding: CGFloat = 20
        let bottomToolBar = UIView()
        bottomToolBar.translatesAutoresizingMaskIntoConstraints = false
        bottomToolBar.backgroundColor = .background
        bottomToolBar.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: bottomToolBar.topAnchor, constant: verticalPadding),
            backButton.bottomAnchor.constraint(equalTo: bottomToolBar.bottomAnchor, constant: -verticalPadding),
            backButton.leadingAnchor.constraint(equalTo: bottomToolBar.leadingAnchor, constant: horizontalPadding)
        ])
        return bottomToolBar
    }()
    
    private lazy var backButton: UIButton = {
        let backButton = UIButton(configuration: .capsule)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.action, for: .normal)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return backButton
    }()
    
    private lazy var playbackToggle: PlaybackToggleView = {
        return PlaybackToggleView(size: 60, player: queuePlayer)
    }()
    
    private lazy var timelineControllView: TimelineControlView = {
       return TimelineControlView(player: queuePlayer)
    }()
    
    init(composer: MediaComposer) {
        self.composer = composer
        self.queuePlayer = AVQueuePlayer()
        self.looper = AVPlayerLooper(player: self.queuePlayer, templateItem: composer.playerItem)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queuePlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queuePlayer.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerView.layer.sublayers?.forEach { $0.frame = playerView.bounds }
    }
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func togglePLayback() {
        queuePlayer.rate == 0 ? queuePlayer.play() : queuePlayer.pause()
    }
    
    private func setupViews() {
        view.addSubview(playerView)
        view.addSubview(bottomToolBar)
        view.addSubview(playbackToggle)
        view.addSubview(timelineControllView)
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomToolBar.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            bottomToolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            playbackToggle.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            playbackToggle.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            
            timelineControllView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            timelineControllView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
            timelineControllView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor)
        ])
    }
}
