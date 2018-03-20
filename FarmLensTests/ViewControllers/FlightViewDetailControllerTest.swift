//
//  FlightViewDetailControllerTest.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
import Mapbox
@testable import FarmLens

class FlightViewDetailControllerTest: XCTestCase {
    
    private var viewController: FlightViewDetailController!
    
    override func setUp() {
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = storyboard.instantiateViewController(withIdentifier: "FlightViewDetailController") as! FlightViewDetailController
        _ = viewController.view
    }
    
    func testFetchCamera() {
        XCTAssertNil(self.viewController.fetchCamera())
    }
    
    func testShouldPerformSegue() {
        assert(viewController.shouldPerformSegue(withIdentifier: "test", sender: nil))
        assert(!viewController.shouldPerformSegue(withIdentifier: "downloadImageSegue", sender: nil))
    }
    
    func testMapViews() {
        var annotation = viewController.mapView(MGLMapView(), imageFor: MGLUserLocation())
        assert(annotation == nil)
        
        annotation = viewController.mapView(MGLMapView(), imageFor: DJIImageAnnotation(identifier: "test"))
        assert(annotation != nil)
        
        var color = viewController.mapView(MGLMapView(), strokeColorForShapeAnnotation: MGLPolyline())
        assert(color == .red)
        
        color = viewController.mapView(MGLMapView(), strokeColorForShapeAnnotation: MGLPolygon())
        assert(color == .green)
        
        color = viewController.mapView(MGLMapView(), fillColorForPolygonAnnotation: MGLPolygon())
        assert(color == .green)
        
        assert(viewController.mapView(MGLMapView(), lineWidthForPolylineAnnotation: MGLPolyline()) == 6)
        
        var alpha = viewController.mapView(MGLMapView(), alphaForShapeAnnotation: MGLPolyline())
        assert(alpha == 1)
        
        alpha = viewController.mapView(MGLMapView(), alphaForShapeAnnotation: MGLPolygon())
        assert(alpha == 0.5)
        
        var showCallout = viewController.mapView(MGLMapView(), annotationCanShowCallout: MGLPointAnnotation())
        assert(showCallout)
        
        showCallout = viewController.mapView(MGLMapView(), annotationCanShowCallout: MGLUserLocation())
        assert(!showCallout)
        
        assert(viewController.mapView(MGLMapView(), rightCalloutAccessoryViewFor: MGLPointAnnotation()) != nil)
    }
}
