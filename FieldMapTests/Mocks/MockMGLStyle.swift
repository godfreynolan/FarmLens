//
//  MockMGLStyle.swift
//  FarmLensTests
//
//  Created by Tom Kocik on 3/16/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Mapbox

class MockMGLStyle: MGLStyle {
    override func addSource(_ source: MGLSource) {
        //Do nothing
    }
    
    override func setImage(_ image: UIImage, forName name: String) {
        //Do nothing
    }
    
    override func insertLayer(_ layer: MGLStyleLayer, below sibling: MGLStyleLayer) {
        //Do nothing
    }
    
    override func layer(withIdentifier identifier: String) -> MGLStyleLayer? {
        return MGLBackgroundStyleLayer.init(identifier: "Test")
    }
}
