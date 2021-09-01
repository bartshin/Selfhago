//
//  VImageFilters.swift
//  Filterpedia
//
//  Created by Simon Gladman on 21/04/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
// These filters don't work nicely in background threads! Execute in dispatch_get_main_queue()!
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import CoreImage
import Accelerate

class HistogramSpecification: CIFilter, VImageFilter
{
	
	var inputImage: CGImage?
	var ciContext: CIContext!
	var sourceBuffer: vImage_Buffer?
	var outputCGImage: CGImage? 
	private var inputHistogramSource: CGImage?
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "Histogram Specification",
			"inputImage": [kCIAttributeIdentity: 0,
						   kCIAttributeClass: "CIImage",
						   kCIAttributeDisplayName: "Image",
						   kCIAttributeType: kCIAttributeTypeImage],
			"inputHistogramSource": [kCIAttributeIdentity: 0,
									 kCIAttributeClass: "CIImage",
									 kCIAttributeDisplayName: "Histogram Source",
									 kCIAttributeType: kCIAttributeTypeImage],
		]
	}
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey {
		   let newImage = (value as! CGImage)
			if inputImage != newImage {
				createSourceBufferFromCGImage(newImage, format: vImage.cgImageFormat8888)
			}
			inputImage = newImage
		}
		else if key == kCIInputTargetImageKey {
			inputHistogramSource = (value as! CGImage)
		}
	}
	
	
	override var outputImage: CIImage?
	{
		guard inputImage != nil,
			  inputHistogramSource != nil,
			  sourceBuffer != nil,
			  var histogramSourceBuffer = try? vImage_Buffer(cgImage: inputHistogramSource!,
														format: vImage.cgImageFormat8888,
														flags: .noFlags) else
		{
			assertionFailure("Fail to set buffer")
			return nil
		}
		
		let alpha: UnsafeMutablePointer<UInt>? = .allocate(capacity: 256)
		alpha?.initialize(repeating: 0, count: 256)
		let red: UnsafeMutablePointer<UInt>? = .allocate(capacity: 256)
		alpha?.initialize(repeating: 0, count: 256)
		let green: UnsafeMutablePointer<UInt>? = .allocate(capacity: 256)
		alpha?.initialize(repeating: 0, count: 256)
		let blue: UnsafeMutablePointer<UInt>? = .allocate(capacity: 256)
		alpha?.initialize(repeating: 0, count: 256)
		
		let alphaMutablePointer: UnsafeMutablePointer<vImagePixelCount>? = UnsafeMutablePointer<vImagePixelCount>(mutating: alpha)
		let redMutablePointer: UnsafeMutablePointer<vImagePixelCount>? = UnsafeMutablePointer<vImagePixelCount>(mutating: red)
		let greenMutablePointer: UnsafeMutablePointer<vImagePixelCount>? = UnsafeMutablePointer<vImagePixelCount>(mutating: green)
		let blueMutablePointer: UnsafeMutablePointer<vImagePixelCount>? = UnsafeMutablePointer<vImagePixelCount>(mutating: blue)
		
		var rgbaMutablePointers = [redMutablePointer, greenMutablePointer, blueMutablePointer, alphaMutablePointer]
		
		vImageHistogramCalculation_ARGB8888(&histogramSourceBuffer, &rgbaMutablePointers, UInt32(kvImageNoFlags))
		let width = sourceBuffer!.width
		let height = sourceBuffer!.height
		let pixelBuffer = malloc( sourceBuffer!.rowBytes * Int(height) )
		
		var outBuffer = vImage_Buffer(
			data: pixelBuffer,
			height: height,
			width: width,
			rowBytes: sourceBuffer!.rowBytes)
		
		let alphaPointer: UnsafePointer<vImagePixelCount>? = .init(alpha)
		let redPointer: UnsafePointer<vImagePixelCount>? = .init(red)
		let greenPointer: UnsafePointer<vImagePixelCount>? = .init(green)
		let bluePointer: UnsafePointer<vImagePixelCount>? = .init(blue)
		
		var rgbaPointers = [redPointer, greenPointer, bluePointer, alphaPointer]
		
		vImageHistogramSpecification_ARGB8888(&sourceBuffer!, &outBuffer, &rgbaPointers, UInt32(kvImageNoFlags))
		
		defer {
			free(histogramSourceBuffer.data)
			free(pixelBuffer)
			free(alpha)
			free(green)
			free(blue)
			free(red)
		}
		return CIImage(fromvImageBuffer: outBuffer)
	}
	
	deinit {
		sourceBuffer?.free()
	}
}
