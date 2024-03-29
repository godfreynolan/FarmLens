//
//  MediaHandlerTest.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
@testable import FarmLens

class MediaHandlerTest: XCTestCase, CameraCallback {
    
    private var camera = MockCamera()
    private var downloader: MediaHandler!
    
    override func setUp() {
        super.setUp()
        
        self.downloader = MediaHandler(callback: self, camera: self.camera)
    }
    
    func testCallback() {
        self.downloader.setCameraToDownload()
    }
    
    func testError() {
        (self.camera.mediaManager as! MockMediaManager).fileListState = .syncing
        self.downloader.setCameraToDownload()
    }
    
    func onDownloadReady() {
        self.downloader.retrieveMediaFiles()
    }
    
    func onPhotoReady() {
        XCTAssert(true)
    }
    
    func onFileListRefresh() {
        self.downloader.setCameraToPhotoShoot()
    }
    
    func onError(error: Error?) {
        XCTAssertNil(error)
    }
    
}
