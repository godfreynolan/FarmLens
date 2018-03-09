//
//  DJIImageAnnotation.swift
//  SDK Swift Sample
//
//  Created by Arnaud Thiercelin on 3/25/17.
//  Copyright © 2017 DJI. All rights reserved.
//

import UIKit
import Mapbox

class DJIImageAnnotation: NSObject, MGLAnnotation {

    var identifier = "N/A"
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    
    fileprivate var _heading: Double = 0.0
    public var heading: Double {
        get {
            return _heading
        }
        set {
            _heading = newValue
        }
    }
    
    init(identifier: String) {
        self.identifier = identifier        
    }
    
    init(coordinates: CLLocationCoordinate2D, heading: Double) {
        self.coordinate = coordinates
        _heading = heading
    }
    
}
