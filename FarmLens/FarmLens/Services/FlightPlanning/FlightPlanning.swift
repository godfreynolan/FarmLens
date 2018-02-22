//
//  FlightPlanning.swift
//  FarmLens
//
//  Created by Ian Timmis on 2/22/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import MapKit
import UIKit

class FlightPlanning {
    
    private var boundingArea: MKPolygon
    
    init(polygon: MKPolygon) {
        self.boundingArea = polygon
    }
    
    func isCoordinateInBoundingArea(coordinate: CLLocationCoordinate2D) -> Bool {
        let renderer = MKPolygonRenderer(polygon: self.boundingArea)
        let position = renderer.point(for: MKMapPoint(x: coordinate.longitude, y: coordinate.latitude))
        
        return renderer.path.contains(position)
    }
    
    func convertSpacingFeetToDegrees(_ spacingFeet:Double) -> Double {
        // SpacingFeet / 3280.4 converts feet to kilometers
        // Kilometers / (10000/90) converts kilometers to lat/long distance
        return (spacingFeet / 3280.4) / (10000/90)
    }
    
    
    func calculateFlightPlan(spacingFeet:Double) -> [CLLocationCoordinate2D] {
        
        // Steps:
        // 1. Get overlaying rectangle
        // 2. Create a point at each {spacingFeet} interval
        // 3. Remove all points outside the original polygon
        // 4. Reorder points to scan properly.
        
        // Step 1. Get overlaying rectangle
        let mapRect = self.boundingArea.boundingMapRect
        
        let maxX = MKMapRectGetMaxX(mapRect)
        let maxY = MKMapRectGetMaxY(mapRect)
        let minX = MKMapRectGetMinX(mapRect)
        let minY = MKMapRectGetMinY(mapRect)
        
        var x = minX
        var y = minY
        let increment = convertSpacingFeetToDegrees(spacingFeet)
        
        // Step 2. Create a point at each {spacingFeet} interval
        var locations:[CLLocationCoordinate2D] = []
        
        while x <= maxX {
            while y <= maxY {
                y = y + increment
                locations.append(CLLocationCoordinate2D(latitude: y, longitude: x))
            }
            y = minY
            x = x + increment
            locations.append(CLLocationCoordinate2D(latitude: y, longitude: x))
        }
        
        // Step 3. Remove all points outside the original polygon
        let locationsInPolygon = locations.filter{ location in isCoordinateInBoundingArea(coordinate: location) == true }
        
        // Step 4. Reorder points to scan properly
        var lines:[[CLLocationCoordinate2D]] = []
        var currentLine:[CLLocationCoordinate2D] = []
        
        var currentLong = locationsInPolygon[0].longitude
        
        for loc in locationsInPolygon
        {
            if loc.longitude == currentLong {
                currentLine.append(loc)
                currentLong = loc.longitude
            }
            else {
                // Flip every other line
                if lines.count % 2 == 0 {
                    lines.append(currentLine.reversed())
                } else {
                    lines.append(currentLine)
                }
                currentLine.removeAll()
                currentLine.append(loc)
                currentLong = loc.longitude
            }
        }
        
        // Add leftover line
        lines.append(currentLine)
        
        let coordinates = Array(lines.joined())
        
        return coordinates
    }
}

