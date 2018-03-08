//
//  PicturesViewController.swift
//  FarmLens
//
//  Created by Tom Kocik on 2/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK
import Photos

class PicturesViewController: UIViewController, DJICameraDelegate, DJIMediaManagerDelegate {
    var camera: DJICamera?
    var mediaManager: DJIMediaManager?
    var mediaDownloadList: [DJIMediaFile] = []
    var currentDownloadIndex = 0
    var downloadedPictures: [UIImage] = []
    var statusIndex = 1
    
    @IBOutlet var outputLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        UIApplication.shared.isIdleTimerDisabled = true
        super.viewDidLoad()
        self.resetUI()
        
        self.camera = fetchCamera()
        self.camera?.delegate = self
        self.mediaManager = self.camera?.mediaManager
        self.mediaManager?.delegate = self
        
        PHPhotoLibrary.requestAuthorization { (status) in
            
        }
    }
    
    @IBAction func downloadPictures(_ sender: UIButton) {
        resetUI()
        startMediaDownload()
    }
    
    @IBAction func stitchPictures(_ sender: UIButton) {
        let imageManager = PHImageManager.default()
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key:"creationDate", ascending: false)
        ]
        options.includeAssetSourceTypes = .typeUserLibrary
        options.fetchLimit = 65
        options.includeAllBurstAssets = false
        options.includeHiddenAssets = false
        
        let results = PHAsset.fetchAssets(with: .image, options: options)
        
        if results.count == 0 {
            return
        }
        
        let imageOptions = PHImageRequestOptions()
        imageOptions.isSynchronous = true
        
        for index in 0...results.count - 1 {
            let result = results[index]
            imageManager.requestImage(for: result, targetSize: CGSize(width: 480.0, height: 360.0), contentMode: .aspectFit, options: imageOptions, resultHandler: { (uiImage, info) in
                self.downloadedPictures.append(uiImage!)
            })
        }
        
        let alert = UIAlertController.init(title: "Stitching", message: "", preferredStyle: .alert)
        self.present(alert, animated: true)
        
        DispatchQueue.global().async {
            //let stitchedImage = CVWrapper.process(with: self.downloadedPictures)
            
            DispatchQueue.main.async {
                alert.dismiss(animated: true, completion: nil)
                //self.imageView.image = stitchedImage
                //UIImageWriteToSavedPhotosAlbum(stitchedImage, self, #selector(self.errorSaving(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    func resetUI() {
        outputLabel.text = "Output:"
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
                self.log(info: "There were errors starting the download: " + (error?.localizedDescription)!)
            } else {
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
        self.statusIndex = 1
        if listCount > 66 {
            self.currentDownloadIndex = listCount - 66
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
                self.statusIndex += 1
                self.currentDownloadIndex += 1

                if (self.currentDownloadIndex < self.mediaDownloadList.count) {
                    self.downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
                } else {
                    self.log(info: "All downloads complete")
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
        var message = "";
        if (error != nil)
        {
            message = String("Save Image Failed! Error: " + (error?.localizedDescription)!);
        }
        
        self.log(info: message)
    }
    
    private func log(info: String) {
        let existingText = outputLabel.text;
        
        outputLabel.text = existingText! + "\n" + info
    }
}
