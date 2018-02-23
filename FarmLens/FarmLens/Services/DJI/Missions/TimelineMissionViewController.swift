//
//  TimelineMissionViewController.swift
//

import UIKit
import DJISDK

class TimelineMissionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, DJICameraDelegate, DJIMediaManagerDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    var locationManager: CLLocationManager?
    var userLocation: CLLocationCoordinate2D?
    var boundaryPolygon: MKPolygon?
    var boundaryLine: MKPolyline?
    var coordinateList: [CLLocationCoordinate2D] = []

    @IBOutlet weak var availableElementsView: UICollectionView!
    var availableElements = [TimelineElementKind]()
    
    @IBOutlet weak var mapView: MKMapView!
    
    var homeAnnotation = DJIImageAnnotation(identifier: "homeAnnotation")
    var aircraftAnnotation = DJIImageAnnotation(identifier: "aircraftAnnotation")
    var aircraftAnnotationView: MKAnnotationView!
    
    @IBOutlet weak var timelineView: UICollectionView!
    var scheduledElements = [TimelineElementKind]()
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    
    @IBOutlet weak var simulatorButton: UIButton!

//    fileprivate var _isSimulatorActive: Bool = false
//    public var isSimulatorActive: Bool {
//        get {
//            return _isSimulatorActive
//        }
//        set {
//            _isSimulatorActive = newValue
//            self.simulatorButton.titleLabel?.text = _isSimulatorActive ? "Stop Simulator" : "Start Simulator"
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
//        DJISDKManager.missionControl()?.addListener(self, toTimelineProgressWith: { (event: DJIMissionControlTimelineEvent, element: DJIMissionControlTimelineElement?, error: Error?, info: Any?) in
//
//            switch event {
//            case .started:
//                self.didStart()
//            case .stopped:
//                self.didStop()
//            case .paused:
//                self.didPause()
//            case .resumed:
//                self.didResume()
//            default:
//                break
//            }
//        })
//
//        self.mapView.addAnnotations([self.aircraftAnnotation, self.homeAnnotation])
//
//        if let aircraftLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)  {
//            DJISDKManager.keyManager()?.startListeningForChanges(on: aircraftLocationKey, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
//                if newValue != nil {
//                    let newLocationValue = newValue!.value as! CLLocation
//
//                    if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
//                        self.aircraftAnnotation.coordinate = newLocationValue.coordinate
//                    }
//
//                    self.latitudeLabel.text = String(format:"Lat: %.4f", newLocationValue.coordinate.latitude)
//                    self.longitudeLabel.text = String(format:"Long: %.4f", newLocationValue.coordinate.longitude)
//                    self.altitudeLabel.text = String(format:"Alt: %.4f", newLocationValue.altitude)
//                }
//            }
//        }
//
//        if let aircraftHeadingKey = DJIFlightControllerKey(param: DJIFlightControllerParamCompassHeading) {
//            DJISDKManager.keyManager()?.startListeningForChanges(on: aircraftHeadingKey, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
//                if (newValue != nil) {
//                    self.aircraftAnnotation.heading = newValue!.doubleValue
//                    if (self.aircraftAnnotationView != nil) {
//                        self.aircraftAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat(self.degreesToRadians(Double(self.aircraftAnnotation.heading))))
//                    }
//                }
//            }
//        }
//
//        if let homeLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamHomeLocation) {
//            DJISDKManager.keyManager()?.startListeningForChanges(on: homeLocationKey, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
//                if (newValue != nil) {
//                    let newLocationValue = newValue!.value as! CLLocation
//
//                    if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
//                        self.homeAnnotation.coordinate = newLocationValue.coordinate
//                    }
//                }
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            //            locationManager?.distanceFilter = 0.1
            locationManager?.requestWhenInUseAuthorization()
            locationManager?.startUpdatingLocation()
        } else {
            let alert = UIAlertController.init(title: "Location Services", message: "Location Services are not enabled.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        
        self.userLocation = kCLLocationCoordinate2DInvalid;

        self.availableElementsView.delegate = self
        self.availableElementsView.dataSource = self
        
        self.timelineView.delegate = self
        self.timelineView.dataSource = self
        
        self.availableElements.append(contentsOf: [.takeOff, .goTo, .goHome, .gimbalAttitude, .singleShootPhoto, .continuousShootPhoto, .recordVideoDuration, .recordVideoStart, .recordVideoStop, .waypointMission, .hotpointMission, .aircraftYaw])
        
        self.mapView.delegate = self
        self.mapView.mapType = .hybrid // Maybe change to just satellite? Need clarification
        self.mapView.showsUserLocation = true
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        self.mapView.addGestureRecognizer(gestureRecognizer)
        
        
//        if let isSimulatorActiveKey = DJIFlightControllerKey(param: DJIFlightControllerParamIsSimulatorActive) {
//            DJISDKManager.keyManager()?.startListeningForChanges(on: isSimulatorActiveKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
//                if newValue?.boolValue != nil {
//                    self.isSimulatorActive = (newValue?.boolValue)!
//                }
//            })
//        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    private func refreshCoordinates() {
        if self.coordinateList.count < 3 {
            if self.boundaryPolygon != nil {
                self.mapView.remove(self.boundaryPolygon!)
                self.boundaryPolygon = nil
            }
            
            if self.boundaryLine != nil {
                self.mapView.remove(self.boundaryLine!)
            }
            
            self.boundaryLine = MKPolyline(coordinates: self.coordinateList, count: self.coordinateList.count)
            self.mapView.add(self.boundaryLine!)
        } else {
            if self.boundaryLine != nil {
                self.mapView.remove(self.boundaryLine!)
                self.boundaryLine = nil
            }
            
            if self.boundaryPolygon != nil {
                self.mapView.remove(self.boundaryPolygon!)
            }
            
            for coordinate in self.coordinateList {
                print("Lat/Long: \(coordinate.latitude)/\(coordinate.longitude)")
            }
            
            self.boundaryPolygon = MKPolygon(coordinates: self.coordinateList, count: self.coordinateList.count)
            self.mapView.add(self.boundaryPolygon!)
        }
    }
    
    // MARK: GestureDelegate
    func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        print("Handled the tap: \(gestureRecognizer.state.rawValue)")
        if gestureRecognizer.state == .ended {
            let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
            let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            self.coordinateList.append(newCoordinate)
            
            addAnnotationOnLocation(pointedCoordinate: newCoordinate)
            self.refreshCoordinates()
        }
    }
    
    private func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D) {
        let annotation = DJIImageAnnotation()
        annotation.coordinate = pointedCoordinate
        annotation.title = "Loading..."
        annotation.subtitle = "Loading..."
        
        mapView.addAnnotation(annotation)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.last?.coordinate
        
        if (CLLocationCoordinate2DIsValid(self.userLocation!)) {
            var region: MKCoordinateRegion = MKCoordinateRegion()
            region.center = self.userLocation!
            region.span.latitudeDelta = 0.001
            region.span.longitudeDelta = 0.001
            
            self.mapView.setRegion(region, animated: true)
            self.locationManager?.stopUpdatingLocation()
        }
    }

    // MARK: - MKMapViewDelegate
    
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = .red
            return lineView
        }
        
        if overlay is MKPolygon {
            let lineView = MKPolygonRenderer(overlay: overlay)
            lineView.strokeColor = .green
            return lineView
        }
        
        return MKOverlayRenderer()
    }
    
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
        
        let alert = UIAlertController.init(title: "Coordinate Details", message: "Latitude \(latitude)\nLongitude \(longitude)\n\nWould you like to remove this coordinate?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { (alert: UIAlertAction!) in
            self.coordinateList = self.coordinateList.filter({ (listCoordinate) -> Bool in
                coordinate?.latitude != listCoordinate.latitude || coordinate?.longitude != listCoordinate.longitude
            })
            
            mapView.removeAnnotation(view.annotation!)
            self.refreshCoordinates()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // End Map View delegate methods
    
    fileprivate var started = false
    fileprivate var paused = false
    
    @IBAction func playButtonAction(_ sender: Any) {
//        if self.paused {
//            DJISDKManager.missionControl()?.resumeTimeline()
//        } else if self.started {
//            DJISDKManager.missionControl()?.pauseTimeline()
//        } else {
//            DJISDKManager.missionControl()?.startTimeline()
//        }
    }
    
    @IBAction func stopButtonAction(_ sender: Any) {
//        DJISDKManager.missionControl()?.stopTimeline()
    }
    
    @IBAction func startSimulatorButtonAction(_ sender: Any) {
//        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
//            return
//        }
//
//        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
//            return
//        }
//
//        let droneLocation = droneLocationValue.value as! CLLocation
//        let droneCoordinates = droneLocation.coordinate
//
//        if let aircraft = DJISDKManager.product() as? DJIAircraft {
//            if self.isSimulatorActive {
//                aircraft.flightController?.simulator?.stop(completion: nil)
//            } else {
//                aircraft.flightController?.simulator?.start(withLocation: droneCoordinates,
//                                                                      updateFrequency: 30,
//                                                                      gpsSatellitesNumber: 12,
//                                                                      withCompletion: { (error) in
//                    if (error != nil) {
//                        NSLog("Start Simulator Error: \(error.debugDescription)")
//                    }
//                })
//            }
//        }
    }
    
//    func didStart() {
//        self.started = true
//        DispatchQueue.main.async {
//            self.stopButton.isEnabled = true
//            self.playButton.setTitle("⏸", for: .normal)
//        }
//    }
//
//    func didPause() {
//        self.paused = true
//        DispatchQueue.main.async {
//            self.playButton.setTitle("▶️", for: .normal)
//        }
//    }
//
//    func didResume() {
//        self.paused = false
//        DispatchQueue.main.async {
//            self.playButton.setTitle("⏸", for: .normal)
//        }
//    }
//
//    func didStop() {
//        self.started = false
//        DispatchQueue.main.async {
//            self.stopButton.isEnabled = false
//            self.playButton.setTitle("▶️", for: .normal)
//        }
//    }
    
    //MARK: OutlineView Delegate & Datasource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.availableElementsView {
            return self.availableElements.count
        } else if collectionView == self.timelineView {
            return self.scheduledElements.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "elementCell", for: indexPath) as! TimelineElementCollectionViewCell
        
        if collectionView == self.availableElementsView {
            cell.label.text = self.availableElements[indexPath.row].rawValue
        } else if collectionView == self.timelineView {
            cell.label.text = self.scheduledElements[indexPath.row].rawValue
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.isEqual(self.availableElementsView) {
            let elementKind = self.availableElements[indexPath.row]

            guard let element = self.timelineElementForKind(kind: elementKind) else {
                return;
            }
            let error = DJISDKManager.missionControl()?.scheduleElement(element)

            if error != nil {
                print("Error scheduling element \(String(describing: error))")
                return;
            }

            self.scheduledElements.append(elementKind)
            DispatchQueue.main.async {
                self.timelineView.reloadData()
            }
        } else if collectionView.isEqual(self.timelineView) {
            if self.started == false {
                DJISDKManager.missionControl()?.unscheduleElement(at: UInt(indexPath.row))
                self.scheduledElements.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    self.timelineView.reloadData()
                }
            }
        }
    }
    
    // MARK : Timeline Element 

    func timelineElementForKind(kind: TimelineElementKind) -> DJIMissionControlTimelineElement? {
        switch kind {
            case .takeOff:
                return DJITakeOffAction()
            case .goTo:
                return DJIGoToAction(altitude: 50)
            case .goHome:
                return DJIGoHomeAction()
            case .gimbalAttitude:
                return self.defaultGimbalAttitudeAction()
            case .singleShootPhoto:
                return DJIShootPhotoAction(singleShootPhoto: ())
            case .continuousShootPhoto:
                return DJIShootPhotoAction(photoCount: 10, timeInterval: 3.0)
            case .recordVideoDuration:
                return DJIRecordVideoAction(duration: 10)
            case .recordVideoStart:
                return DJIRecordVideoAction(startRecordVideo: ())
            case .recordVideoStop:
                return DJIRecordVideoAction(stopRecordVideo: ())
            case .waypointMission:
                return self.defaultWaypointMission()
            case .hotpointMission:
                return self.defaultHotPointAction()
            case .aircraftYaw:
                return DJIAircraftYawAction(relativeAngle: 36, andAngularVelocity: 30)
        }
    }

    func defaultGimbalAttitudeAction() -> DJIGimbalAttitudeAction? {
        let attitude = DJIGimbalAttitude(pitch: 30.0, roll: 0.0, yaw: 0.0)

        return DJIGimbalAttitudeAction(attitude: attitude)
    }

    func defaultWaypointMission() -> DJIWaypointMission? {
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 15
        mission.autoFlightSpeed = 8
        mission.finishedAction = .noAction
        mission.headingMode = .auto
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .pointToPoint
        mission.repeatTimes = 1

        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
            return nil
        }

        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
            return nil
        }

        let droneLocation = droneLocationValue.value as! CLLocation
        let droneCoordinates = droneLocation.coordinate

        if !CLLocationCoordinate2DIsValid(droneCoordinates) {
            return nil
        }

        mission.pointOfInterest = droneCoordinates
        let offset = 0.0000899322

        let loc1 = CLLocationCoordinate2DMake(droneCoordinates.latitude + offset, droneCoordinates.longitude)
        let waypoint1 = DJIWaypoint(coordinate: loc1)
        waypoint1.altitude = 25
        waypoint1.heading = 0
        waypoint1.actionRepeatTimes = 1
        waypoint1.actionTimeoutInSeconds = 60
        waypoint1.cornerRadiusInMeters = 5
        waypoint1.turnMode = .clockwise
        waypoint1.gimbalPitch = 0

        let loc2 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude + offset)
        let waypoint2 = DJIWaypoint(coordinate: loc2)
        waypoint2.altitude = 26
        waypoint2.heading = 0
        waypoint2.actionRepeatTimes = 1
        waypoint2.actionTimeoutInSeconds = 60
        waypoint2.cornerRadiusInMeters = 5
        waypoint2.turnMode = .clockwise
        waypoint2.gimbalPitch = -90

        let loc3 = CLLocationCoordinate2DMake(droneCoordinates.latitude - offset, droneCoordinates.longitude)
        let waypoint3 = DJIWaypoint(coordinate: loc3)
        waypoint3.altitude = 27
        waypoint3.heading = 0
        waypoint3.actionRepeatTimes = 1
        waypoint3.actionTimeoutInSeconds = 60
        waypoint3.cornerRadiusInMeters = 5
        waypoint3.turnMode = .clockwise
        waypoint3.gimbalPitch = 0

        let loc4 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude - offset)
        let waypoint4 = DJIWaypoint(coordinate: loc4)
        waypoint4.altitude = 28
        waypoint4.heading = 0
        waypoint4.actionRepeatTimes = 1
        waypoint4.actionTimeoutInSeconds = 60
        waypoint4.cornerRadiusInMeters = 5
        waypoint4.turnMode = .clockwise
        waypoint4.gimbalPitch = -90

        let waypoint5 = DJIWaypoint(coordinate: loc1)
        waypoint5.altitude = 29
        waypoint5.heading = 0
        waypoint5.actionRepeatTimes = 1
        waypoint5.actionTimeoutInSeconds = 60
        waypoint5.cornerRadiusInMeters = 5
        waypoint5.turnMode = .clockwise
        waypoint5.gimbalPitch = 0

        mission.add(waypoint1)
        mission.add(waypoint2)
        mission.add(waypoint3)
        mission.add(waypoint4)
        mission.add(waypoint5)

        return DJIWaypointMission(mission: mission)
    }

    func defaultHotPointAction() -> DJIHotpointAction? {
        let mission = DJIHotpointMission()

        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
            return nil
        }

        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
            return nil
        }

        let droneLocation = droneLocationValue.value as! CLLocation
        let droneCoordinates = droneLocation.coordinate

        if !CLLocationCoordinate2DIsValid(droneCoordinates) {
            return nil
        }

        let offset = 0.0000899322

        mission.hotpoint = CLLocationCoordinate2DMake(droneCoordinates.latitude + offset, droneCoordinates.longitude)
        mission.altitude = 15
        mission.radius = 15
        mission.angularVelocity = DJIHotpointMissionOperator.maxAngularVelocity(forRadius: mission.radius) * (arc4random() % 2 == 0 ? -1 : 1)
        mission.startPoint = .nearest
        mission.heading = .alongCircleLookingForward

        return DJIHotpointAction(mission: mission, surroundingAngle: 180)
    }
    
    // MARK: - Convenience
    
    func degreesToRadians(_ degrees: Double) -> Double {
        return Double.pi / 180 * degrees
    }
}