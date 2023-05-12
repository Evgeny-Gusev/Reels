//
//  UIEdgeInsets.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit

extension UIEdgeInsets {
    func inverted() -> UIEdgeInsets {
        return UIEdgeInsets(top: -top,
                            left: -left,
                            bottom: -bottom,
                            right: -right)
    }
}
