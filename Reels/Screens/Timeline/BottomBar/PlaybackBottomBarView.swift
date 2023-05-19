//
//  PlaybackBottomBarView.swift
//  Reels
//
//  Created by Eugene on 18/5/2023.
//

import UIKit

class PlaybackBottomBarView: UIView {
    weak var delegate: PlaybackBottomBarViewDelegate?
    
    private lazy var editButton: UIButton = {
        let backButton = UIButton(configuration: .capsule)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Edit", for: .normal)
        backButton.setTitleColor(.action, for: .normal)
        backButton.addTarget(self, action: #selector(editPressed), for: .touchUpInside)
        return backButton
    }()
    
    private lazy var nextButton: UIButton = {
        let backButton = UIButton(configuration: .capsule)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Next", for: .normal)
        backButton.setTitleColor(.action, for: .normal)
        backButton.addTarget(self, action: #selector(nextPressed), for: .touchUpInside)
        return backButton
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupSubviews()
    }
    
    private func setupSubviews() {
        let horizontalPadding: CGFloat = 20
        
        addSubview(editButton)
        addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            editButton.topAnchor.constraint(equalTo: topAnchor),
            editButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            editButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            
            nextButton.topAnchor.constraint(equalTo: topAnchor),
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            nextButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    @objc func editPressed() {
        delegate?.editPressed()
    }
    
    @objc func nextPressed() {
        delegate?.proceedPressed()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol PlaybackBottomBarViewDelegate: AnyObject {
    func editPressed()
    func proceedPressed()
}
