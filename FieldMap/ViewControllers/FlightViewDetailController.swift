//
//  FlightViewDetailController.swift
//  FarmLens
//
//  Created by Tom Kocik on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import UIKit
import DJISDK
import DJIWidget
import Mapbox

class FlightViewDetailController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, DJIVideoFeedListener, DJICameraDelegate, DJISDKManagerDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var fpView: UIView!
    private var boundaryCoordinateList: [CLLocationCoordinate2D] = []
    private var droneConnected = false
    private var locationManager: CLLocationManager!
    private var boundaryPolygon: MGLPolygon?
    private var boundaryLine: MGLPolyline?
    private var flightPlanning: FlightPlanning!
    private var isFlightComplete = false
    private var loadingAlert: UIAlertController!
    @IBOutlet weak var startFlightButton: UIButton!
    
    private var aircraftAnnotation = DJIImageAnnotation(identifier: "aircraftAnnotation")
    
    @IBOutlet weak var flightMapView: MGLMapView!
    @IBOutlet weak var topInfoView: UIView!
    
    override func viewWillDisappear(_ animated: Bool) {
        self.resetVideoPreview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.flightPlanning = FlightPlanning()
        self.flightMapView.addAnnotation(self.aircraftAnnotation)

        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                let newLocationValue = newValue!.value as! CLLocation
                
                if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
                    self.aircraftAnnotation.coordinate = newLocationValue.coordinate
                }
            }
        }

        DJISDKManager.keyManager()?.getValueFor(DJIBatteryKey(param: DJIBatteryParamChargeRemainingInPercent)!, withCompletion: { [unowned self] (value: DJIKeyedValue?, error: Error?) in
            if value == nil {
                return
            }
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

        self.startFlightButton.setImage(UIImage(named: "start-flight-btn-enabled"), for: .normal)
        self.startFlightButton.setImage(UIImage(named: "start-flight-btn-disabled"), for: .disabled)
        
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
        self.topInfoView.backgroundColor = UIColor.black
        self.topInfoView.setNeedsDisplay()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    @IBAction func startFlightClicked(_ sender: Any) {
        startFlight(sender)
        self.startFlightButton.isEnabled = false
        self.fpView.isHidden = false
        self.setupVideoPreviewer()
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
     
        var timerCount = 0
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
 
            timerCount += 1
            DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toUploadEvent: self, with: .main, andBlock: { (event) in
                let logger = Log()
                if event.currentState == .readyToExecute {
                    logger.write("Aircraft state == readyToExecute // starting!")
                    // kill the timer
                timer.invalidate()
                    self.startMission(loadingAlert: self.loadingAlert)
                } else {
                    logger.write("Aircraft state != readyToExecute\n")
                    logger.write(String(reflecting: event.currentState)+"\n")
                    switch event.currentState{
                    case .unknown:
                        logger.write("unknown: ")
                    case .disconnected:
                        logger.write("disconnected: ")
                    case .recovering:
                        logger.write("recovering: ")
                    case .notSupported:
                        logger.write("notSupported: ")
                    case .readyToUpload:
                        logger.write("readyToUpload: ")
                    case .uploading:
                        logger.write("uploading: ")
                    case .readyToExecute:
                        logger.write("readyToExecute: ")
                    case .executing:
                        logger.write("executing: ")
                    case .executionPaused:
                        logger.write("executionPaused: ")
                    }
                    logger.write(String(event.currentState.rawValue)+"\n")
                }
            })
            
            DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toFinished: self, with: DispatchQueue.main, andBlock: { (error) in
                if error != nil {
                    let alert = UIAlertController(title: "Mission Error", message: "Failed to finish mission", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                } else {
                    self.isFlightComplete = true
                    // TODO: Launch flight complete stuff here!
                    //let alert = UIAlertController(title: "Mission Success", message: "The mission has finished successfully. Please wait until the drone lands to download the pictures.", preferredStyle: .alert)
                    //alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    //self.present(alert, animated: true)
                    self.performSegue(withIdentifier: "segueFlightComplete", sender: nil)
                }
            })
            
            DJISDKManager.missionControl()?.waypointMissionOperator().load(mission)
            
            DJISDKManager.missionControl()?.waypointMissionOperator().uploadMission(completion: { (error) in
                let logger = Log()
                if error != nil {
                    logger.write("Mission upload error: " + error.debugDescription)
                    self.loadingAlert.dismiss(animated: true, completion: {
                        let alert = UIAlertController(title: "Upload Error", message: "Failed to upload mission: \(error?.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        //self.present(alert, animated: true)
                    })
                }
            })
            
            //debugging to see if it flys within 5 attempts
            let logger = Log()
                logger.write("\(timerCount) trial\n")

            self.loadingAlert.dismiss(animated: true, completion: {
                // change text
                self.loadingAlert.title = "Trial \(timerCount+1)"
                self.loadingAlert.message = "Please wait, will try \(5-timerCount) more times."
                self.present(self.loadingAlert, animated: true)
            })
            
            if(timerCount == 5){
                logger.write("Ending timer after \(timerCount) times\n")
                timer.invalidate()
                
                self.loadingAlert.dismiss(animated: true, completion: {
                    // change text
                    self.loadingAlert.title = "Timeout \(timerCount)"
                    self.loadingAlert.message = "Couldn't fly after \(timerCount) attempts."
                    self.loadingAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(self.loadingAlert, animated: true)
                })
                
            }
            
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
            image = #imageLiteral(resourceName: "map-marker")
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
            if self.boundaryCoordinateList.count < 3 {
                return .red
            } else {
                return UIColor(red: 0, green: 1.0, blue: 0.63529, alpha: 1.0)
            }
        }
        return UIColor(red: 0, green: 1.0, blue: 0.63529, alpha: 1.0)
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 4
    }
    
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return UIColor(red: 0, green: 0.3921, blue: 0.2509, alpha: 0.5)
    }
    
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        if annotation is MGLPolyline {
            return 1
        }
        
        return 0.7
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
                let logger = Log()
                if error != nil {
                    logger.write("No startMissionError")
                    loadingAlert.dismiss(animated: true, completion: {
                        let alert = UIAlertController(title: "Start Error", message: "Failed to start mission: \(error?.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    } )
                } else {
                    logger.write("startMissionError = " + error.debugDescription)
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
                var lineCoords = boundaryCoordinateList
                lineCoords.append(lineCoords[0])
                self.boundaryLine = MGLPolyline(coordinates: lineCoords, count: UInt(lineCoords.count))
                self.flightMapView.add(self.boundaryLine!)
            }
            
            if self.boundaryPolygon != nil {
                self.flightMapView.remove(self.boundaryPolygon!)
            }
            
            self.boundaryPolygon = MGLPolygon(coordinates: self.boundaryCoordinateList, count: UInt(self.boundaryCoordinateList.count))
            self.flightMapView.add(self.boundaryPolygon!)
        }
    }
    
    func setupVideoPreviewer() {
        DJIVideoPreviewer.instance().setView(self.fpView)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        DJIVideoPreviewer.instance().start()
    }
    
    func resetVideoPreview() {
        DJIVideoPreviewer.instance()?.unSetView()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
    }
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        let videoData = videoData as NSData
        let videoBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: videoData.length)
        videoData.getBytes(videoBuffer, length: videoData.length)
        DJIVideoPreviewer.instance().push(videoBuffer, length: Int32(videoData.length))
    }
    
    // Handles disconnects and reconnects.
    func productConnected(_ product: DJIBaseProduct?) {
        print("Product Connected")
        
        if (product != nil) {
            let camera = self.fetchCamera()
            if (camera != nil) {
                camera!.delegate = self
            }
            self.setupVideoPreviewer()
        }
    }
    
    func productDisconnected() {
        print("Product Disconnected")
        let camera = self.fetchCamera()
        if((camera != nil) && (camera?.delegate?.isEqual(self))!){
            camera?.delegate = nil
        }
        self.resetVideoPreview()
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if error == nil {
            DJISDKManager.startConnectionToProduct()
        }
    }
}
