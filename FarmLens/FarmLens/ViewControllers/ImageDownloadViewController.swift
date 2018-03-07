//
//  ImageDownloadViewController.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK

class ImageDownloadViewController: UIViewController, DJIMediaManagerDelegate {
    private var camera: DJICamera?
    private var currentDownloadIndex = 0
    private var masterViewController: MasterViewController!
    private var mediaDownloadList: [DJIMediaFile] = []
    private var mediaManager: DJIMediaManager?
    private var statusIndex = 0
    private var totalImageCount = 0
    
    @IBOutlet weak var totalDownloadImageLabel: UILabel!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        self.masterViewController = self.splitViewController?.viewControllers.first?.childViewControllers.first as! MasterViewController
        self.totalImageCount = self.masterViewController.boundaryCoordinateList.count
    }
    
    override func viewDidLoad() {
        UIApplication.shared.isIdleTimerDisabled = true
        super.viewDidLoad()
        
        self.camera = fetchCamera()
        self.mediaManager = self.camera?.mediaManager
        self.mediaManager?.delegate = self
        
        if self.totalImageCount == 0 {
            self.totalDownloadImageLabel.text = "0 Images to download"
            self.downloadProgressLabel.text = "No images to download"
        } else if self.totalImageCount == 1 {
            self.totalDownloadImageLabel.text = "1 Image to download"
            self.downloadProgressLabel.text = "Ready to download"
        } else {
            self.totalDownloadImageLabel.text = "\(totalImageCount) Images to download"
            self.downloadProgressLabel.text = "Ready to download"
        }
    }
    
    @IBAction func downloadPictures(_ sender: UIButton) {
        startMediaDownload()
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
    
    private func startMediaDownload() {
        self.camera?.setMode(.mediaDownload, withCompletion: { (error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Camera Error", message: "Please verify connection to the drone. If connected, please verify the drone is nearby.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.retrieveMediaFiles()
            }
        })
    }
    
    func endMediaDownload() {
        self.camera?.setMode(.shootPhoto, withCompletion: { (error) in
            if (error == nil) {
                self.downloadProgressLabel.text = "All Images Downloaded"
            }
        })
    }
    
    func retrieveMediaFiles() {
        if (self.mediaManager?.fileListState == .syncing || self.mediaManager?.fileListState == .deleting) {
            let alert = UIAlertController(title: "Camera Error", message: "Please verify the drone is idle.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.mediaManager?.refreshFileList(completion: { (error) in
                if (error != nil) {
                    let alert = UIAlertController(title: "Camera Error", message: "Please verify the drone is idle.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.downloadProgressLabel.text = "Downloading Image 1 of \(self.totalImageCount)"
                    self.startImageDownload()
                }
            })
        }
    }
    
    private func startImageDownload() {
        if (self.mediaManager?.fileListState != .upToDate && self.mediaManager?.fileListState != .incomplete) {
            let alert = UIAlertController(title: "Camera Error", message: "Please verify the drone is idle.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        mediaDownloadList = (self.mediaManager?.fileListSnapshot())!
        let listCount = mediaDownloadList.count

        self.currentDownloadIndex = 0
        self.statusIndex = 1
        if listCount > self.masterViewController.boundaryCoordinateList.count {
            self.currentDownloadIndex = listCount - self.totalImageCount
        }

        downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
    }
    
    private func downloadImage(file: DJIMediaFile) {
        let isPhoto = file.mediaType == .JPEG || file.mediaType == .TIFF;
        if (!isPhoto) {
            return
        }
        
        var mutableData: Data? = nil
        var previousOffset = 0
        
        file.fetchData(withOffset: UInt(previousOffset), update: DispatchQueue.main, update: { (data, isComplete, error) in
            if (error != nil) {
                return
            }
            
            if (mutableData == nil) {
                mutableData = data
            } else {
                mutableData?.append(data!)
            }
            
            previousOffset += (data?.count)!;
            if (previousOffset == file.fileSizeInBytes && isComplete) {
                self.saveImage(data: mutableData!)
                
                self.statusIndex += 1
                self.currentDownloadIndex += 1
                self.downloadProgressLabel.text = "Downloading Image \(self.statusIndex) of \(self.totalImageCount)"

                if (self.currentDownloadIndex < self.mediaDownloadList.count) {
                    self.downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
                } else {
                    self.endMediaDownload()
                }
            }
        })
    }
    
    private func saveImage(data: Data) {
        let image = UIImage(data: data)
        UIImageWriteToSavedPhotosAlbum(image!, self, #selector(errorSaving(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func errorSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer) {
        if (error != nil) {
            let message = String("Save Image Failed! Error: " + (error?.localizedDescription)!);
            let alert = UIAlertController(title: "Download Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
