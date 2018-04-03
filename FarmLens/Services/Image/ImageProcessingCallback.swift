//
//  ImageProcessingCallback.swift
//  FarmLens
//
//  Created by Tom Kocik on 4/3/18.
//  Copyright © 2018 DJI. All rights reserved.
//

protocol ImageProcessingCallback {
    func onBatchComplete(completedIter: Int)
    func onImageComplete()
}
