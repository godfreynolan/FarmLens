//
//  DroneImageDownloader.swift
//  FarmLens
//
//  Created by Tom Kocik on 2/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import DJISDK

class DroneImageDownloader: NSObject, DJICameraDelegate, DJIMediaManagerDelegate {
    private var camera: DJICamera?
    private var mediaManager: DJIMediaManager?
    
    init(camera: DJICamera) {
        super.init()
        self.camera = camera
        self.camera?.delegate = self
        self.mediaManager = self.camera?.mediaManager
        self.mediaManager?.delegate = self
    }
    
    func startMediaDownload() {
        self.camera?.setMode(.mediaDownload, withCompletion: { (error) in
            if (error != nil) {
                print("There were errors starting the download: " + (error?.localizedDescription)!)
            }
        })
    }
    
    func endMediaDownload() {
        self.camera?.setMode(.shootPhoto, withCompletion: { (error) in
            if (error != nil) {
                print("There were errors ending the download: " + (error?.localizedDescription)!)
            }
        })
    }
    
    func retrieveMediaFiles() {
        if (self.mediaManager?.fileListState == .syncing || self.mediaManager?.fileListState == .deleting) {
            print("Media Manager is busy.");
        } else {
            self.mediaManager?.refreshFileList(completion: { (error) in
                if (error != nil) {
                    print("Fetch media file list failed: " + (error?.localizedDescription)!)
                } else {
                    print("Fetch media file success")
                    let mediaFileList = self.mediaManager?.fileListSnapshot()
                    
                    let taskScheduler = self.mediaManager?.taskScheduler
                    taskScheduler?.suspendAfterSingleFetchTaskFailure = false
                    taskScheduler?.resume(completion: nil)
                    
                    let lastFile = mediaFileList?.last
                    self.downloadImage(file: lastFile!)
                    
//                    for mediaFile in mediaFileList! {
//                        if (mediaFile.thumbnail == nil) {
//                            let task = DJIFetchMediaTask.init(file: mediaFile, content: .thumbnail, andCompletion: { (file, content, error) in
//                                //Reload the data?
//                            })
//
//                            taskScheduler?.moveTask(toEnd: task)
//                        }
//                    }
                }
            })
        }
    }
    
    private func downloadImage(file: DJIMediaFile) {
        let isPhoto = file.mediaType == .JPEG || file.mediaType == .TIFF;
        if (!isPhoto) {
            return
        }
        
        var mutableData: NSMutableData? = nil
        var previousOffset = 0
        
        file.fetchData(withOffset: UInt(previousOffset), update: DispatchQueue.main, update: { (data, isComplete, error) in
            if (error != nil) {
                print("Download failed: " + (error?.localizedDescription)!)
                return
            }
            
            if (mutableData == nil) {
                mutableData = data as? NSMutableData
            } else {
                mutableData?.append(data!)
            }
            
            previousOffset += (data?.count)!;
            //float progress = target.previousOffset * 100.0 / target.selectedMedia.fileSizeInBytes;
            //[target.statusAlertView updateMessage:[NSString stringWithFormat:@"Downloading: %0.1f%%", progress]];
            if (previousOffset == file.fileSizeInBytes && isComplete) {
                //[target dismissStatusAlertView];
                if (isPhoto) {
                    self.saveImage(data: mutableData!)
                }
            }
        })
    }
    
    private func saveImage(data: NSData) {
        let image = UIImage.init(data: data as Data)
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
        
        print(message)
        
//        if (self.statusAlertView == nil) {
//            self.statusAlertView = [DJIAlertView showAlertViewWithMessage:message titles:@[@"Dismiss"] action:^(NSUInteger buttonIndex) {
//                WeakReturn(target);
//                if (buttonIndex == 0) {
//                [target dismissStatusAlertView];
//                }
//                }];
//        }
    }
}
