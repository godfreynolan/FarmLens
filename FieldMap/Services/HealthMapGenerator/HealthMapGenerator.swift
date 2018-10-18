//
//  HealthMapGenerator.swift
//  FarmLens
//
//  Created by ian timmis on 4/3/18.
//  Copyright © 2018. All rights reserved.
//

import Foundation
import UIKit
import Surge

class HealthMapGenerator
{
    func GenerateHealthMap(img: UIImage) -> UIImage
    {
        // Get dimensions
        let height = Int(img.size.height)
        let width = Int(img.size.width)
        
        // Extract raw pixel data (RGB-A) from image
        let pixel_data = (img.pixelData())!
        
        // Initialize vectors from pixel data
        var vec_red:[Double]   = Array(repeating: 0, count:pixel_data.count/4)
        var vec_green:[Double] = Array(repeating: 0, count:pixel_data.count/4)
        var vec_blue:[Double]  = Array(repeating: 0, count:pixel_data.count/4)
        var alpha_mask:[UInt8] = Array(repeating: 0, count:pixel_data.count/4)
        
        // Extract vectors from pixel data
        var i = 0
        for idx in stride(from: 0, to: pixel_data.count, by: 4)
        {
            vec_red[i] = Double(pixel_data[idx])
            vec_green[i] = Double(pixel_data[idx + 1])
            vec_blue[i] = Double(pixel_data[idx + 2])
            alpha_mask[i] = pixel_data[idx + 3]
            i = i + 1
        }
        
        // Perform operations on bands
        let ndvi = CalculateNDVI(vec_red, vec_green, vec_blue)
        
        let interim = ExpandPixelsOfPercentileRangeToUInt8Range(ndvi: ndvi, alpha_mask: alpha_mask, bottom_percent: 0.05, top_percent: 0.95)
        
        // Convert from [Double] to [UInt8]
        let interim_uint8 = ConvertArrayToUInt8(arr: interim)
        
        // Apply CLUT to image. Re-attach the alpha mask
        let final_pixels:[PixelData] = ApplyCLUT(interim_uint8, alpha_mask: alpha_mask)
        
        // Create UIImage from pixels
        let final_image = GetImageFromBitmap(pixels: final_pixels, width: width, height: height)
        
        return final_image!
    }
    
    func CalculateNDVI(_ vec_red:[Double], _ vec_green:[Double], _ vec_blue:[Double]) -> [Double]
    {
        /////////
        // Phatom 4 Pro Equation
        // NDVI = ((1 + ((blue - green) / ((blue + green) + 0.0001))) / 2)
        /////////
        
        // NDVI = ((1 + ((blue - green) / ((blue + green) + 0.0001))) / 2)
        // blue - green
        let X = Surge.sub(vec_blue, y: vec_green)
        
        // NDVI = ((1 + (X / ((blue + green) + 0.0001))) / 2)
        // blue + green
        let Y = Surge.add(vec_blue, y: vec_green)
        
        // NDVI = ((1 + (X / (Y + 0.0001))) / 2)
        // ɛ
        let epsilon = 0.0001
        
        // NDVI = ((1 + (X / (Y + ɛ))) / 2)
        // Y + ɛ
        let Y_eps = Y.map {$0 + epsilon}
        
        // NDVI = ((1 + (X / Y_ɛ)) / 2)
        // X / Y_ɛ
        let quo = ElementWiseDivide(numer: X, denom: Y_eps)
        
        // NDVI = ((1 + quo) / 2)
        let ndvi = quo.map {($0 + 1.0) / 2.0}
        
        return ndvi
    }
    
    // Bottom percent = 0.05
    // Top percent = 0.95
    func ExpandPixelsOfPercentileRangeToUInt8Range(ndvi:[Double], alpha_mask:[UInt8], bottom_percent:Double, top_percent:Double) -> [Double]
    {
        let totalBuckets = 256 * 2
        var range:[Double] = [0.0, 2.0]
        
        var hist = CalculateHistogram(arr: ndvi, range: range, totalBuckets: totalBuckets, alpha: alpha_mask)
        
        var totalNonAlphaPixels:UInt = 0
        
        for row in hist
        {
            // totalNonAlphaPixels += UInt(row[0])
            totalNonAlphaPixels += UInt(row)
        }
        
        var firstNonZeroRow = 0
        var lastNonZeroRow = hist.count - 1
        
        var i = 0
        for row in hist
        {
            // let val = UInt(row[0])
            let val = UInt(row)
            
            if val != 0 && firstNonZeroRow == 0
            {
                firstNonZeroRow = i
            }
            
            if val != 0
            {
                lastNonZeroRow = i
            }
            
            i += 1
        }
        
        var step = (range[1] - range[0]) / Double(totalBuckets)
        
        // The max is exclusive so we need to add the epsilon to it
        let newMin = range[0] + step * Double(firstNonZeroRow)
        let newMax = range[0] + step * Double(lastNonZeroRow) + Double.ulpOfOne
        
        // Now that we know the true min/max of the image,
        // create our new range
        range = [newMin, newMax]
        
        hist = CalculateHistogram(arr: ndvi, range: range, totalBuckets: totalBuckets, alpha: alpha_mask)
        
        var runningTotal:UInt = 0
        
        let lowerBoundCount = UInt(bottom_percent * Double(totalNonAlphaPixels))
        let upperBoundCount = UInt(top_percent * Double(totalNonAlphaPixels))
        
        var lowerBoundIndex = 0
        var upperBoundIndex = hist.count - 1
        
        i = 0
        for row in hist
        {
            //runningTotal += UInt(row[0])
            runningTotal += UInt(row)
            
            if runningTotal > lowerBoundCount && lowerBoundIndex == 0
            {
                lowerBoundIndex = max(i - 1, 0)
            }
            
            if runningTotal > upperBoundCount && upperBoundIndex == hist.count - 1
            {
                upperBoundIndex = max(i - 1, 0)
            }
            
            i += 1
        }
        
        let out_min = 0.0
        let out_max = 255.0
        
        // Perform our percentile calculation now that we have our value between 0 and 2
        step = (range[1] - range[0]) / Double(totalBuckets)
        let lowerPercentile = range[0] + step * Double(lowerBoundIndex)
        let upperPercentile = range[0] + step * Double(upperBoundIndex)
        
        // Collapse everything to the bottom of our lower percentile (anything below it will be negative)
        var outMatrix:[Double] = ndvi.map { $0 - lowerPercentile }
        
        // Expand our data from the 0 to 255 range, still will be floats
        let scale = ((out_min - out_max) / (lowerPercentile - upperPercentile))
        outMatrix = outMatrix.map { $0 * scale }
        
        // Now add back out our bottom percentile value, this will generally be unnecessary since our out_min and out_max
        // are so far out of the 0 to 2 range, but could effect a small number of pixels
        outMatrix = outMatrix.map { $0 + lowerPercentile }
        
        // We will now have data that is below our minimum percentile <= 0
        // And things above our percentile max will be >=255
        return outMatrix
    }
    
    // Truncate values between 0...255
    func ConvertArrayToUInt8(arr: [Double]) -> [UInt8] {
        var response:[UInt8] = [UInt8]()
        
        for element in arr
        {
            if element >= 255
            {
                response.append(UInt8(255))
            }
            else if element <= 0
            {
                response.append(UInt8(0))
            }
            else
            {
                response.append(UInt8( round(element) ))
            }
        }
        
        return response
    }
    
    
    ////////////
    /// Math ///
    ////////////
    
    func ElementWiseDivide(numer: [Double], denom:[Double]) -> [Double]
    {
        // Invert the denominator
        let true_denom = Surge.pow(denom, -1.0)
        
        // Element-wise multiply
        let result = Surge.mul(numer, y: true_denom)
        
        return result
    }
    
    // Values between 0..2
    func CalculateHistogram(arr:[Double], range:[Double], totalBuckets:Int, alpha:[UInt8]) -> [Double]
    {
        var hist:[Double] = Array(repeating: 0, count: totalBuckets)
        
        let step = (range[1] - range[0]) / Double(totalBuckets)
        
        for element in arr
        {
            var min_loss = Double.infinity
            
            for idx in 0..<totalBuckets
            {
                let value_for_idx = (Double(idx) * step) + range[0]
                let loss = abs(element - value_for_idx)
                
                if  loss < min_loss
                {
                    // Have not reached optimal idx. Keep searching
                    min_loss = loss
                }
                else
                {
                    // Add to hist and move to next element
                    hist[idx - 1] += 1
                    break
                }
            }
        }
        
        return hist
    }
    
    
    /////////////
    /// Image ///
    /////////////
    
    // Shifts the NDVI values with corresponding CLUT values.
    // Applies original Alpha Mask back to this processed image
    func ApplyCLUT(_ ndvi:[UInt8], alpha_mask:[UInt8]) -> [PixelData] {
        
        // Import image
        let img = UIImage(named: "CLUT")!
        
        // Get dimensions
        let width = Int(img.size.width)
        
        // Extract raw pixel data (RGB-A) from image
        let pixel_data = (img.pixelData())!
        
        // Extract 1 row of image (RGB-A)
        let clut = pixel_data[0...width * 4]
        
        var new_image_pixels = [PixelData]()
        
        for i in 0..<ndvi.count {
            
            // Get ndvi color on greyscale spectrum
            let value = Int(ndvi[i])
            
            var pixel = PixelData()
            
            // Replace with CLUT value
            pixel.r = clut[value * 4]
            pixel.g = clut[value * 4 + 1]
            pixel.b = clut[value * 4 + 2]
            
            // Merge alpha value from original image
            pixel.a = alpha_mask[i]
            
            // Add to image
            new_image_pixels.append(pixel)
        }
        
        return new_image_pixels
    }
    
    struct PixelData
    {
        var a: UInt8 = 0
        var r: UInt8 = 0
        var g: UInt8 = 0
        var b: UInt8 = 0
    }
    
    func GetImageFromBitmap(pixels: [PixelData], width: Int, height: Int) -> UIImage?
    {
        assert(width > 0)
        assert(height > 0)
        
        let pixelDataSize = MemoryLayout<PixelData>.size
        assert(pixelDataSize == 4)
        
        assert(pixels.count == Int(width * height))
        
        let data: Data = pixels.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        
        let cfdata = NSData(data: data) as CFData
        let provider: CGDataProvider! = CGDataProvider(data: cfdata)
        
        if provider == nil
        {
            print("CGDataProvider is not supposed to be nil")
            return nil
        }
        
        let cgimage: CGImage! = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * pixelDataSize,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        
        if cgimage == nil
        {
            print("CGImage is not supposed to be nil")
            return nil
        }
        
        return UIImage(cgImage: cgimage)
    }
}

