//
//  ViewWithTouchSize.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import UIKit

class ViewWithTouchSize: UIView {
    var touchAreaPadding: UIEdgeInsets?
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let insets = touchAreaPadding else {
            return super.point(inside: point, with: event)
        }
        let rect = bounds.inset(by: insets.inverted())
        return rect.contains(point)
    }
}
