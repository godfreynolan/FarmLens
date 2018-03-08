//
//  FlightViewDetailController.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK

class FlightViewDetailController: UIViewController, MKMapViewDelegate, DJICameraDelegate, DJIMediaManagerDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    var locationManager: CLLocationManager!
    var boundaryPolygon: MKPolygon?
    var boundaryLine: MKPolyline?
    var flightPathLine: MKPolyline?
    private var flightPlanning: FlightPlanning!
    private var isFlightComplete = false
    private var masterViewController: MasterViewController!
    
    var homeAnnotation = DJIImageAnnotation(identifier: "homeAnnotation")
    var aircraftAnnotation = DJIImageAnnotation(identifier: "aircraftAnnotation")
    var aircraftAnnotationView: MKAnnotationView!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var batteryLifeLabel: UILabel!
    
    @IBOutlet weak var flightMapView: MKMapView!
    
    override func viewWillAppear(_ animated: Bool) {
        self.masterViewController = self.splitViewController?.viewControllers.first?.childViewControllers.first as! MasterViewController
        self.flightPlanning = FlightPlanning()
        self.flightMapView.addAnnotations([self.aircraftAnnotation, self.homeAnnotation])
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                let newLocationValue = newValue!.value as! CLLocation
                
                if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
                    self.aircraftAnnotation.coordinate = newLocationValue.coordinate
                }
                
                self.latitudeLabel.text = String(format:"Lat: %.4f", newLocationValue.coordinate.latitude)
                self.longitudeLabel.text = String(format:"Long: %.4f", newLocationValue.coordinate.longitude)
                self.altitudeLabel.text = String(format:"Alt: %.4f", newLocationValue.altitude)
            }
        }
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIBatteryKey(), withListener: self, andUpdate: { (oldValue, newValue) in
            if newValue != nil {
                self.batteryLifeLabel.text = "Battery Percentage: \(newValue!.unsignedIntegerValue) %"
            }
        })
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamCompassHeading)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if (newValue != nil) {
                self.aircraftAnnotation.heading = newValue!.doubleValue
                if (self.aircraftAnnotationView != nil) {
                    self.aircraftAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat(self.degreesToRadians(Double(self.aircraftAnnotation.heading))))
                }
            }
        }
        
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamHomeLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if (newValue != nil) {
                let newLocationValue = newValue!.value as! CLLocation
                
                if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
                    self.homeAnnotation.coordinate = newLocationValue.coordinate
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
        self.flightMapView.mapType = .hybrid
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
        if (self.masterViewController.boundaryCoordinateList.isEmpty) {
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
        
        let flightPathCoordinateList = self.flightPlanning.calculateFlightPlan(boundingArea: self.boundaryPolygon!, spacingFeet: 40)
        let mission = self.flightPlanning.createMission(missionCoordinates: flightPathCoordinateList)
        
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
            var region: MKCoordinateRegion = MKCoordinateRegion()
            region.center = (locations.last?.coordinate)!
            region.span.latitudeDelta = 0.001
            region.span.longitudeDelta = 0.001
            
            self.flightMapView.setRegion(region, animated: true)
            // We don't want the map changing while the user is trying to draw on it.
            self.locationManager?.stopUpdatingLocation()
        }
    }
    
    // MARK: GestureDelegate
    func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        if (self.boundaryPolygon != nil) {
            return
        }
        
        if gestureRecognizer.state == .ended {
            let touchPoint: CGPoint = gestureRecognizer.location(in: self.flightMapView)
            let newCoordinate: CLLocationCoordinate2D = self.flightMapView.convert(touchPoint, toCoordinateFrom: self.flightMapView)
            self.masterViewController.boundaryCoordinateList.append(newCoordinate)
            
            addAnnotationOnLocation(pointedCoordinate: newCoordinate)
            self.refreshCoordinates()
        }
    }
    
    // MARK: - MKMapViewDelegate
    // Handle the placing of different annotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var image: UIImage?
        let imageAnnotation: DJIImageAnnotation
        
        if (annotation is MKUserLocation) {
            imageAnnotation = DJIImageAnnotation()
            imageAnnotation.identifier = "User"
            image = #imageLiteral(resourceName: "waypoint")
        } else {
            imageAnnotation = annotation as! DJIImageAnnotation
            
            if annotation.isEqual(self.aircraftAnnotation) {
                image = #imageLiteral(resourceName: "aircraft")
            } else if annotation.isEqual(self.homeAnnotation) {
                image = #imageLiteral(resourceName: "navigation_poi_pin")
            }
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: imageAnnotation.identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: imageAnnotation.identifier)
        }
        
        annotationView?.image = image
        
        if annotation.isEqual(self.aircraftAnnotation) {
            if annotationView != nil {
                self.aircraftAnnotationView = annotationView!
            }
        }
        
        return annotationView
    }
    
    // Handle the drawing of the lines and shapes
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = .red
            lineView.lineWidth = 6
            return lineView
        }
        
        if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.strokeColor = .green
            polygonView.lineWidth = 6
            return polygonView
        }
        
        return MKOverlayRenderer()
    }
    
    // Handle the "click" of a coordinate
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            return
        }
        
        if (view.annotation?.isEqual(self.aircraftAnnotation))! || (view.annotation?.isEqual(self.homeAnnotation))! {
            return
        }
        
        let coordinate = view.annotation?.coordinate
        let latitude = (coordinate?.latitude)!
        let longitude = (coordinate?.longitude)!
        
        let alert = UIAlertController(title: "Coordinate Details", message: "Latitude \(latitude)\nLongitude \(longitude)\n\nWould you like to remove this coordinate?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { (alert: UIAlertAction!) in
            self.masterViewController.boundaryCoordinateList = self.masterViewController.boundaryCoordinateList.filter({ (listCoordinate) -> Bool in
                coordinate?.latitude != listCoordinate.latitude || coordinate?.longitude != listCoordinate.longitude
            })
            
            mapView.removeAnnotation(view.annotation!)
            self.refreshCoordinates()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // MARK: - Convenience
    
    private func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D) {
        let annotation = DJIImageAnnotation()
        annotation.coordinate = pointedCoordinate
        
        self.flightMapView.addAnnotation(annotation)
    }
    
    private func refreshCoordinates() {
        if self.masterViewController.boundaryCoordinateList.count < 3 {
            if self.boundaryPolygon != nil {
                self.flightMapView.remove(self.boundaryPolygon!)
                self.boundaryPolygon = nil
            }
            
            if self.boundaryLine != nil {
                self.flightMapView.remove(self.boundaryLine!)
            }
            
            self.boundaryLine = MKPolyline(coordinates: self.masterViewController.boundaryCoordinateList, count: self.masterViewController.boundaryCoordinateList.count)
            self.flightMapView.add(self.boundaryLine!)
        } else {
            if self.boundaryLine != nil {
                self.flightMapView.remove(self.boundaryLine!)
                self.boundaryLine = nil
            }
            
            if self.boundaryPolygon != nil {
                self.flightMapView.remove(self.boundaryPolygon!)
            }
            
            self.boundaryPolygon = MKPolygon(coordinates: self.masterViewController.boundaryCoordinateList, count: self.masterViewController.boundaryCoordinateList.count)
            self.flightMapView.add(self.boundaryPolygon!)
        }
    }
    
    func degreesToRadians(_ degrees: Double) -> Double {
        return Double.pi / 180 * degrees
    }
}
