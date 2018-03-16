//
//  FarmLensUITests.swift
//  FarmLensUITests
//
//  Created by Ian Timmis on 3/9/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest

class FarmLensUITests: XCTestCase {
    
    var app:XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Since UI tests are more expensive to run, it's usually a good idea
        // to exit if a failure was encountered
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // We send a command line argument to our app,
        // to enable it to reset its state
        app.launchArguments.append("--uitesting")

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNavigation() {
        
        app.launch()
        
        XCUIDevice.shared.orientation = .landscapeLeft
        
        app.buttons["Open"].tap()
        
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Image Download"]/*[[".cells.staticTexts[\"Image Download\"]",".staticTexts[\"Image Download\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["View Images"]/*[[".cells.staticTexts[\"View Images\"]",".staticTexts[\"View Images\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Click on map to create boundaries of the field you want to map."]/*[[".cells.staticTexts[\"Click on map to create boundaries of the field you want to map.\"]",".staticTexts[\"Click on map to create boundaries of the field you want to map.\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
}
