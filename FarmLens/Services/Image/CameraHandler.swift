//
//  CameraHandler.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import DJISDK

class CameraHandler: NSObject {
    func fetchCamera() -> DJICamera? {
        if (DJISDKManager.product() == nil) {
            return nil
        }
        
        if (DJISDKManager.product() is DJIAircraft) {
            return (DJISDKManager.product() as? DJIAircraft)?.camera
        }
        
        return nil
    }
    
    func fetchMediaManager() -> DJIMediaManager {
        return (fetchCamera()?.mediaManager)!
    }
}
