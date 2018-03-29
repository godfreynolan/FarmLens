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

class FlightViewDetailController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private var boundaryCoordinateList: [CLLocationCoordinate2D] = []
    private var droneConnected = false
    private var locationManager: CLLocationManager!
    private var boundaryPolygon: MGLPolygon?
    private var boundaryLine: MGLPolyline?
    private var flightPlanning: FlightPlanning!
    private var isFlightComplete = false
    private var loadingAlert: UIAlertController!
    
    private var aircraftAnnotation = DJIImageAnnotation(identifier: "aircraftAnnotation")
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var batteryLifeLabel: UILabel!
    
    @IBOutlet weak var flightMapView: MGLMapView!
    
    override func viewWillAppear(_ animated: Bool) {
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
                self.altitudeLabel.text = String(format:"Alt: %.4f ft", Utils.metersToFeet(newLocationValue.altitude))
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
        
        DJISDKManager.keyManager()?.getValueFor(DJIProductKey(param: DJIParamConnection)!, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
            if value != nil {
                if value!.boolValue {
                    // connected
                    self.droneConnected = true
                } else {
                    // disconnected
                    self.droneConnected = false
                }
            }
        })
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
            let alert = UIAlertController(title: "Error", message: "There are no pictures to download. Please fly first!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
            return false
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
        
        if !self.droneConnected {
            let alert = UIAlertController(title: "Drone Error", message: "Please connect to a drone before attempting to fly", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        self.loadingAlert = UIAlertController(title: "Loading", message: "Calculating flight path and launching", preferredStyle: .alert)
        self.present(self.loadingAlert, animated: true)
        
        // Fetches the initial number of files on the SD Card. This is used to determine how many images we have to download later
        let initialCameraCallback = InitialCameraCallback(camera: self.fetchCamera()!, viewController: self)
        initialCameraCallback.fetchInitialData()
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
    
    // MARK: - CameraCallback Helper
    func setPreFlightImageCount(imageCount: Int) {
        self.appDelegate.preFlightImageCount = imageCount
    }
    
    func fetchCamera() -> DJICamera? {
        if (DJISDKManager.product() == nil) {
            return nil
        }
        
        if (DJISDKManager.product() is DJIAircraft) {
            return (DJISDKManager.product() as? DJIAircraft)?.camera
        }
        
        return nil
    }
    
    func startMission() {
        let flightPathCoordinates = self.flightPlanning.calculateFlightPlan(boundingArea: self.boundaryPolygon!, spacingFeet: 95)
        
        if flightPathCoordinates.count <= 2 {
            self.missionError(message: "Your flight is too short. Please select a larger area")
            return
        }
        
        if flightPathCoordinates.count >= 99 {
            self.missionError(message: "Your flight is too long. Please select a smaller area")
            return
        }
        
        let mission = self.flightPlanning.createMission(missionCoordinates: flightPathCoordinates)
        
        DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toUploadEvent: self, with: .main, andBlock: { (event) in
            if event.currentState == .readyToExecute {
                self.startMission(loadingAlert: self.loadingAlert)
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
        
        DJISDKManager.missionControl()?.waypointMissionOperator().load(mission)
        
        DJISDKManager.missionControl()?.waypointMissionOperator().uploadMission(completion: { (error) in
            if error != nil {
                self.loadingAlert.dismiss(animated: true, completion: {
                    let alert = UIAlertController(title: "Upload Error", message: "Failed to upload mission: \(error?.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                })
            }
        })
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
            mapView.removeAnnotation(annotation)
            self.refreshCoordinates()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // MARK: - Convenience
    
    private func startMission(loadingAlert: UIAlertController) {
        DJISDKManager.missionControl()?.waypointMissionOperator().startMission(completion: { (error) in
            if error != nil {
                loadingAlert.dismiss(animated: true, completion: {
                    let alert = UIAlertController(title: "Start Error", message: "Failed to start mission: \(error?.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                } )
            } else {
                loadingAlert.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    private func missionError(message: String) {
        let pins = self.flightMapView.annotations?.filter({ (annotation) -> Bool in
            !(annotation is MGLUserLocation) && !(annotation is DJIImageAnnotation)
        })
        self.flightMapView.removeAnnotations(pins!)
        self.boundaryCoordinateList.removeAll()
        self.refreshCoordinates()
        
        self.loadingAlert.dismiss(animated: true) {
            let alert = UIAlertController(title: "Mission Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
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
}
