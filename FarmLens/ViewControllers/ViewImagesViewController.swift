//
//  MapboxActivity.swift
//  FarmLens
//
//  Created by Ian Timmis on 2/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import CoreLocation
import Mapbox
import Photos

class ViewImagesViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private let imageLoader = ImageLoader()
    private let imageTiler = ImageTiler()
    private let locManager = CLLocationManager()
    
    private var mapStyle: MGLStyle!
    
    @IBOutlet weak var mapView: MGLMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.requestWhenInUseAuthorization()
        locManager.startUpdatingLocation()
        
        PHPhotoLibrary.requestAuthorization { (status) in
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.mapView.styleURL = MGLStyle.satelliteStreetsStyleURL()
        self.mapView.showsUserLocation = true
        
        // Set the map view‘s delegate property.
        self.mapView.delegate = self
    }
    
    @IBAction func loadImages(_ sender: Any) {
        var imagesShown = false
        
        if self.appDelegate.actualPictureCount == 0 {
            let alert = UIAlertController(title: "Error", message: "There are no pictures to show. Please download the images first!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        } else {
            let images = imageLoader.loadImages(imageCount: self.appDelegate.actualPictureCount)
            imagesShown = self.imageTiler.overlayImages(mapView: mapView, style: self.mapStyle, images: images)
        }
        
        if !imagesShown {
            let alert = UIAlertController(title: "Image Loading Error", message: "There are no pictures to show. Please download the images first!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapStyle = style
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.mapView.setCenter((locations.last?.coordinate)!, zoomLevel: 18, animated: true)
        // We don't want the map changing while the user is trying to view images.
        self.locManager.stopUpdatingLocation()
    }
}
