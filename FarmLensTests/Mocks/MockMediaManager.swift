//
//  MockMediaManager.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import DJISDK

class MockMediaManager: DJIMediaManager {
    override init() {
    }
    
    override func refreshFileList(completion: DJICompletionBlock? = nil) {
        completion?(nil)
    }
    
    private var privateFileListState: DJIMediaFileListState = .unknown
    override var fileListState: DJIMediaFileListState{
        get {
            return privateFileListState
        }
        set {
            self.privateFileListState = newValue
        }
    }
}
