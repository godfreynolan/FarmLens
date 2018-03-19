//
//  ImageDownloader.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import DJISDK
import UIKit

class ImageDownloader {
    private var camera: DJICamera!
    private var callback: CameraCallback!
    
    init(callback: CameraCallback) {
        self.callback = callback
        camera = fetchCamera()
    }
    
    // ### Camera Modes ###
    func setCameraToDownload() {
        self.camera.setMode(.mediaDownload, withCompletion: { (error) in
            if (error != nil) {
                self.callback.onError(error: error)
            } else {
                self.callback.onDownloadReady()
            }
        })
    }
    
    func setCameraToPhotoShoot() {
        self.camera.setMode(.shootPhoto, withCompletion: { (error) in
            if (error == nil) {
                self.callback.onPhotoReady()
            }
        })
    }
    
    // ### MediaManager state ###
    func retrieveMediaFiles() {
        if (self.camera.mediaManager?.fileListState == .syncing || self.camera.mediaManager?.fileListState == .deleting) {
            self.callback.onError(error: nil)
        } else {
            self.camera.mediaManager?.refreshFileList(completion: { (error) in
                if (error != nil) {
                    self.callback.onError(error: error)
                } else {
                    self.callback.onFileListRefresh()
                }
            })
        }
    }
    
    // ### Helpers ###
    private func fetchCamera() -> DJICamera? {
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
