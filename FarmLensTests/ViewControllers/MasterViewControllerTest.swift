//
//  MasterViewControllerTest.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
@testable import FarmLens

class MasterViewControllerTest: XCTestCase {
    
    private var viewController: MasterViewController!
    
    override func setUp() {
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = storyboard.instantiateViewController(withIdentifier: "MasterViewController") as! MasterViewController
        _ = viewController.view
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSetup() {
        let count = viewController.tableView(UITableView(), numberOfRowsInSection: 0)
        assert(count == 3)
        
        viewController.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))
        viewController.tableView(UITableView(), didSelectRowAt: IndexPath(row: 1, section: 0))
        viewController.tableView(UITableView(), didSelectRowAt: IndexPath(row: 2, section: 0))
    }
}
