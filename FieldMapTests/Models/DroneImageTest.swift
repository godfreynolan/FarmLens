//
//  DroneImageTest.swift
//  FarmLensTests
//
//  Created by Ian Timmis on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
import CoreLocation
@testable import FarmLens

class DroneImageTest: XCTestCase {
    
    var loc:CLLocation!
    var img:UIImage!
    var drone_img:DroneImage!
    
    override func setUp() {
        super.setUp()
        
        let lat: CLLocationDegrees = 40.1
        let lon: CLLocationDegrees = 39.9
        
        loc = CLLocation(latitude: lat, longitude: lon)
        img = UIImage()
        
        drone_img = DroneImage(location: loc, image: img)
    }
    
    func testInit() {
        XCTAssertNotNil(drone_img)
    }
    
    func testGetLocation() {
        XCTAssert(drone_img.getLocation().latitude == loc.coordinate.latitude)
        XCTAssert(drone_img.getLocation().longitude == loc.coordinate.longitude)
    }
    
    func testGetImage() {
        XCTAssert(drone_img.getImage() == img)
    }
}
