//
//  TimelineVideoCollectionViewCell.swift
//  Reels
//
//  Created by Eugene on 19/5/2023.
//

import UIKit

class TimelineVideoCollectionViewCell: UICollectionViewCell, ReusableItem {
    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderWidth = 4
            } else {
                layer.borderWidth = 0
            }
            rightDragHandleView.isHidden = !isSelected
        }
    }
    
    @UseAutoLayout var imageView = UIImageView()
    lazy var rightDragHandleView: UIView = {
        let rightDragHandleView = UIView()
        rightDragHandleView.translatesAutoresizingMaskIntoConstraints = false
        rightDragHandleView.backgroundColor = .yellow
        rightDragHandleView.isHidden = true
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        rightDragHandleView.addGestureRecognizer(panGestureRecognizer)
        return rightDragHandleView
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        layer.borderColor = UIColor.red.cgColor
        addSubview(imageView)
        addSubview(rightDragHandleView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            rightDragHandleView.topAnchor.constraint(equalTo: topAnchor),
            rightDragHandleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightDragHandleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightDragHandleView.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let locationX = gesture.location(in: superview).x
        print(locationX)
    }
}

