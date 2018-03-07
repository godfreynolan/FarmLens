//
//  ImageTiling.swift
//  FarmLens
//
//  Created by Ian Timmis on 3/7/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Mapbox
import MapKit
import UIKit

class ImageTiler
{
    func convertSpacingFeetToDegrees(_ spacingFeet:Double) -> Double
    {
        // SpacingFeet / 3280.4 converts feet to kilometers
        // Kilometers / (10000/90) converts kilometers to lat/long distance
        return (spacingFeet / 3280.4) / (10000/90)
    }
    
    func OverlayImages(mapView:MGLMapView, style:MGLStyle, imageLocations:[CLLocationCoordinate2D], images:[UIImage]) -> Bool
    {
        var success = true
        
        // Determine that the ratio from image to image_location is 1:1 and that the lists
        // are not empty
        if images.count != imageLocations.count || images.isEmpty || imageLocations.isEmpty
        {
            // Image to image_location ratio is not 1:1, or one of the lists is empty
            success = false
        }
        else
        {
            // Calculate the physical dimensions of the image in terms of lat/long spacing
            let heightSpace = convertSpacingFeetToDegrees(64.0)
            let widthSpace =  convertSpacingFeetToDegrees(85.0)
            
            var idx = 0
            
            // Overlay each image
            for (img, loc) in zip(images, imageLocations)
            {
                // Calculate the coordinates of the where the boundaries of the image should lay
                let north: CLLocationDegrees = (loc.latitude) + heightSpace
                let south: CLLocationDegrees = (loc.latitude) - heightSpace
                let east:  CLLocationDegrees = (loc.longitude) + widthSpace
                let west:  CLLocationDegrees = (loc.longitude) - widthSpace
                
                // TODO UPDATE THIS WITH BETTER COORDINATES
                let polygon = MGLPolygon(coordinates: [
                    CLLocationCoordinate2D(latitude: north, longitude: west),
                    CLLocationCoordinate2D(latitude: north, longitude: east),
                    CLLocationCoordinate2D(latitude: south, longitude: east),
                    CLLocationCoordinate2D(latitude: south, longitude: west)
                    ], count: 4)
                
                // Zoom the map to the region
                mapView.setVisibleCoordinateBounds(polygon.overlayBounds,
                                                   edgePadding: UIEdgeInsetsMake(50, 50, 50, 50),
                                                   animated: false)
                
                let point = MGLPointFeature()
                point.coordinate = loc
                
                // Add image to the style
                let source = MGLShapeSource(identifier: "overlay_\(idx)", shape: point, options: nil)
                style.addSource(source)
                
                // Scale image
                let metersPerPoint = mapView.metersPerPoint(atLatitude: loc.latitude)
                let polygonMetersWidth = CLLocation(latitude: north, longitude: west).distance(from: CLLocation(latitude: north, longitude: east))
                let polygonPointsWidth = CGFloat(polygonMetersWidth / metersPerPoint)
                let currentImageScale = img.size.width / polygonPointsWidth
                
                // Resize to current zoom
                let rect = CGRect(x: 0, y: 0, width: img.size.width / currentImageScale, height: img.size.height / currentImageScale)
                UIGraphicsBeginImageContextWithOptions(rect.size, true, UIScreen.main.scale)
                img.draw(in: rect)
                let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                
                // add scaled image to the style
                style.setImage(scaledImage, forName: "scaled_overlay_\(idx)")
                
                // Configure image to grow and shrink when the user zooms in and out in the map
                var stops = [NSNumber : MGLStyleValue<NSNumber>]()
                var zoom = mapView.zoomLevel
                var scale = 1.0
                
                while zoom > 0
                {
                    stops[NSNumber(value: zoom)] = MGLStyleValue(rawValue: NSNumber(value: scale))
                    zoom = zoom - 1
                    scale = scale / 2
                }
                
                zoom = mapView.zoomLevel + 1
                scale = 2.0
                
                while zoom < mapView.maximumZoomLevel + 1
                {
                    stops[NSNumber(value: zoom)] = MGLStyleValue(rawValue: NSNumber(value: scale))
                    zoom = zoom + 1
                    scale = scale * 2
                }
                
                // Create layer
                let layer = MGLSymbolStyleLayer(identifier: "overlay_\(idx)", source: source)
                
                let val = "scaled_overlay_\(idx)" as NSString
                
                layer.iconImageName = MGLStyleValue(rawValue: val)
                layer.iconOpacity = MGLStyleValue(rawValue: 0.75)
                
                // Configure image to rotate with the map.
                layer.iconRotationAlignment = MGLStyleValue(rawValue: NSNumber(value: MGLIconRotationAlignment.map.rawValue))
                
                // Scale factor
                layer.iconScale = MGLCameraStyleFunction(interpolationMode: .exponential,
                                                         cameraStops: stops,
                                                         options: nil)
                
                // Add overlay to map
                style.insertLayer(layer, below: style.layer(withIdentifier: "waterway-label")!)
                
                // Update idx so that each image has unique identifiers
                idx = idx + 1
            }
        }
        
        return success
    }
}
