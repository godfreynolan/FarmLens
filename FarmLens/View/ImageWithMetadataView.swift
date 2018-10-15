//
//  ImageWithMetadataView.swift
//  FarmLens
//
//  Created by Administrator on 10/15/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit

class ImageWithMetadataView: UIView {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var numPics: UILabel!
    
    public struct ImageMetadata {
        var date: String? = nil
        var time: String? = nil
        var numPics: Int = 0
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    /// Set the metadata that appears below the image
    func setMetadata(metadata data: ImageMetadata) {
        self.date.text = data.date
        self.time.text = data.time
        self.numPics.text = String(format: "%d", data.numPics)
        self.setNeedsDisplay()
    }
    
    /// Sets the image that appears at the top of the view.
    func setImage(image img: UIImage?) {
        self.image.image = img
        self.setNeedsDisplay()
    }

}
