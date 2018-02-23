//
//  FlightPlanning.swift
//  FarmLens
//
//  Created by Ian Timmis on 2/22/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import MapKit

class FlightPlanning {
    
    private var boundingArea: MKPolygon
    
    init(polygon: MKPolygon) {
        self.boundingArea = polygon
    }
    
    func isCoordinateInBoundingArea(coordinate: CLLocationCoordinate2D) -> Bool {
        let renderer = MKPolygonRenderer(polygon: self.boundingArea)
        let position = renderer.point(for: MKMapPointForCoordinate(coordinate))
        
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
        let mapPoints = self.boundingArea.points()
        
        var minX = MKCoordinateForMapPoint(mapPoints[0]).longitude
        var minY = MKCoordinateForMapPoint(mapPoints[0]).latitude
        var maxX = MKCoordinateForMapPoint(mapPoints[0]).longitude
        var maxY = MKCoordinateForMapPoint(mapPoints[0]).latitude
        
        for i in 0...(self.boundingArea.pointCount - 1) {
            let coordinate = MKCoordinateForMapPoint(mapPoints[i])
            
            minX = minX > coordinate.longitude ? coordinate.longitude : minX
            minY = minY > coordinate.latitude ? coordinate.latitude : minY
            maxX = maxX < coordinate.longitude ? coordinate.longitude : maxX
            maxY = maxY < coordinate.latitude ? coordinate.latitude : maxY
        }
        
        var x = minX
        var y = minY
        let increment = convertSpacingFeetToDegrees(spacingFeet)
        
        // Step 2. Create a point at each {spacingFeet} interval
        var locations:[CLLocationCoordinate2D] = []
        
        while x <= maxX {
            while y <= maxY {
                locations.append(CLLocationCoordinate2D(latitude: y, longitude: x))
                y = y + increment
            }
            y = minY
            x = x + increment
            locations.append(CLLocationCoordinate2D(latitude: y, longitude: x))
        }
        
        // Step 3. Remove all points outside the original polygon
        let locationsInPolygon = locations.filter{ location in isCoordinateInBoundingArea(coordinate: location) }
        
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
        if lines.count % 2 == 0 {
            lines.append(currentLine.reversed())
        } else {
            lines.append(currentLine)
        }
        
        let coordinates = Array(lines.joined())
        
        return coordinates
    }
}

