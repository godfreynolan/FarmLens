//
//  File.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import DJISDK

class MockCamera: DJICamera {
    override init() {
        
    }
    
    override func setMode(_ mode: DJICameraMode, withCompletion completion: DJICompletionBlock? = nil) {
        completion?(nil)
    }
    
    override var mediaManager: DJIMediaManager? {
        get {
            return MockMediaManager()
        }
        set {
            
        }
    }
}
