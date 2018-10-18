//
//  ImageDownloadViewController.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK
import Photos

class ImageDownloadViewController: UIViewController, CameraCallback {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private var camera: DJICamera?
    private var currentDownloadIndex = 0
    private var mediaDownloadList: [DJIMediaFile] = []
    private var mediaManager: DJIMediaManager?
    private var statusIndex = 0
    private var imageDownloader: MediaHandler!
    private var initialCameraCallback: InitialCameraCallback!
    
    @IBOutlet weak var totalDownloadImageLabel: UILabel!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    
    private var droneConnected:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var didDownload = false
    @IBAction func downloadPictures(_ sender: UIButton) {
        if self.appDelegate.flightImageCount == 0 {
            let alert = UIAlertController(title: "Error", message: "There are no pictures to download", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if (self.droneConnected) {
            self.imageDownloader.setCameraToDownload()
        }
    }
    
    @IBAction func GenerateNdviImages(_ sender: Any) {
        if didDownload == true {
            if self.appDelegate.flightImageCount != 0 {
                let gen = HealthMapGenerator()
                let loader = ImageLoader()

                downloadProgressLabel.text = "Loading images..."
                let drone_images = loader.loadImages(imageCount: appDelegate.flightImageCount)

                var i = 1
                for img in drone_images {
                    
                    downloadProgressLabel.text = "Processing Image \(i) of \(appDelegate.flightImageCount)"
                    
                    // Generate health map
                    img.setImage(image: gen.GenerateHealthMap(img: img.getImage()))

                    // Save to photo album
                    let loc = CLLocation(latitude: img.getLocation().latitude, longitude: img.getLocation().longitude)
                    addAssetWithMetadata(image: img.getImage(), location: loc)

                    i = i + 1
                }
                stitchImages("")
            } else {
                let alert = UIAlertController(title: "Error", message: "There are no pictures to process", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "You need to download images first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func addAssetWithMetadata(image: UIImage, location: CLLocation? = nil) {
        PHPhotoLibrary.shared().performChanges({
            // Request creating an asset from the image.
            let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            // Set metadata location
            if let location = location {
                creationRequest.location = location
            }
        }, completionHandler: { success, error in
            if !success { NSLog("error creating asset: \(String(describing: error))") }
        })
    }
    
    //### CameraCallback ###
    func onDownloadReady() {
        self.mediaDownloadList = (self.mediaManager?.fileListSnapshot())!
        
        self.downloadProgressLabel.text = "Downloading Image 1 of \(self.appDelegate.flightImageCount)"
        //self.startImageDownload()
    }
    
    func onPhotoReady() {
        self.downloadProgressLabel.text = "All Images Downloaded"
        didDownload = true
        GenerateNdviImages("")
    }
    
    func onFileListRefresh() {
        // Not needed since we already refreshed the file snapshot to get the image count
    }
    
    func fetchCamera() -> DJICamera? {
        if (DJISDKManager.product() == nil) {
            return nil
        }
        
        if (DJISDKManager.product() is DJIAircraft) {
            return (DJISDKManager.product() as? DJIAircraft)?.camera
        }
        
        return nil
    }
    
    //### CameraCallback Helper ###
    func setTotalImageCount(totalFileCount: Int) {
        self.appDelegate.flightImageCount = totalFileCount - self.appDelegate.preFlightImageCount

        if self.appDelegate.flightImageCount == 0 {
            self.totalDownloadImageLabel.text = "0 Images to download"
            self.downloadProgressLabel.text = "No images to download"
        } else if self.appDelegate.flightImageCount == 1 {
            self.totalDownloadImageLabel.text = "1 Image to download"
            self.downloadProgressLabel.text = "Ready to download"
        } else {
            self.totalDownloadImageLabel.text = "\(self.appDelegate.flightImageCount) Images to download"
            self.downloadProgressLabel.text = "Ready to download"
        }
    }
    
    func onError(error: Error?) {
        if (error != nil) {
            let alert = UIAlertController(title: "Camera Error", message: "Please verify connection to the drone. If connected, please verify the drone is nearby.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Camera Error", message: "Please verify the drone is idle.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //### Helper Methods ###

    @IBAction func stitchImages(_ sender: Any) {
        self.downloadProgressLabel.text = String(format: "Uploading image 1 of %d", mediaDownloadList.count)
        var num = 0
        DispatchQueue.global(qos: .background).async {
            let requester = StitchRequester()
            requester.startStitch {
                DispatchQueue.main.async {
                    self.downloadProgressLabel.text = String("Started stitch")
                    self.downloadProgressLabel.setNeedsDisplay()
                }
                let loader = ImageLoader()
                var images = loader.loadAssetImages(imageCount: self.appDelegate.flightImageCount)
                for image in images {
                    
                }
                DispatchQueue.main.async {
                    self.downloadProgressLabel.text = String(format: "Images fetched: %d", images.count)
                    self.downloadProgressLabel.setNeedsDisplay()
                }
                requester.addImages(images: images, onImageSuccess: {
                    num = num + 1
                    DispatchQueue.main.async {
                        self.downloadProgressLabel.text = String(format: "Added image %d of %d", num, self.appDelegate.flightImageCount)
                        self.downloadProgressLabel.setNeedsDisplay()
                    }
                    if num == self.mediaDownloadList.count {
                        self.lockStitch(requester)
                    }
                }, onImageFailure: { (err) in
                    num = num + 1
                    let alert = UIAlertController(title: "Mission Error", message: err, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    DispatchQueue.main.async {
                        self.downloadProgressLabel.text = String(format: "failure %d", num)
                        self.downloadProgressLabel.setNeedsDisplay()
                    }
                })
            }
        }
    }
    
    private func lockStitch(_ requester: StitchRequester) {
        requester.lockStitch(onSuccess: { () in
            DispatchQueue.main.async {
                self.downloadProgressLabel.text = "Stitch locked! Waiting for completion..."
                self.downloadProgressLabel.setNeedsDisplay()
            }
            self.pollStitch(requester)
        }, onFailure: { () in
            DispatchQueue.main.async {
                self.downloadProgressLabel.text = "Could not lock stitch!"
                self.downloadProgressLabel.setNeedsDisplay()
            }
        })
    }
    
    private func pollStitch(_ requester: StitchRequester) {
        requester.pollStitch { (isComplete) in
            if(!isComplete) {
                sleep(3)
                self.pollStitch(requester)
            } else {
                DispatchQueue.main.async {
                    self.downloadProgressLabel.text = "Stitch complete! Downloading..."
                    self.downloadProgressLabel.setNeedsDisplay()
                }
                self.retrieveStitch(requester)
            }
        }
    }
    
    private func retrieveStitch(_ requester: StitchRequester) {
        requester.retrieveResult { (data) in
            if data == nil {
                DispatchQueue.main.async {
                    self.downloadProgressLabel.text = "Stitch download failed. Please try again."
                    self.downloadProgressLabel.setNeedsDisplay()
                }
            } else {
                DispatchQueue.main.async {
                    self.downloadProgressLabel.text = "Stitch download complete."
                    self.downloadProgressLabel.setNeedsDisplay()
                }
            }
        }
    }
}
