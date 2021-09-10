//
//  Glitter.swift
//  Selfhago
//
//  Created by bart Shin on 19/07/2021.
//

import CoreImage
import UIKit

class Glitter: CIFilter {
	
	private var inputImage: CIImage?
	private var anglesAndRadius = [CGFloat: CGFloat]()
	private var threshold: CGFloat = 1
	private lazy var thresholdKernel = findKernel("threshold", in: "utilityFilter")
	
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
	
	// MARK: - Preset image
	
	static let presetImageSize = CGSize(width: 128, height: 128)
	static let presetAngleAndRadius: [[CGFloat: CGFloat]] = [
		[.pi: 1, .pi/2: 1 ],
		[.pi: 0.5, .pi/2: 1],
		[.pi: 1, .pi/2: 0.5],
		[.pi: 0.5, .pi/2: 0.5],
		[.pi/4: 1, .pi*3/4: 1],
		[.pi/4: 0.5, .pi*3/4: 1],
		[.pi/4: 1, .pi*3/4: 0.5],
		[.pi/4: 0.5, .pi*3/4: 0.5]
	]
	
	fileprivate static func createCircleImage(in size: CGSize? = nil) -> CIImage {
		let frame = CGRect(origin: .zero, size: size ?? presetImageSize)
		let radius = min(frame.width, frame.height) * 0.1
		let renderer = UIGraphicsImageRenderer(bounds: frame)
		let circleImage = renderer.image { context in
			context.cgContext.setFillColor(UIColor.white.cgColor)
			context.cgContext.addEllipse(in: CGRect(origin: CGPoint(x: frame.midX - radius/2,
																	y: frame.midY - radius/2),
													size: CGSize(width: radius, height: radius)))
			context.cgContext.drawPath(using: .fill)
		}
		return CIImage(image: circleImage)!
	}
	
	static func createPresetImages() -> [CIImage] {
		let filter = Glitter()
		let circleImage = createCircleImage()
		let blackBackground = CIImage(color: .black).cropped(to: circleImage.extent)
		var presetImages = [CIImage]()
		let compositeFilter = CIFilter(name: "CISourceAtopCompositing")!
		compositeFilter.setValue(blackBackground, forKey: kCIInputBackgroundImageKey)
		presetAngleAndRadius.forEach { angleAndRadius in
			filter.setValue(angleAndRadius, forKey: kCIInputAngleKey)
			guard let presetImage = filter.createPresetImage(by: circleImage) else {
				print("Fail to create preset image")
				return
			}
			compositeFilter.setValue(presetImage, forKey: kCIInputImageKey)
			if let outputImage = compositeFilter.outputImage {
				presetImages.append(outputImage)
			}
		}
		return presetImages
	}
	
	static func createPresetImage(for angleAndRadius: [CGFloat: CGFloat], in size: CGSize) -> CIImage {
		let filter = Glitter()
		let circleImage = createCircleImage(in: size)
		filter.setValue(angleAndRadius, forKey: kCIInputAngleKey)
		return filter.createPresetImage(by: circleImage) ?? CIImage()
	}
	
	private func createPresetImage(by circleImage: CIImage) -> CIImage? {
		guard let accumulator = CIImageAccumulator(
				extent: circleImage.extent,
				format: CIFormat.ARGB8) else {
			return nil
		}
		let size = min(circleImage.extent.width, circleImage.extent.height)
		for (angle, radius) in anglesAndRadius {
			let blurImage = circleImage.applyingFilter(
				"CIMotionBlur",
				parameters: [
					kCIInputRadiusKey: radius * size/5,
					kCIInputAngleKey: .pi * 2 - angle
				])
				.cropped(to: circleImage.extent)
				.applyingFilter("CIAdditionCompositing",
								parameters: [
									kCIInputBackgroundImageKey: accumulator.image()
								])
			accumulator.setImage(blurImage)
		}
		return accumulator.image().settingAlphaOne(in: circleImage.extent)
	}
	
}


