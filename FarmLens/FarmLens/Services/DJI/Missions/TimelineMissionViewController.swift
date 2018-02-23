//
//  TimelineMissionViewController.swift
//

import UIKit
import DJISDK

class TimelineMissionViewController: UIViewController, UICollectionViewDelegate, MKMapViewDelegate, DJICameraDelegate, DJIMediaManagerDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    var locationManager: CLLocationManager?
    var userLocation: CLLocationCoordinate2D?
    var boundaryPolygon: MKPolygon?
    var boundaryLine: MKPolyline?
    var boundaryCoordinateList: [CLLocationCoordinate2D] = []
    var mission: DJIWaypointMission? = nil
    var flightPlanning: FlightPlanning? = nil
    
    @IBOutlet weak var mapView: MKMapView!
    
    var homeAnnotation = DJIImageAnnotation(identifier: "homeAnnotation")
    var aircraftAnnotation = DJIImageAnnotation(identifier: "aircraftAnnotation")
    var aircraftAnnotationView: MKAnnotationView!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    
    @IBOutlet weak var simulatorButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        self.mapView.addAnnotations([self.aircraftAnnotation, self.homeAnnotation])

        if let aircraftLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)  {
            DJISDKManager.keyManager()?.startListeningForChanges(on: aircraftLocationKey, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
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
        }

        if let aircraftHeadingKey = DJIFlightControllerKey(param: DJIFlightControllerParamCompassHeading) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: aircraftHeadingKey, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
                if (newValue != nil) {
                    self.aircraftAnnotation.heading = newValue!.doubleValue
                    if (self.aircraftAnnotationView != nil) {
                        self.aircraftAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat(self.degreesToRadians(Double(self.aircraftAnnotation.heading))))
                    }
                }
            }
        }

        if let homeLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamHomeLocation) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: homeLocationKey, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
                if (newValue != nil) {
                    let newLocationValue = newValue!.value as! CLLocation

                    if CLLocationCoordinate2DIsValid(newLocationValue.coordinate) {
                        self.homeAnnotation.coordinate = newLocationValue.coordinate
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
            locationManager?.startUpdatingLocation()
        } else {
            let alert = UIAlertController.init(title: "Location Services", message: "Location Services are not enabled.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        
        self.userLocation = kCLLocationCoordinate2DInvalid;
        
        self.mapView.delegate = self
        self.mapView.mapType = .hybrid
        self.mapView.showsUserLocation = true
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        gestureRecognizer.delegate = self
        self.mapView.addGestureRecognizer(gestureRecognizer)
    }

    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    private func refreshCoordinates() {
        if self.boundaryCoordinateList.count < 3 {
            if self.boundaryPolygon != nil {
                self.mapView.remove(self.boundaryPolygon!)
                self.boundaryPolygon = nil
            }
            
            if self.boundaryLine != nil {
                self.mapView.remove(self.boundaryLine!)
            }
            
            self.boundaryLine = MKPolyline(coordinates: self.boundaryCoordinateList, count: self.boundaryCoordinateList.count)
            self.mapView.add(self.boundaryLine!)
        } else {
            if self.boundaryLine != nil {
                self.mapView.remove(self.boundaryLine!)
                self.boundaryLine = nil
            }
            
            if self.boundaryPolygon != nil {
                self.mapView.remove(self.boundaryPolygon!)
            }
            
            self.boundaryPolygon = MKPolygon(coordinates: self.boundaryCoordinateList, count: self.boundaryCoordinateList.count)
            self.flightPlanning = FlightPlanning(polygon: self.boundaryPolygon!)
            self.mapView.add(self.boundaryPolygon!)
        }
    }
    
    // MARK: GestureDelegate
    func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
            let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            self.boundaryCoordinateList.append(newCoordinate)
            
            addAnnotationOnLocation(pointedCoordinate: newCoordinate)
            self.refreshCoordinates()
        }
    }
    
    private func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D) {
        let annotation = DJIImageAnnotation()
        annotation.coordinate = pointedCoordinate
        
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
            lineView.lineWidth = 3
            return lineView
        }
        
        if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.strokeColor = .green
            polygonView.lineWidth = 3
            return polygonView
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
            self.boundaryCoordinateList = self.boundaryCoordinateList.filter({ (listCoordinate) -> Bool in
                coordinate?.latitude != listCoordinate.latitude || coordinate?.longitude != listCoordinate.longitude
            })
            
            mapView.removeAnnotation(view.annotation!)
            self.refreshCoordinates()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    // End Map View delegate methods
    
    @IBAction func assembleFlightPath(_ sender: Any) {
        if (self.boundaryPolygon == nil) {
            let alert = UIAlertController.init(title: "Flight Path Error", message: "Please draw a proper bounding area before preparing a flight.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        let flightCoordinateList = self.flightPlanning?.calculateFlightPlan(spacingFeet: 40)
        
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 15
        mission.autoFlightSpeed = 8
        mission.finishedAction = .goHome
        mission.headingMode = .auto
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .pointToPoint // Might need to be changed to safely
        mission.repeatTimes = 1
        
        for coordinate in flightCoordinateList! {
            let waypoint = DJIWaypoint(coordinate: coordinate)
            waypoint.altitude = 50
            waypoint.heading = 0
            waypoint.actionRepeatTimes = 1
            waypoint.actionTimeoutInSeconds = 6
            waypoint.turnMode = .clockwise
            waypoint.add(DJIWaypointAction(actionType: DJIWaypointActionType.shootPhoto, param: 0))
            waypoint.gimbalPitch = -90
            
            mission.add(waypoint)
        }
        
        self.mission = DJIWaypointMission(mission: mission)
    }
    
    @IBAction func startSimulatorButtonAction(_ sender: Any) {
        if (self.mission == nil) {
            let alert = UIAlertController.init(title: "Flight Path Error", message: "Please prepare a flight before attempting to fly.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        DJISDKManager.missionControl()?.waypointMissionOperator().load(self.mission!)
        
        DJISDKManager.missionControl()?.waypointMissionOperator().addListener(toFinished: self, with: DispatchQueue.main, andBlock: { (error) in
            if error != nil {
                let alert = UIAlertController.init(title: "Mission Error", message: "Failed to finish mission: \(error?.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else {
                let alert = UIAlertController.init(title: "Mission Finished", message: "Mission Finished.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        })
        
        DJISDKManager.missionControl()?.waypointMissionOperator().uploadMission(completion: { (error) in
            if error != nil {
                let alert = UIAlertController.init(title: "Mission Error", message: "Failed to upload mission: \(error?.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else {
                let alert = UIAlertController.init(title: "Mission Success", message: "Mission uploaded.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        })
    }
    
    // MARK : Timeline Element

    func defaultWaypointMission() -> DJIWaypointMission? {
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 15
        mission.autoFlightSpeed = 8
        mission.finishedAction = .goHome
        mission.headingMode = .auto
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .pointToPoint // Might need to be changed to safely
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
        waypoint1.altitude = 50
        waypoint1.heading = 0
        waypoint1.actionRepeatTimes = 1
        waypoint1.actionTimeoutInSeconds = 6
        waypoint1.turnMode = .clockwise
        waypoint1.add(DJIWaypointAction(actionType: DJIWaypointActionType.shootPhoto, param: 0))
        waypoint1.gimbalPitch = -90

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
    
    // MARK: - Convenience
    
    func degreesToRadians(_ degrees: Double) -> Double {
        return Double.pi / 180 * degrees
    }
}
