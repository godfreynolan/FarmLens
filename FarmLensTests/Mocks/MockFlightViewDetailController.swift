//
//  MockFlightViewDetailController.swift
//  FarmLensTests
//
//  Created by Ian Timmis on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
@testable import FarmLens

class MockFlightViewDetailController: FlightViewDetailController {
    override func startMission() {
        // Do nothing
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        
    }
}
