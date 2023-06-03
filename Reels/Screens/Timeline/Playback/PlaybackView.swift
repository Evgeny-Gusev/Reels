//
//  PlaybackView.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit
import AVKit
import Combine

class PlaybackView: UIView {
    weak var delegate: PlaybackViewDelegate?
    
    private let mediaComposer: MediaComposer
    private let playerViewBoundsKeyPath = NSExpression(forKeyPath: \PlaybackView.playerView.bounds).keyPath
    
    @objc private lazy var playerView: UIView = {
        let playerView = UIView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        return playerView
    }()
    
    private lazy var topToolBar: TopToolBar = {
        let topToolBar = TopToolBar()
        topToolBar.delegate = self
        return topToolBar
    }()
    
    private lazy var playbackToggle: PlaybackToggleView = {
        let playbackToggle = PlaybackToggleView(size: 60, mediaComposer: mediaComposer)
        return playbackToggle
    }()
    
    private lazy var playProgressBarView = {
       return PlayProgressBarView(mediaComposer: mediaComposer)
    }()
    
    init(_ mediaComposer: MediaComposer) {
        self.mediaComposer = mediaComposer
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupSubviews()
        let playerLayer = AVPlayerLayer(player: mediaComposer.player)
        playerView.layer.addSublayer(playerLayer)
        playerLayer.frame = playerView.bounds
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playerViewTapped))
        playerView.addGestureRecognizer(tapGestureRecognizer)
        
        addObserver(self, forKeyPath: playerViewBoundsKeyPath, options: .new, context: nil)
    }
    
    private func setupSubviews() {
        addSubview(playerView)
        addSubview(playbackToggle)
        addSubview(playProgressBarView)
        addSubview(topToolBar)
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            playbackToggle.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            playbackToggle.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),

            playProgressBarView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            playProgressBarView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -5),
            playProgressBarView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            
            topToolBar.topAnchor.constraint(equalTo: topAnchor),
            topToolBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topToolBar.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == playerViewBoundsKeyPath {
            playerView.layer.sublayers?.first?.frame = playerView.bounds
        }
    }
    
    func setOverlaysHidden(_ isHidden: Bool) {
        playbackToggle.isHidden = isHidden
        playProgressBarView.isHidden = isHidden
        topToolBar.isHidden = isHidden
    }
    
    @objc private func playerViewTapped() {
        delegate?.playbackPressed()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlaybackView: TopToolBarDelegate {
    func closePressed() {
        delegate?.closePressed()
    }
}

protocol PlaybackViewDelegate: AnyObject {
    func playbackPressed()
    func closePressed()
}
