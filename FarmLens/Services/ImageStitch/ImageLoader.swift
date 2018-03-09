//
//  ImageLoader.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Photos

class ImageLoader {
    func loadImages(imageCount: Int) -> [UIImage] {
        var loadedImages: [UIImage] = []
        
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
        
        for index in 0...results.count - 1 {
            let result = results[index]
            
            imageManager.requestImage(for: result, targetSize: CGSize(width: 480.0, height: 360.0), contentMode: .aspectFit, options: imageOptions, resultHandler: { (uiImage, info) in
                loadedImages.append(uiImage!)
            })
        }
        
        return loadedImages
    }
}