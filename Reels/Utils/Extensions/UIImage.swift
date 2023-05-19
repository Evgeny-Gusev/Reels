//
//  UIImage.swift
//  Reels
//
//  Created by Eugene on 18/5/2023.
//

import UIKit

extension UIImage {
    func resize(to newSize: CGSize) -> UIImage {
        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
            
        return image.withRenderingMode(renderingMode)
    }
}
