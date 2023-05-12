//
//  CMTime.swift
//  Reels
//
//  Created by Eugene on 12/5/2023.
//

import CoreMedia

func * (time: CMTime, multiplier: Double) -> CMTime {
    return CMTimeMultiplyByFloat64(time, multiplier: Float64(multiplier))
}
