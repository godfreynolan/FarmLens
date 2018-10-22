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
        mission.maxFlightSpeed = 15
        mission.autoFlightSpeed = 15
        mission.finishedAction = .goHome
        mission.headingMode = .usingWaypointHeading
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .safely
        
        for coordinate in missionCoordinates {
            let waypoint = DJIWaypoint(coordinate: coordinate)
            waypoint.altitude = 60.0
            waypoint.heading = 0
            waypoint.actionRepeatTimes = 1
            waypoint.actionTimeoutInSeconds = 30
            waypoint.turnMode = .clockwise
            waypoint.add(DJIWaypointAction(actionType: .rotateGimbalPitch, param: -90))
            waypoint.add(DJIWaypointAction(actionType: .shootPhoto, param: 0))
            waypoint.gimbalPitch = -90
            waypoint.shootPhotoDistanceInterval = Float(Utils.feetToMeters(95))
            
            mission.add(waypoint)
        }
        
        return DJIWaypointMission(mission: mission)
    }
    
    func calculateFlightPlan(boundingArea: MGLPolygon, spacingFeet: Double) -> [CLLocationCoordinate2D] {
        // Steps:
        // 1. Get the overlay polygon's min/max lat/long's
        // 2. Starting from lat/long mins, increment the lat by spacingFeet and store the coordinate.
        // 3. Once the max lat is exceeded, filter out coordinates that are not in the original overlay polygon.
        // 4. Store the start and end point of the above line. Increment the long. Repeat 2-4 until the max long is exceeded
        // 5. Reorder points to create a more efficient flight plan
        
        let mapPoints = Array(UnsafeBufferPointer(start: boundingArea.coordinates, count: Int(boundingArea.pointCount)))
        
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
        let xIncrement = Utils.convertSpacingFeetToDegrees(spacingFeet)
        let yIncrement = Utils.convertSpacingFeetToDegrees(spacingFeet)
        
        // Step 2.
        var locations:[CLLocationCoordinate2D] = []
        
        while x <= maxX {
            var yLineLocations = [CLLocationCoordinate2D]()
            
            while y <= maxY {
                yLineLocations.append(CLLocationCoordinate2D(latitude: y, longitude: x))
                y += yIncrement
            }
            
            // Step 3.
            yLineLocations = yLineLocations.filter{ location in isCoordinateInBoundingArea(boundaryCoordinates: mapPoints, coordinate: location) }
            
            // Step 4.
            if !yLineLocations.isEmpty {
                locations.append(yLineLocations.first!)
                locations.append(yLineLocations.last!)
            }
            
            y = minY
            x = x + xIncrement
        }
        
        // Step 5.
        var lines:[[CLLocationCoordinate2D]] = []
        var currentLine:[CLLocationCoordinate2D] = []
        
        var currentLong = locations[0].longitude
        
        for loc in locations
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
}

