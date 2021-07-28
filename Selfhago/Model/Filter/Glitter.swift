//
//  Glitter.swift
//  moody
//
//  Created by bart Shin on 19/07/2021.
//

import CoreImage

class Glitter: CIFilter {
	
	private var inputImage: CIImage?
	private var anglesAndRadius = [CGFloat: CGFloat]()
	private var threshold: CGFloat = 1
	private lazy var thresholdKernel = findKernel(by: "threshold", from: "UtilityFilter")
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey{
			inputImage = value as? CIImage
		}
		else if key == kCIInputAngleKey,
				let anglesAndRadius = value as? [CGFloat: CGFloat]{
			self.anglesAndRadius = anglesAndRadius
		}
		else if key == kCIInputBrightnessKey,
				let threshold = value as? CGFloat {
			self.threshold = threshold
		}
	}
	
	override func value(forKey key: String) -> Any? {
		if key == kCIInputAngleKey {
			return anglesAndRadius
		}
		else if key == kCIInputBrightnessKey {
			return threshold
		}
		else {
			return nil
		}
	}
	
	override var outputImage: CIImage?{
		if anglesAndRadius.isEmpty {
			return inputImage
		}
		guard inputImage != nil,
			  let thresholdImage = createThresholdImage(),
			  let sparkleImage = createSparkleImage(by: thresholdImage) else {
			return nil
		}
		return inputImage!.applyingFilter("CIAdditionCompositing",
								   parameters: [
									kCIInputBackgroundImageKey: sparkleImage
								   ])
	}
	
	private func createThresholdImage() -> CIImage? {
		return thresholdKernel.apply(
			extent: inputImage!.extent,
			roiCallback: { index, rect in
				rect
			}, arguments: [inputImage!,
						   threshold])
	}
	
	private func createSparkleImage(by thresholdImage: CIImage) -> CIImage? {
		guard let accumulator = CIImageAccumulator(
			extent: thresholdImage.extent,
				format: CIFormat.ARGB8) else {
			return nil
		}
		let size = min(thresholdImage.extent.width, thresholdImage.extent.height)
		for (angle, radius) in anglesAndRadius {
			let blurImage = thresholdImage.applyingFilter(
				"CIMotionBlur",
				parameters: [
					kCIInputRadiusKey: radius * size/15,
					kCIInputAngleKey: .pi * 2 - angle
				])
				.cropped(to: thresholdImage.extent)
				.applyingFilter("CIAdditionCompositing",
								parameters: [
									kCIInputBackgroundImageKey: accumulator.image()
								])
			accumulator.setImage(blurImage)
		}
		return accumulator.image()
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterName: String(describing: Self.self)
		]
	}
	
}
