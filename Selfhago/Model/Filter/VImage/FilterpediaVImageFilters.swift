
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

class CircularBokeh: CIFilter, VImageFilter
{
	var inputImage: CGImage?
	var outputCGImage: CGImage?
	var inputBlurRadius: CGFloat = 2
	var sourceBuffer: vImage_Buffer?
	
	var inputBokehRadius: CGFloat = 15
	{
		didSet
		{
			probe = nil
		}
	}
	
	var inputBokehBias: CGFloat = 0.25
	{
		didSet
		{
			probe = nil
		}
	}
	
	private var probe: [UInt8]?
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "Circular Bokeh",
			"inputImage": [kCIAttributeIdentity: 0,
							  kCIAttributeClass: "CIImage",
						kCIAttributeDisplayName: "Image",
							   kCIAttributeType: kCIAttributeTypeImage],
			
			"inputBokehRadius": [kCIAttributeIdentity: 0,
									kCIAttributeClass: "NSNumber",
								  kCIAttributeDefault: 15,
							  kCIAttributeDisplayName: "Bokeh Radius",
									  kCIAttributeMin: 0,
								kCIAttributeSliderMin: 0,
								kCIAttributeSliderMax: 20,
									 kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputBlurRadius": [kCIAttributeIdentity: 0,
								   kCIAttributeClass: "NSNumber",
								 kCIAttributeDefault: 2,
							 kCIAttributeDisplayName: "Blur Radius",
									 kCIAttributeMin: 0,
							   kCIAttributeSliderMin: 0,
							   kCIAttributeSliderMax: 10,
									kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputBokehBias": [kCIAttributeIdentity: 0,
								  kCIAttributeClass: "NSNumber",
								kCIAttributeDefault: 0.25,
							kCIAttributeDisplayName: "Bokeh Bias",
									kCIAttributeMin: 0,
							  kCIAttributeSliderMin: 0,
							  kCIAttributeSliderMax: 1,
								   kCIAttributeType: kCIAttributeTypeScalar],
		]
	}
	
	var ciContext: CIContext!
	
//	override var outputImage: CIImage?
//	{
//		guard let inputImage = inputImage,
//			  let imageRef = ciContext.createCGImage(
//				inputImage,
//				from: inputImage.extent)
//		else
//		{
//			return nil
//		}
//
//
//		var imageBuffer = vImage_Buffer()
//
//		vImageBuffer_InitWithCGImage(
//			&imageBuffer,
//			&format,
//			nil,
//			imageRef,
//			UInt32(kvImageNoFlags))
//
//		let pixelBuffer = malloc(imageRef.bytesPerRow * imageRef.height)
//
//		var outBuffer = vImage_Buffer(
//			data: pixelBuffer,
//			height: UInt(imageRef.height),
//			width: UInt(imageRef.width),
//			rowBytes: imageRef.bytesPerRow)
//
//		let probeValue = UInt8((1 - inputBokehBias) * 30)
//		let radius = Int(inputBokehRadius)
//		let diameter = (radius * 2) + 1
//
//		if probe == nil
//		{
//			probe = stride(from: 0, to: (diameter * diameter), by: 1).map
//			{
//				let x = Float(($0 % diameter) - radius)
//				let y = Float(($0 / diameter) - radius)
//				let r = Float(radius)
//				let length = hypot(Float(x), Float(y)) / r
//
//				if length <= 1
//				{
//					let distanceToEdge = 1 - length
//
//					return UInt8(distanceToEdge * Float(probeValue))
//				}
//
//				return 255
//			}
//		}
//
//		vImageDilate_ARGB8888(
//			&imageBuffer,
//			&outBuffer,
//			0,
//			0,
//			probe!,
//			UInt(diameter),
//			UInt(diameter),
//			UInt32(kvImageEdgeExtend))
//
//		let outImage = CIImage(fromvImageBuffer: outBuffer)
//
//		free(pixelBuffer)
//		free(imageBuffer.data)
//
//		return outImage!.applyingFilter(
//			"CIGaussianBlur",
//			parameters: [kCIInputRadiusKey: inputBlurRadius])
//	}
}

// Histogram Equalization
class HistogramEqualization: CIFilter, VImageFilter
{
	var ciContext: CIContext!
	var inputImage: CGImage?
	var sourceBuffer: vImage_Buffer?
	var outputCGImage: CGImage?
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "Histogram Equalization",
			"inputImage": [kCIAttributeIdentity: 0,
							  kCIAttributeClass: "CIImage",
						kCIAttributeDisplayName: "Image",
							   kCIAttributeType: kCIAttributeTypeImage]
		]
	}
	
	
//	override var outputImage: CIImage?
//	{
//		guard let inputImage = inputImage,
//			  let imageRef = ciContext.createCGImage(
//				inputImage,
//				from: inputImage.extent) else
//				{
//					return nil
//				}
//
//
//		var imageBuffer = vImage_Buffer()
//
//		vImageBuffer_InitWithCGImage(
//			&imageBuffer,
//			&format,
//			nil,
//			imageRef,
//			UInt32(kvImageNoFlags))
//
//		let pixelBuffer = malloc(imageRef.bytesPerRow * imageRef.height)
//
//		var outBuffer = vImage_Buffer(
//			data: pixelBuffer,
//			height: UInt(imageRef.height),
//			width: UInt(imageRef.width),
//			rowBytes: imageRef.bytesPerRow)
//
//
//		vImageEqualization_ARGB8888(
//			&imageBuffer,
//			&outBuffer,
//			UInt32(kvImageNoFlags))
//
//		let outImage = CIImage(fromvImageBuffer: outBuffer)
//
//		free(imageBuffer.data)
//		free(pixelBuffer)
//
//		return outImage!
//	}
}

// MARK: EndsInContrastStretch
class EndsInContrastStretch: CIFilter, VImageFilter
{
	var ciContext: CIContext!
	var sourceBuffer: vImage_Buffer?
	var inputImage: CGImage?
	var outputCGImage: CGImage?
	var inputPercentLowRed: CGFloat = 0
	var inputPercentLowGreen: CGFloat = 0
	var inputPercentLowBlue: CGFloat = 0
	
	var inputPercentHiRed: CGFloat = 0
	var inputPercentHiGreen: CGFloat = 0
	var inputPercentHiBlue: CGFloat = 0
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "Ends In Contrast Stretch",
			"inputImage": [kCIAttributeIdentity: 0,
							  kCIAttributeClass: "CIImage",
						kCIAttributeDisplayName: "Image",
							   kCIAttributeType: kCIAttributeTypeImage],
			
			"inputPercentLowRed": [kCIAttributeIdentity: 0,
									  kCIAttributeClass: "NSNumber",
									kCIAttributeDefault: 0,
								kCIAttributeDisplayName: "Percent Low Red",
										kCIAttributeMin: 0,
								  kCIAttributeSliderMin: 0,
								  kCIAttributeSliderMax: 49,
									   kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputPercentLowGreen": [kCIAttributeIdentity: 0,
										kCIAttributeClass: "NSNumber",
									  kCIAttributeDefault: 0,
								  kCIAttributeDisplayName: "Percent Low Green",
										  kCIAttributeMin: 0,
									kCIAttributeSliderMin: 0,
									kCIAttributeSliderMax: 49,
										 kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputPercentLowBlue": [kCIAttributeIdentity: 0,
									   kCIAttributeClass: "NSNumber",
									 kCIAttributeDefault: 0,
								 kCIAttributeDisplayName: "Percent Low Blue",
										 kCIAttributeMin: 0,
								   kCIAttributeSliderMin: 0,
								   kCIAttributeSliderMax: 49,
										kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputPercentHiRed": [kCIAttributeIdentity: 0,
									 kCIAttributeClass: "NSNumber",
								   kCIAttributeDefault: 0,
							   kCIAttributeDisplayName: "Percent High Red",
									   kCIAttributeMin: 0,
								 kCIAttributeSliderMin: 0,
								 kCIAttributeSliderMax: 49,
									  kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputPercentHiGreen": [kCIAttributeIdentity: 0,
									   kCIAttributeClass: "NSNumber",
									 kCIAttributeDefault: 0,
								 kCIAttributeDisplayName: "Percent High Green",
										 kCIAttributeMin: 0,
								   kCIAttributeSliderMin: 0,
								   kCIAttributeSliderMax: 49,
										kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputPercentHiBlue": [kCIAttributeIdentity: 0,
									  kCIAttributeClass: "NSNumber",
									kCIAttributeDefault: 0,
								kCIAttributeDisplayName: "Percent High Blue",
										kCIAttributeMin: 0,
								  kCIAttributeSliderMin: 0,
								  kCIAttributeSliderMax: 49,
									   kCIAttributeType: kCIAttributeTypeScalar],
		]
	}
	
//	override var outputImage: CIImage?
//	{
//		guard let inputImage = inputImage,
//			  let imageRef = ciContext.createCGImage(
//				inputImage,
//				from: inputImage.extent) else
//				{
//					return nil
//				}
//
//
//
//		var imageBuffer = vImage_Buffer()
//
//		vImageBuffer_InitWithCGImage(
//			&imageBuffer,
//			&format,
//			nil,
//			imageRef,
//			UInt32(kvImageNoFlags))
//
//		let pixelBuffer = malloc(imageRef.bytesPerRow * imageRef.height)
//
//		var outBuffer = vImage_Buffer(
//			data: pixelBuffer,
//			height: UInt(imageRef.height),
//			width: UInt(imageRef.width),
//			rowBytes: imageRef.bytesPerRow)
//
//		let low = [inputPercentLowRed, inputPercentLowGreen, inputPercentLowBlue, 0].map { return UInt32($0) }
//		let hi = [inputPercentHiRed, inputPercentHiGreen, inputPercentHiBlue, 0].map { return UInt32($0) }
//
//		vImageEndsInContrastStretch_ARGB8888(
//			&imageBuffer,
//			&outBuffer,
//			low,
//			hi,
//			UInt32(kvImageNoFlags))
//
//		let outImage = CIImage(fromvImageBuffer: outBuffer)
//
//		free(imageBuffer.data)
//		free(pixelBuffer)
//
//		return outImage!
//	}
}

// MARK: Contrast Stretch
class ContrastStretch: CIFilter, VImageFilter
{
	var ciContext: CIContext!
	
	var sourceBuffer: vImage_Buffer?
	
	var inputImage: CGImage?
	var outputCGImage: CGImage?
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "Contrast Stretch",
			"inputImage": [kCIAttributeIdentity: 0,
							  kCIAttributeClass: "CIImage",
						kCIAttributeDisplayName: "Image",
							   kCIAttributeType: kCIAttributeTypeImage]
		]
	}
	
	
//	override var outputImage: CIImage?
//	{
//		guard let inputImage = inputImage,
//			  let imageRef = ciContext.createCGImage(
//				inputImage,
//				from: inputImage.extent) else
//				{
//					return nil
//				}
//
//
//
//		var imageBuffer = vImage_Buffer()
//
//		vImageBuffer_InitWithCGImage(
//			&imageBuffer,
//			&format,
//			nil,
//			imageRef,
//			UInt32(kvImageNoFlags))
//
//		let pixelBuffer = malloc(imageRef.bytesPerRow * imageRef.height)
//
//		var outBuffer = vImage_Buffer(
//			data: pixelBuffer,
//			height: UInt(imageRef.height),
//			width: UInt(imageRef.width),
//			rowBytes: imageRef.bytesPerRow)
//
//		vImageContrastStretch_ARGB8888(
//			&imageBuffer,
//			&outBuffer,
//			UInt32(kvImageNoFlags))
//
//		let outImage = CIImage(fromvImageBuffer: outBuffer)
//
//		free(imageBuffer.data)
//		free(pixelBuffer)
//
//		return outImage!
//	}
}
