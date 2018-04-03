//
//  ImageLoader.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Photos

class ImageLoader {
    func loadImages(imageCount: Int) -> [DroneImage] {
        var loadedImages: [DroneImage] = []
        
        if imageCount == 0 {
            return loadedImages
        }
        
        let imageManager = PHImageManager.default()
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key:"creationDate", ascending: false)
        ]
        options.includeAssetSourceTypes = .typeUserLibrary
        options.fetchLimit = imageCount
        options.includeAllBurstAssets = false
        options.includeHiddenAssets = false
        
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
    
    func loadImagesForProcessing(batchSize: Int, imageCount: Int, iter: Int) -> [DroneImage] {
        var loadedImages: [DroneImage] = []
        
        if imageCount == 0 {
            return loadedImages
        }
        
        let imageManager = PHImageManager.default()
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key:"creationDate", ascending: false)
        ]
        options.includeAssetSourceTypes = .typeUserLibrary
        // Number of pre-processed images plus current post-processed images
        options.fetchLimit = imageCount + batchSize * iter
        options.includeAllBurstAssets = false
        options.includeHiddenAssets = false
        
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
    
    func deleteOldImages(imageCount: Int) {
        if imageCount == 0 {
            return
        }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key:"creationDate", ascending: false)
        ]
        options.includeAssetSourceTypes = .typeUserLibrary
        options.fetchLimit = imageCount * 2
        options.includeAllBurstAssets = false
        options.includeHiddenAssets = false
        
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
}
