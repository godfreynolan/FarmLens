//
//  PicturesViewController.swift
//  FarmLens
//
//  Created by Tom Kocik on 2/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK

class PicturesViewController: UIViewController, DJICameraDelegate, DJIMediaManagerDelegate {
    var camera: DJICamera?
    var mediaManager: DJIMediaManager?
    var mediaDownloadList: [DJIMediaFile] = []
    var currentDownloadIndex = 0
    
    @IBOutlet var outputLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetUI()
        
        self.camera = fetchCamera()
        self.camera?.delegate = self
        self.mediaManager = self.camera?.mediaManager
        self.mediaManager?.delegate = self
    }
    
    @IBAction func downloadPictures(_ sender: UIButton) {
        resetUI()
        startMediaDownload()
    }
    
    @IBAction func takePicture(_ sender: UIButton) {
        resetUI()
        takeSinglePhoto()
    }
    
    func resetUI() {
        outputLabel.text = "Output:"
    }
    
    // This is not currently used, but was proven to work.
    func takeSinglePhoto() {
        camera?.setShootPhotoMode(.single, withCompletion: {
            (error) in DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.camera?.startShootPhoto(completion: { (error) in
                    if (error != nil) {
                        self.log(info: (error?.localizedDescription)!)
                    } else {
                        self.log(info: "Took a picture")
                    }
                })
            }
        })
    }
    
    func fetchCamera() -> DJICamera? {
        if (DJISDKManager.product() == nil) {
            return nil;
        }
        
        if (DJISDKManager.product() is DJIAircraft) {
            return (DJISDKManager.product() as? DJIAircraft)?.camera;
        }
        
        return nil;
    }
    
    private func startMediaDownload() {
        self.camera?.setMode(.mediaDownload, withCompletion: { (error) in
            if (error != nil) {
                self.log(info: "There were errors starting the download: " + (error?.localizedDescription)!)
            } else {
                self.log(info: "Download ready")
                self.retrieveMediaFiles()
            }
        })
    }
    
    func endMediaDownload() {
        self.camera?.setMode(.shootPhoto, withCompletion: { (error) in
            if (error != nil) {
                self.log(info: "There were errors ending the download: " + (error?.localizedDescription)!)
            } else {
                self.log(info: "All downloads complete")
            }
        })
    }
    
    func retrieveMediaFiles() {
        if (self.mediaManager?.fileListState == .syncing || self.mediaManager?.fileListState == .deleting) {
            self.log(info: "Media Manager is busy.");
        } else {
            self.mediaManager?.refreshFileList(completion: { (error) in
                if (error != nil) {
                    self.log(info: "Fetch media file list failed: " + (error?.localizedDescription)!)
                } else {
                    self.log(info: "Starting download")
                    self.startImageDownload()
                }
            })
        }
    }
    
    private func startImageDownload() {
        if (self.mediaManager?.fileListState != .upToDate && self.mediaManager?.fileListState != .incomplete) {
            self.log(info: "System is busy")
            return
        }
        
        mediaDownloadList = (self.mediaManager?.fileListSnapshot())!
        let listCount = mediaDownloadList.count
        
        self.currentDownloadIndex = 0
        if listCount > 5 {
            self.currentDownloadIndex = listCount - 5
        }
        
        self.log(info: "Currently downloading file number \(self.currentDownloadIndex)")
        
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
                self.log(info: "Download failed: " + (error?.localizedDescription)!)
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
                self.currentDownloadIndex += 1
                
                if (self.currentDownloadIndex < self.mediaDownloadList.count) {
                    self.log(info: "Currently downloading file number \(self.currentDownloadIndex)")
                    self.downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
                } else {
                    self.log(info: "All downloads complete")
                    self.endMediaDownload()
                }
            }
        })
    }
    
    private func saveImage(data: Data) {
        let image = UIImage.init(data: data)
        UIImageWriteToSavedPhotosAlbum(image!, self, #selector(errorSaving(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func errorSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer) {
        var message = "";
        if (error != nil)
        {
            message = String("Save Image Failed! Error: " + (error?.localizedDescription)!);
        }
        else
        {
            message = "Saved to Photo Album";
        }
        
        self.log(info: message)
    }
    
    private func log(info: String) {
        let existingText = outputLabel.text;
        
        outputLabel.text = existingText! + "\n" + info
    }
}
