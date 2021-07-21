//
//  SobelEdgeDetection.swift
//  Filterpedia
//
//  Created by Simon Gladman on 18/03/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import CoreImage

class SobelEdgeDetection3x3: SobelOutline
{
	let horizontalSobel = CIVector(values: [
									-1, 0, 1,
									-2, 0, 2,
									-1, 0, 1], count: 9)
	
	let verticalSobel = CIVector(values: [
									-1, -2, -1,
									0,  0,  0,
									1,  2,  1], count: 9)
	
	override var outputImage: CIImage?
	{
		guard let inputImage = inputImage else
		{
			return nil
		}
		if inputBias == 0,
		   inputWeight == 0 {
			return inputImage
		}
		
		let final = sobel(sourceImage: inputImage,
						  filterName: "CIConvolution3X3",
						  horizontalWeights: horizontalSobel,
						  verticalWeights: verticalSobel)
		
		return makeOpaqueKernel.apply(extent: inputImage.extent, roiCallback: { index, rect in
			rect
		}, arguments: [final])
	}
	
	override func kernelSize() -> Int
	{
		return 3
	}
}

// FIXME: Sometimes create all black output image
class SobelEdgeDetection5x5: SobelOutline
{
	let horizontalSobel = CIVector(values: [
									-1, -2, 0, 2, 1,
									-4, -8, 0, 8, 4,
									-6, -12, 0, 12, 6,
									-4, -8, 0, 8, 4,
									-1, -2, 0, 2, 1], count: 25)
	
	let verticalSobel = CIVector(values: [
									-1, -4, -6, -4, -1,
									-2, -8, -12, -8, -2,
									0, 0, 0, 0, 0,
									2, 8, 12, 8, 2,
									1, 4, 6, 4, 1], count: 25)
	
	override var outputImage: CIImage?
	{
		guard let inputImage = inputImage else
		{
			return nil
		}
		
		let final = sobel(sourceImage: inputImage,
						  filterName: "CIConvolution5X5",
						  horizontalWeights: horizontalSobel,
						  verticalWeights: verticalSobel)
		
		return makeOpaqueKernel.apply(extent: inputImage.extent, roiCallback: { index, rect in
			rect
		}, arguments: [final])
	}
	
	override func kernelSize() -> Int
	{
		return 5
	}
}

class SobelOutline: CIFilter
{
	lazy var makeOpaqueKernel = findKernel(by: "makeOpaque")
	
	func sobel(sourceImage: CIImage, filterName: String, horizontalWeights: CIVector, verticalWeights: CIVector) -> CIImage
	{
		sourceImage
			.applyingFilter(filterName,
							parameters: [
								kCIInputWeightsKey: horizontalWeights.multiply(value: inputWeight),
								kCIInputBiasKey: inputBias])
			.applyingFilter(filterName,
							parameters: [
								kCIInputWeightsKey:  verticalWeights.multiply(value:  inputWeight),
								kCIInputBiasKey: inputBias])
			.cropped(to: sourceImage.extent)
	}
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey,
		   let image = value as? CIImage{
			inputImage = image
		}
		else if key == kCIInputBiasKey,
				let bias = value as? CGFloat{
			inputBias = bias
		}
		else if key == kCIInputWeightsKey,
				let weight = value as? CGFloat {
			inputWeight = weight
		}
	}
	
	override func value(forKey key: String) -> Any? {
		if key == kCIInputBiasKey{
			return inputBias
		}
		else if key == kCIInputWeightsKey{
			return inputWeight
		}
		else if key == kCIInputScaleKey {
			return kernelSize()
		}
		return nil
	}
	
	var inputImage : CIImage?
	var inputBias: CGFloat = 0
	var inputWeight: CGFloat = 0
	
	func kernelSize() -> Int
	{
		fatalError("SobelEdgeDetectionBase must be sublassed")
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterName: String(describing: Self.self),
			kCIAttributeName: String(describing: Self.self),
			"inputImage": [kCIAttributeIdentity: 0,
						   kCIAttributeClass: "CIImage",
						   kCIAttributeDisplayName: "Image",
						   kCIAttributeType: kCIAttributeTypeImage],
			
			"inputBias": [kCIAttributeIdentity: 0,
						  kCIAttributeClass: "NSNumber",
						  kCIAttributeDefault: 1,
						  kCIAttributeDisplayName: "Bias",
						  kCIAttributeMin: 0,
						  kCIAttributeSliderMin: 0,
						  kCIAttributeSliderMax: 2,
						  kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputWeight": [kCIAttributeIdentity: 0,
							kCIAttributeClass: "NSNumber",
							kCIAttributeDefault: 1,
							kCIAttributeDisplayName: "Weight",
							kCIAttributeMin: 0,
							kCIAttributeSliderMin: 0,
							kCIAttributeSliderMax: 4,
							kCIAttributeType: kCIAttributeTypeScalar],
		]
	}
	
}
