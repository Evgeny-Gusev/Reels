//
//  UIButtonConfiguration.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit

extension UIButton.Configuration {
    static let capsule: UIButton.Configuration = {
        var configuration = UIButton.Configuration.tinted()
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = .action
        configuration.baseBackgroundColor = .action
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        return configuration
    }()
}
