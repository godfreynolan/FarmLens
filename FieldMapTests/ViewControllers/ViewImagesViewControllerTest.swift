//
//  ViewImagesViewControllerTest.swift
//  FarmLensTests
//
//  Created by Ian Timmis on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
@testable import FarmLens

class ViewImagesViewControllerTest: XCTestCase {
    
    var viewController: ViewImagesViewController!
    
    override func setUp() {
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = storyboard.instantiateViewController(withIdentifier: "ViewImagesViewController") as! ViewImagesViewController
        _ = viewController.view
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testViewDidLoad() {
        XCTAssertNotNil(viewController.view)
    }
}
