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
    
    private let imageLoader = ImageLoader()
    private let imageTiler = ImageTiler()
    private let locManager = CLLocationManager()
    
    private var mapStyle: MGLStyle!
    private var masterViewController: MasterViewController!
    
    @IBOutlet weak var mapView: MGLMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.masterViewController = self.splitViewController?.viewControllers.first?.childViewControllers.first as! MasterViewController
        
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
        
        if self.masterViewController.flightCoordinateList.isEmpty {
            let alert = UIAlertController(title: "Error", message: "There are no pictures to show. Please download the images first!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        } else {
            let images = imageLoader.loadImages(imageCount: self.masterViewController.flightCoordinateList.count)
            imagesShown = self.imageTiler.overlayImages(mapView: mapView, style: self.mapStyle, imageLocations: self.masterViewController.flightCoordinateList.reversed(), images: images)
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
