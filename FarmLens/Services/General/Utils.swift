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
    
    static func feetToMeters(_ feet: Double) -> Double {
        return 0.3048 * feet
    }
    
    static func convertSpacingFeetToDegrees(_ spacingFeet:Double) -> Double {
        // SpacingFeet / 3280.4 converts feet to kilometers
        // Kilometers / (10000/90) converts kilometers to lat/long distance
        return (spacingFeet / 3280.4) / (10000/90)
    }
}

struct Log: TextOutputStream {
    
    func write(_ string: String) {
        let fm = FileManager.default
        let log = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("log.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
}
