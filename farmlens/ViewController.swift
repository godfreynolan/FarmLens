//
//  ViewController.swift
//  farmlens
//
//  Created by Ian Timmis on 2/14/18.
//  Copyright © 2018 Agribotix. All rights reserved.
//

import UIKit
import DJISDK

class ViewController: UIViewController, DJISDKManagerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DJISDKManager.registerApp(with: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func appRegisteredWithError(_ error: Error?) {
        var message = "Register App Successed!"
        if (error != nil) {
            message = "Register app failed! Please enter your app key and check the network."
        } else {
            DJISDKManager.startConnectionToProduct()
        }
        
        self.showAlertViewWithTitle(title:"Register App", withMessage: message)
    }
}

