//
//  MapboxActivity.swift
//  FarmLens
//
//  Created by Ian Timmis on 2/20/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Mapbox

class MapboxViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    
//    @IBOutlet weak var btnTest: UIButton!
//    @IBOutlet weak var lblTestLabel: UILabel!
    
    let locManager = CLLocationManager()
    
    var droneMarker: MGLPointAnnotation? = nil
    var mapView: MGLMapView? = nil
    
    var startLat = 0.0
    var startLong = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.requestWhenInUseAuthorization()
        locManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.satelliteStreetsStyleURL())
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.tintColor = .darkGray
        
        var currentLocation: CLLocation!
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ) {
            currentLocation = locManager.location
            startLat = currentLocation.coordinate.latitude
            startLong = currentLocation.coordinate.longitude
        }
        
        // Set the map's bounds to Pisa, Italy.
        let bounds = MGLCoordinateBounds(
            sw: CLLocationCoordinate2D(latitude: (startLat - 0.0005), longitude: (startLong - 0.01)),
            ne: CLLocationCoordinate2D(latitude: (startLat + 0.0005), longitude: (startLong + 0.01)))
        mapView?.setVisibleCoordinateBounds(bounds, animated: false)
        
        view.addSubview(mapView!)

        //        self.view.bringSubview(toFront: lblTestLabel)
        //        self.view.bringSubview(toFront: btnTest)
        //        let drone = DroneModel(homeElevation: 0.0)
        //        lblTestLabel.text = "Coordinates: \(drone.latitude),\(drone.longitude)"
        
        UpdateMarker()
        
        // Set the map view‘s delegate property.
        mapView?.delegate = self
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        
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
        
        if (ImageTiler().OverlayImages(mapView: mapView, style: style, imageLocations: imageLocations, images: images))
        {
            // success
        }
        else
        {
            // failure
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        startLat = location.coordinate.latitude
        startLong = location.coordinate.longitude
        UpdateMarker()
    }
    
    
//    @IBAction func btnTestPressed(_ sender: Any) {
//        startLat += 0.1
//        startLong += 0.1
//        UpdateMarker(latitude: startLat, longitude: startLong)
//    }
    
    
    func UpdateMarker()
    {
        if droneMarker != nil
        {
            mapView?.removeAnnotation(droneMarker!)
        }
        
        // Initialize and add the point annotation.
        droneMarker = MGLPointAnnotation()
        droneMarker?.coordinate = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
        //pisa.title = "Leaning Tower of Pisa"
        mapView?.addAnnotation(droneMarker!)
        
        // Set the map's bounds
//        let bounds = MGLCoordinateBounds(
//            sw: CLLocationCoordinate2D(latitude: (startLat - 0.0005), longitude: (startLong - 0.01)),
//            ne: CLLocationCoordinate2D(latitude: (startLat + 0.0005), longitude: (startLong + 0.01)))
//        mapView?.setVisibleCoordinateBounds(bounds, animated: false)
    }
    
//    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
//        // Try to reuse the existing ‘pisa’ annotation image, if it exists.
//        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "drone")
//
//        if annotationImage == nil {
//            // Leaning Tower of Pisa by Stefan Spieler from the Noun Project.
//            var image = UIImage(named: "aircraft")!
//
//            let size = CGSize(width: 60, height: 60)
//            image = resizeImage(image: image, targetSize: size)
//
//            // The anchor point of an annotation is currently always the center. To
//            // shift the anchor point to the bottom of the annotation, the image
//            // asset includes transparent bottom padding equal to the original image
//            // height.
//            //
//            // To make this padding non-interactive, we create another image object
//            // with a custom alignment rect that excludes the padding.
//            image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image.size.height/2, right: 0))
//
//            // Initialize the ‘pisa’ annotation image with the UIImage we just loaded.
//            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "drone")
//        }
//
//        return annotationImage
//    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        
        if (widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
