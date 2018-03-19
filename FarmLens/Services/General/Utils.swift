//
//  Utils.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Foundation

class Utils {
    static func metersToFeet(_ meters: Double) -> Double {
        return 3.28084 * meters
    }
    
    static func convertSpacingFeetToDegrees(_ spacingFeet:Double) -> Double {
        // SpacingFeet / 3280.4 converts feet to kilometers
        // Kilometers / (10000/90) converts kilometers to lat/long distance
        return (spacingFeet / 3280.4) / (10000/90)
    }
}
