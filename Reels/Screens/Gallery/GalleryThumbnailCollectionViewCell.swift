//
//  GalleryThumbnailCollectionViewCell.swift
//  Reels
//
//  Created by Eugene on 11/5/2023.
//

import UIKit

class GalleryThumbnailCollectionViewCell: UICollectionViewCell, ReusableItem {
    @UseAutoLayout var imageView = UIImageView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }
}
