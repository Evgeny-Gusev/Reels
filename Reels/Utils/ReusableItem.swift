//
//  ReusableItem.swift
//  Reels
//
//  Created by Eugene on 11/5/2023.
//

import UIKit

protocol ReusableItem {
    static var reuseID: String { get }
}

extension ReusableItem {
    static var reuseID: String {
        return String(describing: self)
    }
}

extension UICollectionView {
    func dequeueCell<Cell: UICollectionViewCell>(at indexPath: IndexPath, type: Cell.Type) -> Cell where Cell: ReusableItem {
        return dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as! Cell
    }
    
    func register<Cell: UICollectionViewCell>(_ type: Cell.Type) where Cell: ReusableItem {
        register(type, forCellWithReuseIdentifier: Cell.reuseID)
    }
}

