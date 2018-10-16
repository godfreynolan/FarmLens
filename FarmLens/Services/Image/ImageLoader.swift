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
            // TODO: Grab the images by more specific thing than just creationDate
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
        
        for index in 0...results.count - 1 {
            let result = results[index]
            
            imageManager.requestImage(for: result, targetSize: CGSize(width: CGFloat(800), height: CGFloat(600)), contentMode: .aspectFill, options: imageOptions, resultHandler: { (uiImage, info) in
                loadedImages.append(DroneImage(location: result.location!, image: uiImage!))
            })
        }
        
        return loadedImages
    }
    
    func loadAssetImages(imageCount: Int) -> [Data] {
        var loadedImages: [Data] = []
        
        if imageCount == 0 {
            return loadedImages
        }
        
        let imageManager = PHImageManager.default()
        let options = PHFetchOptions()
        options.sortDescriptors = [
            // TODO: Grab the images by more specific thing than just creationDate
            NSSortDescriptor(key:"creationDate", ascending: false)
        ]
        options.includeAssetSourceTypes = .typeUserLibrary
        options.fetchLimit = imageCount
        options.includeAllBurstAssets = false
        options.includeHiddenAssets = false
        
        let results = PHAsset.fetchAssets(with: .image, options: options)
        
        for index in 0...results.count - 1 {
            //loadedImages.append(results[index])
            let opts = PHImageRequestOptions()
            opts.isSynchronous = true
            imageManager.requestImageData(for: results[index], options: opts,
                resultHandler: { (data, str, orientation, info) -> Void in
                    let image = UIImage(data: data!)!
                    let pngImageData = UIImagePNGRepresentation(image)!
                    loadedImages.append(pngImageData)
            })
        }
        
        return loadedImages
    }
}
