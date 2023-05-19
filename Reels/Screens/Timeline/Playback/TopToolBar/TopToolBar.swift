//
//  TopToolBar.swift
//  Reels
//
//  Created by Eugene on 15/5/2023.
//

import UIKit

class TopToolBar: UIView {
    
    weak var delegate: TopToolBarDelegate?
    
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton(configuration: .capsule)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.setTitleColor(.action, for: .normal)
        closeButton.addTarget(self, action: #selector(closePressed), for: .touchUpInside)
        closeButton.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return closeButton
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupSubviews()
    }
    
    private func setupSubviews() {
        addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
        ])
    }
    
    @objc func closePressed() {
        delegate?.closePressed()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol TopToolBarDelegate: AnyObject {
    func closePressed()
}
