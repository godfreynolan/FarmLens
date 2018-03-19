//
//  DroneImage.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import CoreLocation

class DroneImage {
    private var location: CLLocationCoordinate2D!
    private var image: UIImage!
    
    init(location: CLLocation, image: UIImage) {
        self.location = location.coordinate
        self.image = image
    }
    
    func getLocation() -> CLLocationCoordinate2D {
        return location
    }
    
    func getImage() -> UIImage {
        return image
    }
}
