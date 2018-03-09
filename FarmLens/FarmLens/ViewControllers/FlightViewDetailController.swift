//
//  FlightViewDetailController.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK
import Mapbox

class FlightViewDetailController: UIViewController, MGLMapViewDelegate, DJICameraDelegate, DJIMediaManagerDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    private var boundaryCoordinateList: [CLLocationCoordinate2D] = []
    private var locationManager: CLLocationManager!
    private var boundaryPolygon: MGLPolygon?
    private var boundaryLine: MGLPolyline?
    private var flightPlanning: FlightPlanning!
    private var isFlightComplete = false
    private var masterViewController: MasterViewController!
    
    private var aircraftAnnotation = DJIImageAnnotation(identifier: "aircraftAnnotation")
    private var aircraftAnnotationView: MGLAnnotationView!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var batteryLifeLabel: UILabel!
    
    @IBOutlet weak var flightMapView: MGLMapView!
    
    override func viewWillAppear(_ animated: Bool) {
        self.masterViewController = self.splitViewController?.viewControllers.first?.childViewControllers.first as! MasterViewController
        self.flightPlanning = FlightPlanning()
        self.flightMapView.addAnnotation(self.aircraftAnnotation)
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                let newLocationValue = newValue!.value as! CLLocation
                
                if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
                    self.aircraftAnnotation.coordinate = newLocationValue.coordinate
                }
                
                self.latitudeLabel.text = String(format:"Lat: %.4f", newLocationValue.coordinate.latitude)
                self.longitudeLabel.text = String(format:"Long: %.4f", newLocationValue.coordinate.longitude)
                self.altitudeLabel.text = String(format:"Alt: %.4f ft", self.metersToFeet(newLocationValue.altitude))
            }
        }
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIBatteryKey(param: DJIBatteryParamChargeRemainingInPercent)!, withListener: self, andUpdate: { (oldValue, newValue) in
            if newValue != nil {
                self.batteryLifeLabel.text = "Battery Percentage: \(newValue!.unsignedIntegerValue) %"
            }
        })
        
        DJISDKManager.keyManager()?.getValueFor(DJIBatteryKey(param: DJIBatteryParamChargeRemainingInPercent)!, withCompletion: { [unowned self] (value: DJIKeyedValue?, error: Error?) in
            if value == nil {
                return
            }
            
            self.batteryLifeLabel.text = "Battery Percentage: \(value!.unsignedIntegerValue)%"
        })
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamCompassHeading)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if (newValue != nil) {
                self.aircraftAnnotation.heading = newValue!.doubleValue
                
                if (self.aircraftAnnotationView != nil) {
                    self.aircraftAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat(self.degreesToRadians(Double(self.aircraftAnnotation.heading))))
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            let alert = UIAlertController(title: "Location Services", message: "Location Services are not enabled.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        
        self.flightMapView.delegate = self
        self.flightMapView.styleURL = MGLStyle.satelliteStreetsStyleURL()
        self.flightMapView.showsUserLocation = true
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        self.flightMapView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "downloadImageSegue" && !self.isFlightComplete {
            
            if !self.isFlightComplete {
                let alert = UIAlertController(title: "Error", message: "There are no pictures to download. Please fly first!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                
                return false
            }
        }
        
        return true
    }
    
    @IBAction func startFlight(_ sender: Any) {
        if (self.boundaryCoordinateList.isEmpty) {
            let alert = UIAlertController(title: "Flight Path Error", message: "Please prepare a flight before attempting to fly.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        if (self.isFlightComplete) {
            let alert = UIAlertController(title: "Flight Error", message: "Please download your pictures before flying again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        self.masterViewController.flightCoordinateList = self.flightPlanning.calculateFlightPlan(boundingArea: self.boundaryPolygon!, spacingFeet: 95)
        let mission = self.flightPlanning.createMission(missionCoordinates: self.masterViewController.flightCoordinateList)
        
        DJISDKManager.missionControl()?.waypointMissionOperator().load(mission)
        
        DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toUploadEvent: self, with: .main, andBlock: { (event) in
            if event.error != nil {
                let alert = UIAlertController(title: "Mission Error", message: "Failed at uploading mission: \(event.error?.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else if event.currentState == .readyToExecute {
                DJISDKManager.missionControl()?.waypointMissionOperator().startMission(completion: { (error) in
                    if error != nil {
                        let alert = UIAlertController(title: "Mission Error", message: "Failed to start mission: \(error?.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    }
                })
            }
        })
        
        DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toFinished: self, with: DispatchQueue.main, andBlock: { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Mission Error", message: "Failed to finish mission", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else {
                self.isFlightComplete = true
                let alert = UIAlertController(title: "Mission Success", message: "The mission has finished successfully. Please wait until the drone lands to download the pictures.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        })
        
        DJISDKManager.missionControl()?.waypointMissionOperator().uploadMission(completion: { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Mission Error", message: "Failed to upload mission: \(error?.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        })
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (CLLocationCoordinate2DIsValid((locations.last?.coordinate)!)) {
            self.flightMapView.setCenter((locations.last?.coordinate)!, zoomLevel: 18, animated: true)
            self.aircraftAnnotation.coordinate = (locations.last?.coordinate)!
            // We don't want the map changing while the user is trying to draw on it.
            self.locationManager?.stopUpdatingLocation()
        }
    }
    
    // MARK: GestureDelegate
    func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let touchPoint: CGPoint = gestureRecognizer.location(in: self.flightMapView)
            let newCoordinate: CLLocationCoordinate2D = self.flightMapView.convert(touchPoint, toCoordinateFrom: self.flightMapView)
            self.boundaryCoordinateList.append(newCoordinate)
            
            addAnnotationOnLocation(pointedCoordinate: newCoordinate)
            self.refreshCoordinates()
        }
    }
    
    // MARK: - MGLMapViewDelegate
    // Handle the placing of different annotations
//    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
//        if !(annotation is DJIImageAnnotation) {
//            return nil
//        }
//
//        let imageAnnotation = annotation as! DJIImageAnnotation
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: imageAnnotation.identifier)
//
//        if annotationView == nil {
//            annotationView = DJIImageAnnotationView(annotation: imageAnnotation, reuseIdentifier: imageAnnotation.identifier)
//        }
//
//        self.aircraftAnnotationView = annotationView as! DJIImageAnnotationView
//
//        return annotationView
//    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if annotation is MGLUserLocation {
            return nil // Use default
        }
        
        var image: UIImage?
        var identifier = ""
        
        if annotation is DJIImageAnnotation {
            let imageAnnotation = annotation as! DJIImageAnnotation
            identifier = imageAnnotation.identifier
            
            if annotation.isEqual(self.aircraftAnnotation) {
                image = #imageLiteral(resourceName: "aircraft")
            }
        } else {
            identifier = annotation.title!!
            image = #imageLiteral(resourceName: "navigation_poi_pin")
        }
        
        let annotationView = mapView.dequeueReusableAnnotationImage(withIdentifier: identifier)
        
        if annotationView == nil {
            return MGLAnnotationImage(image: image!, reuseIdentifier: identifier)
        } else {
            return annotationView
        }
    }
    
    // Handle the drawing of the lines and shapes
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if annotation is MGLPolyline {
            return .red
        }
        
        return .green
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 6
    }
    
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return .green
    }
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        if annotation is MGLPolyline {
            return 1
        }
        
        return 0.5
    }
    
    // Handle the "click" of a coordinate
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        if !(annotation is MGLPointAnnotation) {
            return false
        }
        
        return true
    }
    
    func mapView(_ mapView: MGLMapView, rightCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
        return UIButton(type: .detailDisclosure)
    }
    
    func mapView(_ mapView: MGLMapView, annotation: MGLAnnotation, calloutAccessoryControlTapped control: UIControl) {
        mapView.deselectAnnotation(annotation, animated: false)
        
        let coordinate = annotation.coordinate
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        let alert = UIAlertController(title: "Coordinate Details", message: "Latitude \(latitude)\nLongitude \(longitude)\n\nWould you like to remove this coordinate?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { (alert: UIAlertAction!) in
            self.boundaryCoordinateList = self.masterViewController.flightCoordinateList.filter({ (listCoordinate) -> Bool in
                coordinate.latitude != listCoordinate.latitude || coordinate.longitude != listCoordinate.longitude
            })
            
            mapView.removeAnnotation(annotation)
            self.refreshCoordinates()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // MARK: - Convenience
    
    private func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D) {
        let annotation = MGLPointAnnotation()
        annotation.title = "Latitude \(pointedCoordinate.latitude) Longitude \(pointedCoordinate.longitude)"
        annotation.coordinate = pointedCoordinate

        self.flightMapView.addAnnotation(annotation)
    }
    
    private func refreshCoordinates() {
        if self.boundaryCoordinateList.count < 3 {
            if self.boundaryPolygon != nil {
                self.flightMapView.remove(self.boundaryPolygon!)
                self.boundaryPolygon = nil
            }
            
            if self.boundaryLine != nil {
                self.flightMapView.remove(self.boundaryLine!)
            }
            
            if self.boundaryCoordinateList.isEmpty {
                return
            }
            
            self.boundaryLine = MGLPolyline(coordinates: self.boundaryCoordinateList, count: UInt(self.boundaryCoordinateList.count))
            self.flightMapView.add(self.boundaryLine!)
        } else {
            if self.boundaryLine != nil {
                self.flightMapView.remove(self.boundaryLine!)
                self.boundaryLine = nil
            }
            
            if self.boundaryPolygon != nil {
                self.flightMapView.remove(self.boundaryPolygon!)
            }
            
            self.boundaryPolygon = MGLPolygon(coordinates: self.boundaryCoordinateList, count: UInt(self.boundaryCoordinateList.count))
            self.flightMapView.add(self.boundaryPolygon!)
        }
    }
    
    func degreesToRadians(_ degrees: Double) -> Double {
        return Double.pi / 180 * degrees
    }
    
    func metersToFeet(_ meters: Double) -> Double {
        return 3.28084 * meters
    }
}
