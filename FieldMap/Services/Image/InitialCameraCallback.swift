//
//  InitialCameraCallback.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK

class InitialCameraCallback: CameraCallback {
    private var mediaHandler: MediaHandler!
    private var viewController: UIViewController!
    
    init(camera: DJICamera, viewController: UIViewController) {
        self.mediaHandler = MediaHandler(callback: self, camera: camera)
        self.viewController = viewController
    }
    
    func fetchInitialData() {
        self.mediaHandler.setCameraToDownload()
        if viewController is FlightViewDetailController {
            let flightViewDetailController = self.viewController as! FlightViewDetailController
            flightViewDetailController.startMission()
        }
    }
    
    func onDownloadReady() {
        self.mediaHandler.retrieveMediaFiles()
    }
    
    func onPhotoReady() {
        if viewController is StartupViewController {
            let startupViewController = self.viewController as! StartupViewController
            startupViewController.handleConnected()
        } else if viewController is FlightViewDetailController {
            let flightViewDetailController = self.viewController as! FlightViewDetailController
            flightViewDetailController.startMission()
        }
    }
    
    func onFileListRefresh() {
        let mediaManager = self.mediaHandler.fetchMediaManager()
        
        if viewController is StartupViewController {
            let startupViewController = self.viewController as! StartupViewController
            startupViewController.setPreFlightImageCount(imageCount: (mediaManager.sdCardFileListSnapshot()?.count)!)
        } else if self.viewController is FlightViewDetailController {
            let flightViewDetailController = self.viewController as! FlightViewDetailController
            flightViewDetailController.setPreFlightImageCount(imageCount: (mediaManager.sdCardFileListSnapshot()?.count)!)
        } else if self.viewController is ImageDownloadViewController {
            let imageDownloadViewController = self.viewController as! ImageDownloadViewController
            imageDownloadViewController.setTotalImageCount(totalFileCount: (mediaManager.sdCardFileListSnapshot()?.count)!)
        }
        
        self.mediaHandler.setCameraToPhotoShoot()
    }
    
    func onError(error: Error?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.viewController.present(alert, animated: true, completion: nil)
    }
}
