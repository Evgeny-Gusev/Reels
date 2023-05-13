//
//  PlaybackToggleView.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit
import Combine
import AVFoundation

class PlaybackToggleView: UIView {
    enum State: Int {
        case playing = 2 // AVPlayer.TimeControlStatus.playing.rawValue
        case paused = 0 // AVPlayer.TimeControlStatus.paused.rawValue
    }
    
    var state: State = .paused {
        didSet {
            imageView.image = currentImage
            
            let transitionTiming: TimeInterval = 0.2
            let displayTiming: TimeInterval = 0.3
            
            UIView.animate(withDuration: transitionTiming,
                           delay: 0,
                           options: .beginFromCurrentState) { [unowned self] in
                self.alpha = 1
            } completion: { [unowned self] finished in
                guard finished else { return }
                
                UIView.animate(withDuration: transitionTiming,
                               delay: displayTiming,
                               options: .beginFromCurrentState) { [unowned self] in
                    self.alpha = 0
                }
            }
        }
    }
    
    private let playingImage = UIImage(systemName: "play.fill")
    private let pausedImage = UIImage(systemName: "pause.fill")
    private let imageView: UIImageView
    private var playerStatusCancellable: AnyCancellable?
    private var currentImage: UIImage? {
        return state == .paused ? pausedImage : playingImage
    }
    
    init(size: CGFloat) {
        self.imageView = UIImageView()
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        
        imageView.image = currentImage
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .background.withAlphaComponent(0.5)
        layer.cornerRadius = size / 2
        isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func setPlayer(_ player: AVPlayer) {
        playerStatusCancellable?.cancel()
        playerStatusCancellable = player.publisher(for: \.timeControlStatus).sink(receiveValue: { [weak self] playerStatus in
            guard let self,
                  self.state.rawValue != playerStatus.rawValue,
                  playerStatus != .waitingToPlayAtSpecifiedRate,
                  let newState = State(rawValue: playerStatus.rawValue) else { return }
            self.state = newState
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
