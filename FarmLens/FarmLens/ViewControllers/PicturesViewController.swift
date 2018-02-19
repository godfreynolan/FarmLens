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
    var step = 0
    
    @IBOutlet var outputLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetUI()
        
        self.camera = fetchCamera()
        self.camera?.delegate = self
        self.mediaManager = self.camera?.mediaManager
        self.mediaManager?.delegate = self
        
        startMediaDownload()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        endMediaDownload()
    }
    
    @IBAction func takePictureAndDownload(_ sender: UIButton) {
        switch step {
        case 0:
            retrieveMediaFiles()
        case 1:
            do {
                try startImageDownload()
            } catch {
                log(info: error.localizedDescription)
            }
        default:
            log(info: "Reset the output!")
        }
        
        
        retrieveMediaFiles()
    }
    
    func resetUI() {
        outputLabel.text = "Output:"
        step = 0
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
    
    func startMediaDownload() {
        self.camera?.setMode(.mediaDownload, withCompletion: { (error) in
            if (error != nil) {
                self.log(info: "There were errors starting the download: " + (error?.localizedDescription)!)
            } else {
                self.log(info: "Ready to download")
            }
        })
    }
    
    func endMediaDownload() {
        self.camera?.setMode(.shootPhoto, withCompletion: { (error) in
            if (error != nil) {
                self.log(info: "There were errors ending the download: " + (error?.localizedDescription)!)
            }
        })
    }
    
    func retrieveMediaFiles() {
        if (self.mediaManager?.fileListState == .syncing || self.mediaManager?.fileListState == .deleting) {
            self.log(info: "Media Manager is busy.");
            
            switch self.mediaManager?.fileListState {
            case .deleting?:
                self.log(info: "System Deleting")
            case .syncing?:
                self.log(info: "System Syncing")
            case .reset?:
                self.log(info: "System Reset")
            case .unknown?:
                self.log(info: "System Unknown")
            case .upToDate?:
                self.log(info: "System up to date?")
            case .incomplete?:
                self.log(info: "System incomplete?")
            default:
                self.log(info: "System Really Really Unknown")
            }
        } else {
            if (mediaManager?.fileListSnapshot() != nil) {
                self.log(info: "Already got the files")
                self.step = 1
                return
            }
            
            self.mediaManager?.refreshFileList(completion: { (error) in
                if (error != nil) {
                    self.log(info: "Fetch media file list failed: " + (error?.localizedDescription)!)
                } else {
                    self.step = 1
                }
            })
        }
    }
    
    private func startImageDownload() {
        if (self.mediaManager?.fileListState != .upToDate && self.mediaManager?.fileListState != .incomplete) {
            self.log(info: "System is busy")
            
            switch self.mediaManager?.fileListState {
            case .deleting?:
                self.log(info: "System Deleting")
            case .syncing?:
                self.log(info: "System Syncing")
            case .reset?:
                self.log(info: "System Reset")
            case .unknown?:
                self.log(info: "System Unknown")
            case .upToDate?:
                self.log(info: "System up to date?")
            case .incomplete?:
                self.log(info: "System incomplete?")
            default:
                self.log(info: "System Really Really Unknown")
            }
            return
        }
        
        let mediaFileList = self.mediaManager?.fileListSnapshot()
        
        if (mediaFileList == nil) {
            self.log(info: "The file list is gone?")
            return
        }
        
        let lastFile = mediaFileList?.last
        if (lastFile != nil) {
            self.downloadImage(file: lastFile!)
        }
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
                self.log(info: "Finished getting the data")
                if (isPhoto) {
                    self.saveImage(data: mutableData!)
                }
            }
        })
    }
    
    private func saveImage(data: Data) {
        let image = UIImage.init(data: data)
        
        do {
            try UIImageWriteToSavedPhotosAlbum(image!, self, #selector(errorSaving(_:didFinishSavingWithError:contextInfo:)), nil)
        } catch {
            self.log(info: error.localizedDescription)
        }
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
