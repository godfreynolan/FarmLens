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
    
    func createFlightPath(coordinateList: [CLLocationCoordinate2D]) {
        let boundingRect = self.boundingArea.boundingMapRect
        
        let startPoint = boundingRect.origin
        let endPoint = MKMapPointMake(MKMapRectGetMaxX(boundingRect), MKMapRectGetMaxY(boundingRect))
        
        var flightPath: [CLLocationCoordinate2D] = []
        
        var currentPoint = startPoint
        while MKMapRectContainsPoint(boundingRect, currentPoint) {
            flightPath.append(CLLocationCoordinate2D(latitude: currentPoint.y, longitude: currentPoint.x))
            currentPoint.y = currentPoint.y + flightDelta
        }
    }
    
    private func increaseLatitude(boundingRect: MKMapRect, flightPath: [CLLocationCoordinate2D], currentPoint: MKMapPoint) {
        while MKMapRectContainsPoint(boundingRect, currentPoint) {
//            flightPath.append(CLLocationCoordinate2D(latitude: currentPoint.y, longitude: currentPoint.x))
//            currentPoint.y = currentPoint.y + flightDelta
        }
    }
}
