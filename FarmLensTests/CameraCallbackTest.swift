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
        let viewController = UIViewController()
        cam_cb = InitialCameraCallback(viewController: viewController)
    }
    
    func testFetchInitialData() {
        cam_cb.fetchInitialData()
    }
    
    func testOnDownloadReady() {
        cam_cb.onDownloadReady()
    }
    
    func testOnPhotoReady() {
        cam_cb.onPhotoReady()
    }
    
    func testOnFileListRefresh() {
        cam_cb.onFileListRefresh()
    }
    
    func testOnError() {
        let error = MockError()
        cam_cb.onError(error: error)
    }
}

//fetchInitialData()
//onDownloadReady()
//onPhotoReady()
//onFileListRefresh()
//onError(error: Error?)

