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
            imagesShown = loadTestImages()
        } else {
            let images = imageLoader.loadImages(imageCount: self.masterViewController.flightCoordinateList.count)
            imagesShown = self.imageTiler.overlayImages(mapView: mapView, style: self.mapStyle, imageLocations: self.masterViewController.flightCoordinateList, images: images)
        }
        
        if !imagesShown {
            let alert = UIAlertController(title: "Image LoadingError", message: "There are no pictures to show. Please download the images first!", preferredStyle: .alert)
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
    
    private func loadTestImages() -> Bool {
        let loc_145 = CLLocationCoordinate2DMake(42.5450032416955, -83.1183242941811) // 145
        let loc_146 = CLLocationCoordinate2DMake(42.5448934989812, -83.1183242941811)
        let loc_147 = CLLocationCoordinate2DMake(42.5448934989812, -83.1182145514668)
        let loc_148 = CLLocationCoordinate2DMake(42.5450032416955, -83.1182145514668)
        let loc_149 = CLLocationCoordinate2DMake(42.5451129844098, -83.1182145514668)
        let loc_150 = CLLocationCoordinate2DMake(42.5451129844098, -83.1181048087525)
        let loc_151 = CLLocationCoordinate2DMake(42.5450032416955, -83.1181048087525)
        let loc_152 = CLLocationCoordinate2DMake(42.5448934989812, -83.1181048087525)
        let loc_153 = CLLocationCoordinate2DMake(42.5448934989812, -83.1179950660382)
        let loc_154 = CLLocationCoordinate2DMake(42.5450032416955, -83.1179950660382)
        let loc_155 = CLLocationCoordinate2DMake(42.5451129844098, -83.1179950660382)
        let loc_156 = CLLocationCoordinate2DMake(42.5450032416955, -83.1178853233239)
        let loc_157 = CLLocationCoordinate2DMake(42.5448934989812, -83.1178853233239)
        let loc_158 = CLLocationCoordinate2DMake(42.5448934989812, -83.1177755806096)
        let loc_159 = CLLocationCoordinate2DMake(42.5450032416955, -83.1177755806096)
        let loc_160 = CLLocationCoordinate2DMake(42.5450032416955, -83.1176658378953)
        let loc_161 = CLLocationCoordinate2DMake(42.5448934989812, -83.1176658378953) // 161
        
        let imageLocations:[CLLocationCoordinate2D] = [loc_145,loc_146,loc_147,loc_148,loc_149,
                                                       loc_150,loc_151,loc_152,loc_153,loc_154,
                                                       loc_155,loc_156,loc_157,loc_158,loc_159,
                                                       loc_160,loc_161]
        
        var images = [UIImage]()
        
        for idx in 145...161 {
            let img = UIImage(named: "DJI_0\(idx).JPG")!
            images.append(img)
        }
        
        return self.imageTiler.overlayImages(mapView: mapView, style: self.mapStyle, imageLocations: imageLocations, images: images)
    }
}
