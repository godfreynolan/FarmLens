//
//  ImageLoaderTest.swift
//  FarmLensTests
//
//  Created by Ian Timmis on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import XCTest
@testable import FarmLens

class ImageLoaderTest: XCTestCase {
    
    var loader:ImageManager!
    
    override func setUp() {
        super.setUp()
        loader = ImageManager()
    }
    
    func testInit() {
        XCTAssertNotNil(loader)
    }
    
    func testLoadImagesNil() {
        XCTAssert(loader.loadTileImages(imageCount: 0).count == 0)
    }
}
