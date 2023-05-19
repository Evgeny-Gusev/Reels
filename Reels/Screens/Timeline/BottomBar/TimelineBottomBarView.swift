//
//  TimelineBottomBarView.swift
//  Reels
//
//  Created by Eugene on 18/5/2023.
//

import UIKit

class TimelineBottomBarView: UIView {
    weak var delegate: TimelineBottomBarViewDelegate?
    
    private lazy var addClipButton: UIButton = {
        let backButton = UIButton(configuration: .capsule)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Add Clip", for: .normal)
        backButton.setTitleColor(.action, for: .normal)
        backButton.addTarget(self, action: #selector(addClipPressed), for: .touchUpInside)
        return backButton
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupSubviews()
    }
    
    private func setupSubviews() {
        let horizontalPadding: CGFloat = 20
        addSubview(addClipButton)
        
        NSLayoutConstraint.activate([
            addClipButton.topAnchor.constraint(equalTo: topAnchor),
            addClipButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            addClipButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding)
        ])
    }
    
    @objc func addClipPressed() {
        delegate?.addClipPressed()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol TimelineBottomBarViewDelegate: AnyObject {
    func addClipPressed()
}
