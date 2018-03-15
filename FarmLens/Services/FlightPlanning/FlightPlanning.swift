//
//  FlightPlanning.swift
//  FarmLens
//
//  Created by Ian Timmis on 2/22/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Mapbox
import MapKit
import DJISDK

class FlightPlanning {
    
    func createMission(missionCoordinates: [CLLocationCoordinate2D]) -> DJIWaypointMission {
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 8
        mission.autoFlightSpeed = 4
        mission.finishedAction = .goHome
        mission.headingMode = .usingWaypointHeading
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .safely
        
        for coordinate in missionCoordinates {
            let waypoint = DJIWaypoint(coordinate: coordinate)
            waypoint.altitude = 100
            waypoint.heading = 0
            waypoint.actionRepeatTimes = 1
            waypoint.actionTimeoutInSeconds = 30
            waypoint.turnMode = .clockwise
            waypoint.add(DJIWaypointAction(actionType: .rotateGimbalPitch, param: -90))
            waypoint.add(DJIWaypointAction(actionType: .shootPhoto, param: 0))
            waypoint.gimbalPitch = -90
            
            mission.add(waypoint)
        }
        
        return DJIWaypointMission(mission: mission)
    }
    
    func calculateFlightPlan(boundingArea: MGLPolygon, spacingFeet: Double) -> [CLLocationCoordinate2D] {
        
        // Steps:
        // 1. Get overlaying rectangle
        // 2. Create a point at each {spacingFeet} interval
        // 3. Remove all points outside the original polygon
        // 4. Reorder points to scan properly.
        
        // Step 1.
        var mapPoints = Array(UnsafeBufferPointer(start: boundingArea.coordinates, count: Int(boundingArea.pointCount)))
        
        var minX = mapPoints[0].longitude
        var minY = mapPoints[0].latitude
        var maxX = mapPoints[0].longitude
        var maxY = mapPoints[0].latitude
        
        for coordinate in mapPoints {
            minX = minX > coordinate.longitude ? coordinate.longitude : minX
            minY = minY > coordinate.latitude ? coordinate.latitude : minY
            maxX = maxX < coordinate.longitude ? coordinate.longitude : maxX
            maxY = maxY < coordinate.latitude ? coordinate.latitude : maxY
        }
        
        var x = minX
        var y = minY
        let xIncrement = convertSpacingFeetToDegrees(spacingFeet)
        let yIncrement = convertSpacingFeetToDegrees(spacingFeet)
        
        // Step 2.
        var locations:[CLLocationCoordinate2D] = []
        
        while x <= maxX {
            while y <= maxY {
                locations.append(CLLocationCoordinate2D(latitude: y, longitude: x))
                y = y + yIncrement
            }
            y = minY
            x = x + xIncrement
            locations.append(CLLocationCoordinate2D(latitude: y, longitude: x))
        }
        
        // Step 3.
        let locationsInPolygon = locations.filter{ location in isCoordinateInBoundingArea(boundaryCoordinates: mapPoints, coordinate: location) }
        
        // Step 4.
        var lines:[[CLLocationCoordinate2D]] = []
        var currentLine:[CLLocationCoordinate2D] = []
        
        var currentLong = locationsInPolygon[0].longitude
        
        for loc in locationsInPolygon
        {
            if loc.longitude == currentLong {
                currentLine.append(loc)
                currentLong = loc.longitude
            } else {
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
    
    private func isCoordinateInBoundingArea(boundaryCoordinates: [CLLocationCoordinate2D], coordinate: CLLocationCoordinate2D) -> Bool {
        // If there is a way to do this in mapbox, I would love to see it
        let renderer = MKPolygonRenderer(polygon: MKPolygon(coordinates: boundaryCoordinates, count: boundaryCoordinates.count))
        let position = renderer.point(for: MKMapPointForCoordinate(coordinate))
        
        return renderer.path.contains(position)
    }
    
    private func convertSpacingFeetToDegrees(_ spacingFeet:Double) -> Double {
        // SpacingFeet / 3280.4 converts feet to kilometers
        // Kilometers / (10000/90) converts kilometers to lat/long distance
        return (spacingFeet / 3280.4) / (10000/90)
    }
}

