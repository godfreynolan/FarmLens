//

//  FlightCompleteViewController.swift
//  FarmLens
//
//  Created by Administrator on 10/15/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK
import Photos

class FlightCompleteViewController: UIViewController, CameraCallback {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var downloadNow: UIButton!
    @IBOutlet weak var downloadLater: UIButton!
    @IBOutlet weak var cancelDownload: UIButton!
    @IBOutlet weak var checkIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!

    public var shouldStartImmediately: Bool = false
    private var droneConnected: Bool = false
    private var camera: DJICamera?
    private var currentDownloadIndex = 0
    private var mediaDownloadList: [DJIMediaFile] = []
    private var mediaManager: DJIMediaManager?
    private var statusIndex = 0
    private var imageDownloader: MediaHandler!
    private var initialCameraCallback: InitialCameraCallback!
    private var didDownload: Bool = false
    private var logger = Log()
    
    private var stitchedImage: UIImage? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        let trackInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 15)
        var trackImg = UIImage(named: "progress-track")
        var progressImg = UIImage(named: "progress")
        trackImg = trackImg?.resizableImage(withCapInsets: trackInsets)
        progressImg = progressImg?.resizableImage(withCapInsets: trackInsets)
        self.progressBar.trackImage = trackImg
        self.progressBar.progressImage = progressImg
        
        PHPhotoLibrary.requestAuthorization { (status) in }
        
        updateDroneStatus()
    }
    
    @IBAction func downloadNowClicked(_ sender: Any) {
        self.startDownload()
    }
    
    private func startDownload() {
        self.downloadNow.isHidden = true
        self.downloadLater.isHidden = true
        self.checkIcon.isHidden = true
        self.titleLabel.text = "Downloading Images..."
        self.progressBar.isHidden = false
        self.cancelDownload.isHidden = false
        self.statusLabel.isHidden = false
        
        if self.droneConnected {
            self.statusLabel.text = "Starting Download..."
            if(self.shouldStartImmediately) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5, execute: {() in
                    self.imageDownloader.setCameraToDownload()
                })
            } else {
                self.imageDownloader.setCameraToDownload()
            }
        } else {
            self.statusLabel.text = "Download couldn't start: No drone connected"
        }
    }
    
    @IBAction func downloadLaterClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// MARK: Helper methods
    private func startImageDownload() {
        self.statusIndex = 1
        self.currentDownloadIndex = 0

        CustomPhotoAlbum.sharedInstance.clearAssetCollection {
            self.downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
        }
    }
    
    private func downloadImage(file: DJIMediaFile) {
        let isPhoto = file.mediaType == .JPEG || file.mediaType == .TIFF;
        if (!isPhoto) {
            return
        }
        
        var mutableData: Data? = nil
        var previousOffset = 0
        
        file.fetchPreview { (error) in
            if (error != nil) { return }
            
            let data = UIImagePNGRepresentation(file.preview!)!
            self.saveImage(data: data, statusIndex: self.statusIndex)
            let progress = Float(self.statusIndex) / Float(self.mediaDownloadList.count)
            self.progressBar.setProgress(progress, animated: true)
            
            self.statusIndex += 1
            self.currentDownloadIndex += 1
            if (self.currentDownloadIndex < self.mediaDownloadList.count) {
                self.statusLabel.text = "Downloading Image \(self.statusIndex) of \(self.appDelegate.flightImageCount)"
                self.downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
            } else {
                self.imageDownloader.setCameraToPhotoShoot()
            }
        }
    }
    
    private func saveImage(data: Data, statusIndex: Int) {
        let fileName = "DJI_Image_\(statusIndex).jpg"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
        } catch {
            
        }
        
        CustomPhotoAlbum.sharedInstance.save(fileURL: fileURL)
//        PHPhotoLibrary.shared().performChanges({
//            let request = PHAssetCreationRequest.forAsset()
//            request.addResource(with: .photo, fileURL: fileURL, options: nil)
//        }, completionHandler: { success, error in
//            do {
//                try FileManager.default.removeItem(at: fileURL)
//            } catch {
//
//            }
//
//            if !success {
//                let message = String("Save Image Failed! Error: " + (error?.localizedDescription)!);
//                let alert = UIAlertController(title: "Download Error", message: message, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            }
//        })
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
    
    /// MARK: CameraCallback
    func onDownloadReady() {
        self.mediaDownloadList = (self.mediaManager?.sdCardFileListSnapshot())!
        if(self.shouldStartImmediately) {
            self.appDelegate.flightImageCount = self.mediaDownloadList.count
        }
        self.statusLabel.text = "Downloading Image 1 of \(self.appDelegate.flightImageCount)"
        self.progressBar.setProgress(0.0, animated: true)
        self.startImageDownload()
    }
    
    func onPhotoReady() {
        didDownload = true
        self.statusLabel.text = "All Images Downloaded. Generating heatmaps..."
        self.statusLabel.setNeedsDisplay()
        stitchImages()
    }
    
    func onFileListRefresh() {}
    
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
    
    private func updateDroneStatus() {
        DJISDKManager.keyManager()?.getValueFor(DJIProductKey(param: DJIParamConnection)!, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
            if value != nil {
                if value!.boolValue {
                    // connected
                    self.droneConnected = true
                } else {
                    // disconnected
                    self.droneConnected = false
                }
            }
            
            if (self.droneConnected) {
                self.imageDownloader = MediaHandler(callback: self as CameraCallback, camera: self.fetchCamera()!)
                self.mediaManager = self.imageDownloader.fetchMediaManager()

                self.initialCameraCallback = InitialCameraCallback(camera: self.fetchCamera()!, viewController: self)
                self.initialCameraCallback.fetchInitialData()
                if (self.shouldStartImmediately) {
                    // Wait a short time so everything can be initialized.
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.500, execute: {() in
                        self.startDownload()
                    })
                }
            }
        })
    }

    func stitchImages() {
        self.titleLabel.text = "Stitching Images..."
        self.statusLabel.text = String(format: "Uploading image 1 of %d", mediaDownloadList.count)
        self.progressBar.setProgress(0, animated: true)
        var num = 0
        DispatchQueue.global(qos: .background).async {
            let requester = StitchRequester()
            requester.startStitch {
                DispatchQueue.main.async {
                    self.statusLabel.text = String("Started stitch.")
                    self.statusLabel.setNeedsDisplay()
                }
                let loader = ImageLoader()
                let images = loader.loadAssetImages(imageCount: self.appDelegate.flightImageCount)
                DispatchQueue.main.async {
                    self.statusLabel.text = String(format: "Images fetched: %d", images.count)
                    self.statusLabel.setNeedsDisplay()
                }
                requester.addImages(images: images, onImageSuccess: {
                    num = num + 1
                    DispatchQueue.main.async {
                        self.statusLabel.text = String(format: "Uploaded image %d of %d", num, self.appDelegate.flightImageCount)
                        self.progressBar.setProgress(Float(num) / Float(self.appDelegate.flightImageCount), animated: true)
                        self.statusLabel.setNeedsDisplay()
                    }
                    if num >= self.mediaDownloadList.count {
                        self.lockStitch(requester)
                    }
                }, onImageFailure: { (err) in
                    num = num + 1
                    let alert = UIAlertController(title: "Mission Error", message: err, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    DispatchQueue.main.async {
                        self.statusLabel.text = String(format: "Image upload failure", num)
                        self.statusLabel.setNeedsDisplay()
                    }
                })
            }
        }
    }
    
    private func lockStitch(_ requester: StitchRequester) {
        requester.lockStitch(onSuccess: { () in
            DispatchQueue.main.async {
                self.statusLabel.text = "Stitch locked! Waiting for completion..."
                self.statusLabel.setNeedsDisplay()
            }
            self.pollStitch(requester)
        }, onFailure: { () in
            DispatchQueue.main.async {
                self.statusLabel.text = "Could not lock stitch!"
                self.statusLabel.setNeedsDisplay()
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
                    self.statusLabel.text = "Stitch complete! Downloading..."
                    self.statusLabel.setNeedsDisplay()
                }
                self.retrieveStitch(requester)
            }
        }
    }
    
    private func retrieveStitch(_ requester: StitchRequester) {
        requester.retrieveResult { (data) in
            if data == nil {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Stitch download failed. Please try again."
                    self.statusLabel.setNeedsDisplay()
                }
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Generating heatmap from stitch. This may take a few moments..."
                    self.statusLabel.setNeedsDisplay()
                }
                let queue = DispatchQueue(label: "nvdi-queue")
                queue.async {
                    //let generator = HealthMapGenerator()
                    //self.stitchedImage = generator.GenerateHealthMap(img: UIImage(data: data!)!)
                    DispatchQueue.main.async {
                        self.stitchedImage = UIImage(data: data!)!
                        self.performSegue(withIdentifier: "showStitchSegue", sender: nil)
                    }
                }
                //self.stitchedImage = UIImage(data: data!)!
            }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationController = segue.destination as! StitchViewerViewController
        destinationController.toShow = self.stitchedImage
    }
}
