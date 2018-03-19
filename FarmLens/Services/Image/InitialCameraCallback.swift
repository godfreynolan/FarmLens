//
//  InitialCameraCallback.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit

class InitialCameraCallback: CameraCallback {
    private var imageDownloader: ImageDownloader!
    private var viewController: UIViewController!
    
    init(viewController: UIViewController) {
        self.imageDownloader = ImageDownloader(callback: self)
        self.viewController = viewController
    }
    
    func fetchInitialData() {
        self.imageDownloader.setCameraToDownload()
    }
    
    func onDownloadReady() {
        self.imageDownloader.retrieveMediaFiles()
    }
    
    func onPhotoReady() {
        
    }
    
    func onFileListRefresh() {
        let mediaManager = self.imageDownloader.fetchMediaManager()
        
        if viewController is FlightViewDetailController {
            let flightViewDetailController = viewController as! FlightViewDetailController
            flightViewDetailController.setPreFlightImageCount(imageCount: (mediaManager.fileListSnapshot()?.count)!)
        } else if viewController is ImageDownloadViewController {
            let imageDownloadViewController = viewController as! ImageDownloadViewController
            imageDownloadViewController.setTotalImageCount(totalFileCount: (mediaManager.fileListSnapshot()?.count)!)
        }
        
        self.imageDownloader.setCameraToPhotoShoot()
    }
    
    func onError(error: Error?) {
        
    }
}
