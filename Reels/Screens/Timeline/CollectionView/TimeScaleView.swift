//
//  TimeScaleView.swift
//  Reels
//
//  Created by Eugene on 16/5/2023.
//

import UIKit
import Combine

class TimeScaleView: UIView {
    
    private let font = CGFont(UIFont.systemFont(ofSize: 12).fontName as CFString)
    private var offset: CGFloat = 0
    private var timelineCancellable: AnyCancellable?
    
    init(_ mediaComposer: MediaComposer) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        timelineCancellable = mediaComposer.$timeline.receive(on: DispatchQueue.main).sink { [weak self] timeline in
            self?.createTimeLayer(timeline.totalDuration.seconds)
        }
    }
    
    func updateOffset(_ newOffset: CGFloat) {
        offset = newOffset
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.sublayers?.first?.frame.origin.x = -offset
        CATransaction.commit()
    }
    
    private func createTimeLayer(_ duration: Double, _ pixelsPerSecond: CGFloat = 100) {
        layer.removeSublayers()
        let timeLayer = CALayer()
        layer.addSublayer(timeLayer)
        timeLayer.frame = CGRect(x: -offset,
                                 y: 0,
                                 width: CGFloat(duration) * pixelsPerSecond,
                                 height: bounds.height)
        
        for time in 0..<Int(duration.rounded(.up)) {
            let indicatorLayer: CALayer
            let xPosition = CGFloat(time) * pixelsPerSecond
            if time % 2 == 0 {
                indicatorLayer = CALayer()
                indicatorLayer.backgroundColor = UIColor.gray.cgColor
                indicatorLayer.frame = CGRect(x: xPosition, y: 8, width: 4, height: 4)
                indicatorLayer.cornerRadius = 2
            } else {
                let textLayer = CATextLayer()
                textLayer.font = font
                textLayer.fontSize = 12
                textLayer.foregroundColor = UIColor.white.cgColor
                textLayer.string = "\(time)s."
                textLayer.alignmentMode = .left
                textLayer.frame = CGRect(x: xPosition, y: 3, width: 20, height: 12)
                indicatorLayer = textLayer
            }
            indicatorLayer.contentsScale = window?.screen.scale ?? 1
            timeLayer.addSublayer(indicatorLayer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CALayer {
    func removeSublayers() {
        sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}
