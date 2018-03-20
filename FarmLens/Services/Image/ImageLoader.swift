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
        
        for index in 0...results.count - 1 {
            let result = results[index]
            
            imageManager.requestImage(for: result, targetSize: CGSize(width: CGFloat(400), height: CGFloat(300)), contentMode: .aspectFill, options: imageOptions, resultHandler: { (uiImage, info) in
                loadedImages.append(DroneImage(location: result.location!, image: uiImage!))
            })
        }
        
        return loadedImages
    }
}
