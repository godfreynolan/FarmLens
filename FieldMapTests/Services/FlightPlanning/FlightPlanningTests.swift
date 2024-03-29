//
//  FlightPlanningTests.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 2/23/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
import Mapbox
@testable import FarmLens

class FlightPlanningTests: XCTestCase {
    private let points = [
        CLLocationCoordinate2D(latitude: 42.5448540291358, longitude: -83.118421372042),
        CLLocationCoordinate2D(latitude: 42.5451445170314, longitude: -83.1184361241915),
        CLLocationCoordinate2D(latitude: 42.5451563736514, longitude: -83.1180740259745),
        CLLocationCoordinate2D(latitude: 42.5450763414222, longitude: -83.117974784241),
        CLLocationCoordinate2D(latitude: 42.5450931383183, longitude: -83.117620732651),
        CLLocationCoordinate2D(latitude: 42.544784865152, longitude: -83.117615368233),
        CLLocationCoordinate2D(latitude: 42.544780912922, longitude: -83.1179318688968)
    ]
    
    var flightPlanning: FlightPlanning!
    
    override func setUp() {
        super.setUp()
        
        flightPlanning = FlightPlanning()
    }
    
    func testCalculateFlightPlan() {
        let polygon = MGLPolygon(coordinates: points, count: UInt(points.count))
        let flightPath = flightPlanning.calculateFlightPlan(boundingArea: polygon, spacingFeet: 40)
        XCTAssert(flightPath.count == 14, "Actual value is \(flightPath.count)")
    }
    
    func testCreateMission() {
        let polygon = MGLPolygon(coordinates: points, count: UInt(points.count))
        let flightPath = flightPlanning.calculateFlightPlan(boundingArea: polygon, spacingFeet: 40)
        let mission = flightPlanning.createMission(missionCoordinates: flightPath)
        XCTAssert(mission.waypointCount == 14, "Actual value is \(mission.waypointCount)")
    }
}
