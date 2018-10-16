//
//  StitchViewerViewController.swift
//  FarmLens
//
//  Created by Administrator on 10/15/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit

class StitchViewerViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    public var toShow: UIImage? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = toShow
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self // fallback to viewForZoomingInScrollView
        
        let gen = HealthMapGenerator()
        imageView.image = gen.GenerateHealthMap(img: toShow!)
        // Do any additional setup after loading the view.
    }
    
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
