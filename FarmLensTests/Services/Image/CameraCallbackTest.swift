//
//  CameraCallbackTest.swift
//  FarmLensTests
//
//  Created by Ian Timmis on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
import UIKit
@testable import FarmLens

class CameraCallbackTest: XCTestCase {
    
    var cam_cb:InitialCameraCallback!
    
    override func setUp() {
        super.setUp()
        
        // Test Constructor
        let viewController = MockFlightViewDetailController()
        cam_cb = InitialCameraCallback(viewController: viewController)
    }
    
    // Test OnError
    func testOnError() {
        let error = MockError()
        cam_cb.onError(error: error)
    }
    
    // Test onPhotoReady
    func testOnPhotoReady() {
        cam_cb.onPhotoReady()
    }
}
