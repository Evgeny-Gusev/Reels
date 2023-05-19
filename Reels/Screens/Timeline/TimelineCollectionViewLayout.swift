//
//  TimelineCollectionViewLayout.swift
//  Reels
//
//  Created by Eugene on 15/5/2023.
//

import UIKit

class TimelineCollectionViewLayout: UICollectionViewLayout {
    
    private let rowHeight: CGFloat = 60
    private var cache = [IndexPath: UICollectionViewLayoutAttributes]()
    weak var delegate: TimelineCollectionViewLayoutDelegate? {
        didSet {
            invalidateLayout()
        }
    }
    private var contentSize: CGSize = .zero
    
    override func prepare() {
        cache.removeAll()
        contentSize = .zero
        
        guard let collectionView, let dataSource = collectionView.dataSource, let delegate else { return }
        
        var maxSectionWidth: CGFloat = 0
        let sections = dataSource.numberOfSections?(in: collectionView) ?? 1
        
        for section in 0..<sections {
            var previousWidth: CGFloat = 0
            
            for item in 0..<(dataSource.collectionView(collectionView, numberOfItemsInSection: section)) {
                let indexPath = IndexPath(item: item,
                                          section: section)
                let size = CGSize(width: delegate.widthForItem(at: indexPath),
                                  height: rowHeight)
                let origin = CGPoint(x: previousWidth,
                                     y: CGFloat(section) * rowHeight)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(origin: origin,
                                          size: size)
                cache[indexPath] = attributes
                previousWidth += size.width
            }
            
            maxSectionWidth = max(maxSectionWidth, previousWidth)
        }
        
        contentSize = CGSize(width: maxSectionWidth,
                             height: rowHeight * CGFloat(sections))
    }
    
    override var collectionViewContentSize: CGSize {
        contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.values.filter { $0.frame.intersects(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath]
    }
}

protocol TimelineCollectionViewLayoutDelegate: AnyObject {
    func widthForItem(at indexPath: IndexPath) -> CGFloat
}
