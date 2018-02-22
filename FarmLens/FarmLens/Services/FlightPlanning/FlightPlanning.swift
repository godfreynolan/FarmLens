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
    
    func isCoordinateInBoundingArea(coordinate: CLLocationCoordinate2D) {
        var renderer = MKPolygonRenderer(polygon: self.boundingArea)
        var position = CGPointMake(coordinate.longitude, coordinate.latitude)
        
        return renderer.path.contains(position)
    }
}
