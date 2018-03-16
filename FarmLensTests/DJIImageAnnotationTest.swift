//
//  DJIImageAnnotationTest.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
import Mapbox
@testable import FarmLens

class DJIImageAnnotationTest: XCTest {
    private var imageAnnotation: DJIImageAnnotation!
    
    override func setUp() {
        super.setUp()
        
        imageAnnotation = DJIImageAnnotation()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInitialState() {
        assert(imageAnnotation.identifier == "N/A")
    }
    
    func testConstructors() {
        imageAnnotation = DJIImageAnnotation(identifier: "Test")
        assert(imageAnnotation.identifier == "Test")
        assert(imageAnnotation.heading == 0)
        
        imageAnnotation = DJIImageAnnotation(coordinates: CLLocationCoordinate2D(latitude: 42.5448540291358, longitude: -83.118421372042), heading: 5)
        assert(imageAnnotation.identifier == "N/A")
        assert(imageAnnotation.heading == 5)
    }
}
