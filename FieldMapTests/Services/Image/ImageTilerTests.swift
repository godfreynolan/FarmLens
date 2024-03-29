//
//  ImageTilerTests.swift
//  FarmLensTests
//
//  Created by Ian Timmis on 3/15/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
import Mapbox
@testable import FarmLens

class ImageTilerTests: XCTestCase {
    
    var imageTiler = ImageTiler()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testImageOverlay()
    {
        let mapView = MGLMapView()
        
        let style:MGLStyle = MockMGLStyle()
        
        let djiImages = [
            DroneImage(location: CLLocation(latitude: 42.5448540291358, longitude: -83.118421372042), image: UIImage(named: "aircraft")!),
            DroneImage(location: CLLocation(latitude: 42.5451445170314, longitude: -83.1184361241915), image: UIImage(named: "aircraft")!)
        ]
        
        XCTAssertTrue(imageTiler.overlayImages(mapView:mapView, style:style, images:djiImages))
        
        let images_empty: [DroneImage] = []

        XCTAssertFalse(imageTiler.overlayImages(mapView:mapView, style:style, images:images_empty))
    }
}
