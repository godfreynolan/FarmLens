//
//  StitchViewerViewController.swift
//  FarmLens
//
//  Created by Administrator on 10/15/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import Photos

class StitchViewerViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    
    public var toShow: UIImage? = nil
    private var savedTranslationX = CGFloat(0)
    private var savedTranslationY = CGFloat(0)
    private var imageView: UIImageView? = nil
    private var containerView: UIView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView = UIImageView(image: toShow)
        containerView = UIView(frame: imageView!.bounds)
        containerView!.addSubview(imageView!)
        scrollView.addSubview(containerView!)
        scrollView.contentSize = containerView!.frame.size
        
        scrollView.maximumZoomScale = 31.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = self
        scrollView.bounces = true
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView!
    }

    @IBAction func exitBtnClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "doneLookingAtPhoto", sender: nil)
    }
    
    @IBAction func saveBtnClicked(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: UIImagePNGRepresentation(self.toShow!)!, options: nil)
        }, completionHandler: { success, error in
            var message = ""
            if !success {
                message = String("Image couldn't be saved: " + (error?.localizedDescription)!);
            } else {
                message = "Image saved to Photos."
            }
            
            let alert = UIAlertController(title: "Save Image", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
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
