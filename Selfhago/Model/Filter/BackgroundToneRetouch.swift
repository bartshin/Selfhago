//
//  BackgroundToneRetouch.swift
//  Selfhago
//
//  Created by bart Shin on 31/07/2021.
//

import CoreImage

class BackgroundToneRetouch: CIFilter {
	
	private lazy var toneRetouchFilter = HistogramSpecification()
	private lazy var blendFilter = CIFilter(name: "CIBlendWithMask")!
	private var targetImage: CIImage?
	private var depthMaskImage: CIImage?
	private var inputImage: CIImage?
	private var focus: CGFloat = 0
	private var toneRetouchedImage: CIImage?
	var ciContext: CIContext! {
		didSet {
			toneRetouchFilter.ciContext = ciContext
		}
	}
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey,
		   let image = value as? CIImage {
			if inputImage != image {
				toneRetouchedImage = nil
			}
			inputImage = image
		}
		else if key == kCIInputMaskImageKey ,
				let mask = value as? CIImage?{
			depthMaskImage = mask
		}
		else if key == kCIInputBackgroundImageKey,
				let image = value as? CIImage {
			if targetImage != image {
				toneRetouchedImage = nil
			}
			targetImage = image
		}
		else if key == kCIInputIntensityKey,
				let focus = value as? CGFloat {
			self.focus = focus
		}
	}
	
	override func value(forKey key: String) -> Any? {
		if key == kCIInputIntensityKey {
			return focus
		}
		return nil
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterName: String(describing: Self.self)
		]
	}
	
	private func setToneRetouchedImage() {
		toneRetouchFilter.setValue(inputImage!, forKey: kCIInputImageKey)
		toneRetouchFilter.setValue(targetImage!, forKey: kCIInputTargetImageKey)
		toneRetouchedImage = toneRetouchFilter.outputImage
	}
	
	override var outputImage: CIImage? {
		guard inputImage != nil,
			  depthMaskImage != nil,
			  targetImage != nil else {
			return nil
		}
		if toneRetouchedImage == nil {
			setToneRetouchedImage()
		}
		blendFilter.setValue(toneRetouchedImage, forKey: kCIInputImageKey)
		blendFilter.setValue(inputImage!, forKey: kCIInputBackgroundImageKey)
		blendFilter.setValue(depthMaskImage!, forKey: kCIInputMaskImageKey)
		return blendFilter.outputImage
	}
}
