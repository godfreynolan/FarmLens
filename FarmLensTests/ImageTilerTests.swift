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
    
    func testConvertSpacingFeetToDegrees()
    {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let value:Double = imageTiler.convertSpacingFeetToDegrees(95)
        let value_trunc = Double(round(100000000 * value) / 100000000)
        
        let expected:Double = 0.000260638946469943
        let expected_trunc = Double(round(100000000 * expected) / 100000000)
        
        XCTAssert(value_trunc.isEqual(to: expected_trunc))
    }
    
    func testImageOverlay()
    {
        let mapView = MGLMapView()
        
        let style:MGLStyle = MockMGLStyle()
        
        let points = [
            CLLocationCoordinate2D(latitude: 42.5448540291358, longitude: -83.118421372042),
            CLLocationCoordinate2D(latitude: 42.5451445170314, longitude: -83.1184361241915),
        ]
        
        let images = [
            UIImage(named: "aircraft")!,
            UIImage(named: "aircraft")!,
        ]
        
        XCTAssertTrue(imageTiler.overlayImages(mapView:mapView, style:style, imageLocations:points, images:images))
        
        let points_mismatch = [
            CLLocationCoordinate2D(latitude: 42.5448540291358, longitude: -83.118421372042),
            CLLocationCoordinate2D(latitude: 42.5451445170314, longitude: -83.1184361241915),
            CLLocationCoordinate2D(latitude: 42.5451563736514, longitude: -83.1180740259745),
            ]

        XCTAssertFalse(imageTiler.overlayImages(mapView:mapView, style:style, imageLocations:points_mismatch, images:images))
    }
}
