//
//  UtilsTest.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
@testable import FarmLens

class UtilsTest: XCTestCase {
    func testConvertSpacingFeetToDegrees()
    {
        let value:Double = Utils.convertSpacingFeetToDegrees(95)
        let value_trunc = Double(round(100000000 * value) / 100000000)
        
        let expected:Double = 0.000260638946469943
        let expected_trunc = Double(round(100000000 * expected) / 100000000)
        
        XCTAssert(value_trunc.isEqual(to: expected_trunc))
    }
    
    func testMetersToFeet() {
        let value = Utils.metersToFeet(1)
        XCTAssertEqual(value, 3.28084)
    }
}
