//
//  BoundingAreaPolygon.swift
//  FarmLens
//
//  Created by Tom Kocik on 2/21/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import MapKit

class BoundingAreaPolygon {
    var coordinateList: [CLLocationCoordinate2D] = []
    
    func addCoordinate(coordinate: CLLocationCoordinate2D) {
        coordinateList.append(coordinate)
    }
}
