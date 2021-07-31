//
//  Vignette.swift
//  moody
//
//  Created by bart Shin on 17/07/2021.
//

import CoreImage

class Vignette: CIFilter {
	
	private var inputRadius: CGFloat = 0
	private var inputIntensity: CGFloat = 0
	private var inputEdgeBrightness: CGFloat = 0
	private var inputImage: CIImage?
	
	override func setValue(_ value: Any?, forKey key: String) {
		switch key {
			case kCIInputImageKey:
				inputImage = value as? CIImage
			case kCIInputRadiusKey:
				if let radius = value as? CGFloat {
					inputRadius = radius
				}
			case kCIInputBrightnessKey:
				if let brightness = value as? CGFloat {
					inputEdgeBrightness = brightness
				}
			case kCIInputIntensityKey:
				if let intensity = value as? CGFloat {
					inputIntensity = intensity
				}
			default:
				break
		}
	}
	
	override func value(forKey key: String) -> Any? {
		switch key {
			case kCIInputRadiusKey:
				return inputRadius
			case kCIInputBrightnessKey:
				return inputEdgeBrightness
			case kCIInputIntensityKey:
				return inputIntensity
			default:
				return nil
		}
	}
	
	override var attributes: [String : Any] {
		return [
			kCIAttributeFilterName: String(describing: Self.self)
		]
	}
	
	private func createMask(in rect: CGRect) -> CIImage {
		return CIImage(color: .white)
			.cropped(to: rect)
			.applyingFilter("CIVignette",
							parameters: [
								kCIInputRadiusKey: inputRadius,
								kCIInputIntensityKey: inputIntensity
			])
	}
	
	private func createNoirImage() -> CIImage {
		inputImage!.applyingFilter("CIPhotoEffectNoir")
			.applyingFilter("CIColorControls",
							parameters: [
								kCIInputBrightnessKey: inputEdgeBrightness])
	}
	
	override var outputImage: CIImage? {
		guard inputImage != nil else {
			return nil
		}
		if inputRadius == 0 || inputIntensity == 0 {
			return inputImage!
		}
		return inputImage!.applyingFilter(
			"CIBlendWithMask",
			parameters: [
				kCIInputImageKey: inputImage!,
				kCIInputBackgroundImageKey: createNoirImage(),
				kCIInputMaskImageKey: createMask(in: inputImage!.extent)])
	}
	
}
