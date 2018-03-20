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
    private var imageDownloader: ImageDownloader!
    private var viewController: UIViewController!
    
    init(camera: DJICamera, viewController: UIViewController) {
        self.imageDownloader = ImageDownloader(callback: self, camera: camera)
        self.viewController = viewController
    }
    
    func fetchInitialData() {
        self.imageDownloader.setCameraToDownload()
    }
    
    func onDownloadReady() {
        self.imageDownloader.retrieveMediaFiles()
    }
    
    func onPhotoReady() {
        if viewController is FlightViewDetailController {
            let flightViewDetailController = viewController as! FlightViewDetailController
            flightViewDetailController.startMission()
        }
    }
    
    func onFileListRefresh() {
        let mediaManager = self.imageDownloader.fetchMediaManager()
        
        if viewController is FlightViewDetailController {
            let flightViewDetailController = self.viewController as! FlightViewDetailController
            flightViewDetailController.setPreFlightImageCount(imageCount: (mediaManager.fileListSnapshot()?.count)!)
        } else if viewController is ImageDownloadViewController {
            let imageDownloadViewController = self.viewController as! ImageDownloadViewController
            imageDownloadViewController.setTotalImageCount(totalFileCount: (mediaManager.fileListSnapshot()?.count)!)
        }
        
        self.imageDownloader.setCameraToPhotoShoot()
    }
    
    func onError(error: Error?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.viewController.present(alert, animated: true, completion: nil)
    }
}
