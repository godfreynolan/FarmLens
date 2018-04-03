//
//  ImageTiling.swift
//  FarmLens
//
//  Created by Ian Timmis on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Mapbox
import Photos

class ImageTiler {
    func overlayImages(mapView:MGLMapView, style:MGLStyle, images:[DroneImage]) -> Bool {
        if images.isEmpty {
            return false
        }
        
        // Configure image to grow and shrink when the user zooms in and out in the map
        var stops = [NSNumber : MGLStyleValue<NSNumber>]()
        var zoom = mapView.zoomLevel
        var scale = 1.0
        
        while zoom > 0 {
            stops[NSNumber(value: zoom)] = MGLStyleValue(rawValue: NSNumber(value: scale))
            zoom -= 1
            scale /= 2
        }
        
        zoom = mapView.zoomLevel + 1
        scale = 2.0
        
        while zoom < mapView.maximumZoomLevel + 1 {
            stops[NSNumber(value: zoom)] = MGLStyleValue(rawValue: NSNumber(value: scale))
            zoom = zoom + 1
            scale = scale * 2
        }
        
        // Calculate the physical dimensions of the image in terms of lat/long spacing
        let heightSpace = Utils.convertSpacingFeetToDegrees(416)
        let widthSpace = Utils.convertSpacingFeetToDegrees(537.6)
        
        var idx = 0
        
        // Overlay each image
        for droneImage in images {
            let location = droneImage.getLocation()
            let image = droneImage.getImage()
            
            // Calculate the coordinates of the where the boundaries of the image should lay
            let north: CLLocationDegrees = (location.latitude) + heightSpace / 2
            let east:  CLLocationDegrees = (location.longitude) + widthSpace / 2
            let west:  CLLocationDegrees = (location.longitude) - widthSpace / 2
            
            let point = MGLPointFeature()
            point.coordinate = location
            
            // Add image to the style
            let source = MGLShapeSource(identifier: "overlay_\(idx)", shape: point, options: nil)
            style.addSource(source)
            
            // Scale image
            let metersPerPoint = mapView.metersPerPoint(atLatitude: location.latitude)
            let polygonMetersWidth = CLLocation(latitude: north, longitude: west).distance(from: CLLocation(latitude: north, longitude: east))
            let polygonPointsWidth = CGFloat(polygonMetersWidth / metersPerPoint)
            let currentImageScale = image.size.width / polygonPointsWidth
            
            // Resize to current zoom
            let rect = CGRect(x: 0, y: 0, width: image.size.width / currentImageScale, height: image.size.height / currentImageScale)
            UIGraphicsBeginImageContextWithOptions(rect.size, true, UIScreen.main.scale)
            image.draw(in: rect)
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            // add scaled image to the style
            style.setImage(scaledImage, forName: "scaled_overlay_\(idx)")
            
            // Create layer
            let layer = MGLSymbolStyleLayer(identifier: "overlay_\(idx)", source: source)
            
            let val = "scaled_overlay_\(idx)" as NSString
            
            layer.iconImageName = MGLStyleValue(rawValue: val)
            layer.iconOpacity = MGLStyleValue(rawValue: 0.75)
            
            // Configure image to rotate with the map.
            layer.iconRotationAlignment = MGLStyleValue(rawValue: NSNumber(value: MGLIconRotationAlignment.map.rawValue))
            
            // Scale factor
            layer.iconScale = MGLCameraStyleFunction(interpolationMode: .exponential, cameraStops: stops, options: nil)
            
            // Add overlay to map
            style.insertLayer(layer, below: style.layer(withIdentifier: "waterway-label")!)
            
            // Update idx so that each image has unique identifiers
            idx = idx + 1
        }
        
        return true
    }
}
