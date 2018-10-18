//
//  StartupViewControllerTest.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
@testable import FarmLens

class StartupViewControllerTest: XCTestCase {
    
    private var viewController: StartupViewController!
    
    override func setUp() {
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = storyboard.instantiateViewController(withIdentifier: "StartupViewController") as! StartupViewController
        _ = viewController.view
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testViewDidLoad() {
        assert(viewController.title == "FarmLens")
    }
    
    func testProductDisconnected() {
        viewController.productDisconnected()
        
        assert(viewController.productConnectionStatus.text == "Status: No Product Connected")
    }
}
