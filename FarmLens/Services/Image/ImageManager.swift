//
//  ImageLoader.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Photos

class ImageManager {
    private let batchSize = 5
    
    func deleteOldImages(imageCount: Int) {
        if imageCount == 0 {
            return
        }
        
        let options = self.getFetchOptions(fetchLimit: imageCount * 2)
        let results = PHAsset.fetchAssets(with: .image, options: options)
        
        var resultsToDelete = [PHAsset]()
        
        for index in imageCount..<imageCount * 2 {
            resultsToDelete.append(results[index])
        }
        
        let library = PHPhotoLibrary.shared()
        
        do {
            try library.performChangesAndWait {
                PHAssetChangeRequest.deleteAssets(resultsToDelete as NSArray)
            }
        } catch {
            
        }
    }
    
    func generateNdviImages(imageCount: Int, iter: Int, callback: ImageProcessingCallback) {
        let images = self.loadImagesForProcessing(batchSize: self.batchSize, imageCount: imageCount, iter: iter)
        
        for index in 0..<images.count {
            self.generateNdviImage(droneImage: images[index], callback: callback)
            
            DispatchQueue.main.async {
                callback.onBatchComplete(completedIter: iter)
            }
        }
    }
    
    func generateNdviImage(droneImage: DroneImage, callback: ImageProcessingCallback) {
        let gen = HealthMapGenerator()
        
        let location = CLLocation(latitude: droneImage.getLocation().latitude, longitude: droneImage.getLocation().longitude)
        
        let ndviImage = gen.GenerateHealthMap(img: droneImage.getImage())
        
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: ndviImage)
            creationRequest.location = location
        }, completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    callback.onImageComplete()
                }
            }
        })
    }
    
    func loadImagesForProcessing(batchSize: Int, imageCount: Int, iter: Int) -> [DroneImage] {
        var loadedImages: [DroneImage] = []
        
        if imageCount == 0 {
            return loadedImages
        }
        
        let imageManager = PHImageManager.default()
        
        // Number of pre-processed images plus current post-processed images
        let options = self.getFetchOptions(fetchLimit: imageCount + batchSize * iter)
        let results = PHAsset.fetchAssets(with: .image, options: options)
        
        let imageOptions = PHImageRequestOptions()
        imageOptions.isSynchronous = true
        imageOptions.resizeMode = .exact
        
        // Skip the post process images AND the already processed images
        let startingIndex = batchSize * iter * 2
        
        // Ending index is batchSize less then the start, or whatever is left
        let endingIndex = startingIndex + min(batchSize, imageCount - batchSize * iter)
        
        for index in startingIndex ..< endingIndex {
            let result = results[index]
            
            imageManager.requestImage(for: result, targetSize: CGSize(width: CGFloat(4000), height: CGFloat(3000)), contentMode: .aspectFill, options: imageOptions, resultHandler: { (uiImage, info) in
                loadedImages.append(DroneImage(location: result.location!, image: uiImage!))
            })
        }
        
        return loadedImages
    }
    
    func loadTileImages(imageCount: Int) -> [DroneImage] {
        var loadedImages: [DroneImage] = []
        
        if imageCount == 0 {
            return loadedImages
        }
        
        let imageManager = PHImageManager.default()
        
        let options = self.getFetchOptions(fetchLimit: imageCount)
        let results = PHAsset.fetchAssets(with: .image, options: options)
        
        let imageOptions = PHImageRequestOptions()
        imageOptions.isSynchronous = true
        imageOptions.resizeMode = .exact
        
        for index in 0..<results.count {
            let result = results[index]
            
            imageManager.requestImage(for: result, targetSize: CGSize(width: CGFloat(400), height: CGFloat(300)), contentMode: .aspectFill, options: imageOptions, resultHandler: { (uiImage, info) in
                loadedImages.append(DroneImage(location: result.location!, image: uiImage!))
            })
        }
        
        return loadedImages
    }
    
    private func getFetchOptions(fetchLimit: Int) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key:"creationDate", ascending: false)
        ]
        options.includeAssetSourceTypes = .typeUserLibrary
        options.fetchLimit = fetchLimit
        options.includeAllBurstAssets = false
        options.includeHiddenAssets = false
        
        return options
    }
}
