//
//  MiddleToolBarView.swift
//  Reels
//
//  Created by Eugene on 18/5/2023.
//

import UIKit
import AVFoundation
import Combine

class MiddleToolBarView: UIView {
    static let buttonImageSize = CGSize(width: 15, height: 15)
    weak var delegate: MiddleToolBarViewDelegate?
    weak var mediaComposer: MediaComposer?
    
    private let playImage = UIImage(systemName: "play.fill")?
        .resize(to: MiddleToolBarView.buttonImageSize)
        .withRenderingMode(.alwaysTemplate)
    private let pauseImage = UIImage(systemName: "pause.fill")?
        .resize(to: MiddleToolBarView.buttonImageSize)
        .withRenderingMode(.alwaysTemplate)
    private var playerCancellable: AnyCancellable?
    private var playerStatusCancellable: AnyCancellable?
    private var timeObserverToken: Any?
    
    private lazy var toggleButton: UIButton = {
        let toggleButton = UIButton(configuration: .capsule)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.setImage(playImage, for: .normal)
        toggleButton.tintColor = .action
        toggleButton.addTarget(self, action: #selector(togglePressed), for: .touchUpInside)
        return toggleButton
    }()
    
    private lazy var expandButton: UIButton = {
        let expandButton = UIButton(configuration: .capsule)
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        let chevronImage = UIImage(systemName: "chevron.down")
        expandButton.setImage(chevronImage, for: .normal)
        expandButton.addTarget(self, action: #selector(expandPressed), for: .touchUpInside)
        return expandButton
    }()
    
    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .white
        timeLabel.text = "0:00"
        return timeLabel
    }()
    
    private lazy var bottomSeparatorView: UIView = {
        let bottomSeparatorView = UIView()
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorView.backgroundColor = .gray
        return bottomSeparatorView
    }()

    init(_ mediaComposer: MediaComposer) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        self.mediaComposer = mediaComposer
        setupSubviews()
        
        playerCancellable = mediaComposer.$player
            .compactMap { $0 }
            .sink { [weak self] player in
                self?.addPeriodicTimeObserver(for: player)
                self?.playerStatusCancellable?.cancel()
                self?.playerStatusCancellable = player
                    .publisher(for: \.timeControlStatus)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] playerStatus in
                        let image = playerStatus == .playing ? self?.pauseImage : self?.playImage
                        self?.toggleButton.setImage(image, for: .normal)
                    })
            }
    }
    
    private func setupSubviews() {
        let horizontalPadding: CGFloat = 20
        let verticalPadding: CGFloat = 5
        addSubview(toggleButton)
        addSubview(expandButton)
        addSubview(timeLabel)
        addSubview(bottomSeparatorView)
        
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: topAnchor,
                                              constant: verticalPadding),
            toggleButton.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                 constant: -verticalPadding),
            toggleButton.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                  constant: horizontalPadding),
            toggleButton.widthAnchor.constraint(equalTo: toggleButton.heightAnchor),
        
            expandButton.topAnchor.constraint(equalTo: topAnchor,
                                              constant: verticalPadding),
            expandButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                   constant: -horizontalPadding),
            expandButton.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                constant: -verticalPadding),
            expandButton.widthAnchor.constraint(equalTo: expandButton.heightAnchor),
            
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            bottomSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    private func addPeriodicTimeObserver(for player: AVPlayer) {
        let fps = 60.0
        let time = CMTime(seconds: 1.0 / fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            guard let self else { return }
            let roundedTime = Int(time.seconds.rounded())
            let minutes = roundedTime / 60
            let seconds = roundedTime % 60
            let secondsString = "\(seconds > 9 ? "" : "0")\(seconds)"
            self.timeLabel.text = "\(minutes):\(secondsString)"
        }
    }
    
    @objc func togglePressed() {
        mediaComposer?.togglePlayback()
    }
    
    @objc func expandPressed() {
        delegate?.expandPlayback()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MiddleToolBarViewDelegate: AnyObject {
    func expandPlayback()
}
