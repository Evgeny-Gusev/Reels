//
//  TimelineControlView.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit
import AVFoundation
import Combine

class TimelineControlView: UIView {
    private enum State {
        case expanded, collapsed
    }
    
    private var duration: CMTime? {
        didSet { updateTimeline() }
    }
    private var time: CMTime? {
        didSet {
            updateTimeline()
            updateTime()
        }
    }
    private var state: State = .collapsed {
        didSet {
            guard oldValue != state else { return }
            animateTransitionToCurrentState()
        }
    }
    private var timelineTrailingConstraint: NSLayoutConstraint!
    private var timelineWidthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!
    private var playerDurationCancellable: AnyCancellable?
    private var playerStatusCancellable: AnyCancellable?
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private let timelineHeight: CGFloat = 4
    private let expandedHeight: CGFloat = 30
    private let indicatorViewSize: CGFloat = 8
    private let timelineBacgroundBoundsKeyPath = NSExpression(forKeyPath: \TimelineControlView.timelineBackgroundView.bounds).keyPath
    
    @objc private lazy var timelineBackgroundView: UIView = {
        let timelineBackgroundView = UIView()
        timelineBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        timelineBackgroundView.backgroundColor = .white.withAlphaComponent(0.5)
        timelineBackgroundView.addSubview(timelineView)
        timelineWidthConstraint = timelineView.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            timelineView.topAnchor.constraint(equalTo: timelineBackgroundView.topAnchor),
            timelineView.bottomAnchor.constraint(equalTo: timelineBackgroundView.bottomAnchor),
            timelineView.leadingAnchor.constraint(equalTo: timelineBackgroundView.leadingAnchor),
            timelineWidthConstraint
        ])
        timelineBackgroundView.layer.cornerRadius = timelineHeight / 2
        timelineBackgroundView.clipsToBounds = true
        return timelineBackgroundView
    }()
    
    private lazy var timelineView: UIView = {
        let timelineView = UIView()
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        timelineView.backgroundColor = .white
        return timelineView
    }()
    
    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .white
        timeLabel.text = "0:00"
        return timeLabel
    }()
    
    private lazy var indicatorView: UIView = {
        let indicatorView = ViewWithTouchSize()
        indicatorView.touchAreaPadding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.backgroundColor = .white
        indicatorView.layer.cornerRadius = indicatorViewSize / 2
        NSLayoutConstraint.activate([
            indicatorView.heightAnchor.constraint(equalToConstant: indicatorViewSize),
            indicatorView.widthAnchor.constraint(equalToConstant: indicatorViewSize)
        ])
        return indicatorView
    }()
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupSubviews()
        addObserver(self, forKeyPath: timelineBacgroundBoundsKeyPath, options: .new, context: nil)
    }
    
    func setPlayer(_ player: AVPlayer) {
        playerStatusCancellable?.cancel()
        playerDurationCancellable?.cancel()
        self.player = player
        duration = nil
        
        Task {
            guard let duration = try? await player.currentItem?.asset.load(.duration) else { return }
            self.duration = duration
            self.playerDurationCancellable = player.publisher(for: \.currentItem?.duration).sink(receiveValue: { [weak self] duration in
                self?.duration = duration
                self?.addPeriodicTimeObserver(for: player)
            })
        }
        playerStatusCancellable = player.publisher(for: \.timeControlStatus).sink(receiveValue: { [weak self] playerStatus in
            guard let self else { return }
            switch playerStatus {
            case .playing:
                self.state = .collapsed
            case .paused:
                self.state = .expanded
            default:
                break
            }
        })
    }
    
    private func setupSubviews() {
        addSubview(timelineBackgroundView)
        addSubview(timeLabel)
        addSubview(indicatorView)
        
        indicatorView.alpha = 0
        indicatorView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        
        timelineTrailingConstraint = timelineBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor)
        heightConstraint = heightAnchor.constraint(equalToConstant: timelineHeight)
        NSLayoutConstraint.activate([
            timelineBackgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            timelineTrailingConstraint,
            heightConstraint,
            timelineBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            timelineBackgroundView.heightAnchor.constraint(equalToConstant: timelineHeight),
            timeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: timelineBackgroundView.trailingAnchor, constant: 10),
            indicatorView.centerYAnchor.constraint(equalTo: timelineBackgroundView.centerYAnchor),
            indicatorView.centerXAnchor.constraint(equalTo: timelineView.trailingAnchor, constant: -indicatorViewSize / 2)
        ])
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == timelineBacgroundBoundsKeyPath {
            updateTimeline()
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let duration, let player else { return }
        let locationX = gesture.location(in: timelineBackgroundView).x
        let relativePosition: Double = max(0, min(1, locationX / timelineBackgroundView.bounds.width))
        player.seek(to: duration * relativePosition, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func addPeriodicTimeObserver(for player: AVPlayer) {
        let fps = 60.0
        let time = CMTime(seconds: 1.0 / fps, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            self?.time = time
        }
    }

    private func updateTimeline() {
        guard let duration, duration.seconds > 0, let time else {
            timelineWidthConstraint.constant = 0
            return
        }
        let progress = time.seconds / duration.seconds
        timelineWidthConstraint.constant = timelineBackgroundView.bounds.width * progress
    }
    
    private func updateTime() {
        guard let time, let duration, state == .expanded else { return }
        let remaining = Int((duration.seconds - time.seconds).rounded())
        let minutes = remaining / 60
        let seconds = remaining % 60
        let secondsString = "\(seconds > 9 ? "" : "0")\(seconds)"
        timeLabel.text = "\(minutes):\(secondsString)"
    }
    
    private func animateTransitionToCurrentState() {
        let height: CGFloat = state == .collapsed ? timelineHeight : 30
        heightConstraint.constant = height
        timelineTrailingConstraint.constant = state == .collapsed ? 0 : -(timeLabel.frame.width + 20)
        
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .beginFromCurrentState) { [unowned self] in
            self.indicatorView.alpha = self.state == .expanded ? 1 : 0
            self.superview?.layoutIfNeeded()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
