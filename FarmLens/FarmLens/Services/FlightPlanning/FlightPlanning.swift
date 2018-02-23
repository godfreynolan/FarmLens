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
    private let flightDelta = 40 * 90 / 3280.4 / 10000
    
    private var boundingArea: MKPolygon
    
    init(polygon: MKPolygon) {
        self.boundingArea = polygon
    }
    
    func isCoordinateInBoundingArea(coordinate: CLLocationCoordinate2D) -> Bool {
        let renderer = MKPolygonRenderer(polygon: self.boundingArea)
        let position = renderer.point(for: MKMapPoint(x: coordinate.longitude, y: coordinate.latitude))
        
        return renderer.path.contains(position)
    }
    
    func createFlightPath() -> [CLLocationCoordinate2D] {
        let boundingRect = self.boundingArea.boundingMapRect
        
        let startPoint = boundingRect.origin
        
        var flightPath: [CLLocationCoordinate2D] = []
        
        var currentPoint = startPoint
        
        while MKMapRectContainsPoint(boundingRect, currentPoint) {
            increaseLatitude(boundingRect: boundingRect, flightPath: &flightPath, currentPoint: &currentPoint)
            increaseLongitude(boundingRect: boundingRect, flightPath: &flightPath, currentPoint: &currentPoint)
            
            if !MKMapRectContainsPoint(boundingRect, currentPoint) {
                break
            }
            
            decreaseLatitude(boundingRect: boundingRect, flightPath: &flightPath, currentPoint: &currentPoint)
            increaseLongitude(boundingRect: boundingRect, flightPath: &flightPath, currentPoint: &currentPoint)
        }
        
        for coordinate in flightPath {
            if !isCoordinateInBoundingArea(coordinate: coordinate) {
                flightPath = flightPath.filter({ (listCoordinate) -> Bool in
                    coordinate.latitude != listCoordinate.latitude && coordinate.longitude != listCoordinate.longitude
                })
            }
        }
        
        return flightPath
    }
    
    private func increaseLatitude(boundingRect: MKMapRect, flightPath: inout [CLLocationCoordinate2D], currentPoint: inout MKMapPoint) {
        while MKMapRectContainsPoint(boundingRect, currentPoint) {
            flightPath.append(CLLocationCoordinate2D(latitude: currentPoint.y, longitude: currentPoint.x))
            currentPoint.y = currentPoint.y + flightDelta
        }
        
        if !MKMapRectContainsPoint(boundingRect, currentPoint) {
            currentPoint.y = currentPoint.y - flightDelta
        }
    }
    
    private func decreaseLatitude(boundingRect: MKMapRect, flightPath: inout [CLLocationCoordinate2D], currentPoint: inout MKMapPoint) {
        while MKMapRectContainsPoint(boundingRect, currentPoint) {
            flightPath.append(CLLocationCoordinate2D(latitude: currentPoint.y, longitude: currentPoint.x))
            currentPoint.y = currentPoint.y - flightDelta
        }
        
        if !MKMapRectContainsPoint(boundingRect, currentPoint) {
            currentPoint.y = currentPoint.y + flightDelta
        }
    }
    
    private func increaseLongitude(boundingRect: MKMapRect, flightPath: inout [CLLocationCoordinate2D], currentPoint: inout MKMapPoint) {
        while MKMapRectContainsPoint(boundingRect, currentPoint) {
            flightPath.append(CLLocationCoordinate2D(latitude: currentPoint.y, longitude: currentPoint.x))
            currentPoint.x = currentPoint.x + flightDelta
        }
        
        if !MKMapRectContainsPoint(boundingRect, currentPoint) {
            currentPoint.x = currentPoint.x - flightDelta
        }
    }
}
