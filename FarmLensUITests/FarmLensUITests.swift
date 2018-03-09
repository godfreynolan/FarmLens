//
//  FarmLensUITests.swift
//  FarmLensUITests
//
//  Created by Ian Timmis on 3/9/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest

class FarmLensUITests: XCTestCase {
<<<<<<< HEAD
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
=======
    
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
>>>>>>> d6a5957babd3c5d9fde3925769e2faa0684ae885

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
<<<<<<< HEAD
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
                
=======
    func testNavigation() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        app.launch()
        
        XCUIDevice.shared.orientation = .landscapeLeft

        app.buttons["Open"].tap()
        
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Click on map to create boundaries of the field you want to map."]/*[[".cells.staticTexts[\"Click on map to create boundaries of the field you want to map.\"]",".staticTexts[\"Click on map to create boundaries of the field you want to map.\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
>>>>>>> d6a5957babd3c5d9fde3925769e2faa0684ae885
    }
    
}
