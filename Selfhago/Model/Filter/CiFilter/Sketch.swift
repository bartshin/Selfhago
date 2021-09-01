//
//  Sketch.swift
//  Sketch
//
//  Created by bart Shin on 2021/08/23.
//

import CoreImage
import UIKit

class Sketch: CIFilter {
	
	static let thresholdKey = "inputThreshold"
	static let noiseLevelKey = "inputNRNoiseLevel"
	static let edgeIntensityKey = "inputEdgeIntensity"
	
	private lazy var lineOverlayFilter = CIFilter(name: "CILineOverlay")!
	private lazy var multiplyFilter = CIFilter(name: "CIMultiplyCompositing")!
	private lazy var compositeFilter = CIFilter(name: "CISourceAtopCompositing")!
	private lazy var colorInvertFilter = CIFilter(name: "CIColorInvert")!
	private var inputImage: CIImage?
	private var inputThreshold: CGFloat = 0.1
	private var noiseLevel: CGFloat = 0.07
	private var edgeIntensity: CGFloat = 0.25
	private var penColor: UIColor = .black
	private var backgroundImage: CIImage?
	
	override func setValue(_ value: Any?, forKey key: String) {
		switch key {
			case kCIInputImageKey:
				inputImage = value as? CIImage
			case Self.thresholdKey:
				if let threshold = value as? CGFloat {
					inputThreshold = threshold
				}
			case Self.noiseLevelKey:
				if let noiseLevel = value as? CGFloat {
					self.noiseLevel = noiseLevel
				}
			case Self.edgeIntensityKey:
				if let intensity = value as? CGFloat {
					edgeIntensity = intensity
				}
			case kCIInputColorKey:
				if let color = value as? UIColor {
					penColor = color
				}
			case kCIInputBackgroundImageKey:
				if let background = value as? CIImage {
					backgroundImage = background
				}
			default:
				break
		}
	}
	
	override func value(forKey key: String) -> Any? {
		switch key {
			case Self.thresholdKey:
				return inputThreshold
			case Self.noiseLevelKey:
				return noiseLevel
			case Self.edgeIntensityKey:
				return edgeIntensity
			case kCIInputColorKey:
				return penColor
			case kCIInputBackgroundImageKey:
				return backgroundImage
			default:
				return nil
		}
	}
	
	override var attributes: [String : Any] {
		return [
			kCIAttributeFilterName: String(describing: Self.self)
		]
	}
	
	override var outputImage: CIImage? {
		guard inputImage != nil else {
			return nil
		}
		
		lineOverlayFilter.setValue(inputImage, forKey: kCIInputImageKey)
		lineOverlayFilter.setValue(inputThreshold, forKey: Self.thresholdKey)
		lineOverlayFilter.setValue(noiseLevel, forKey: Self.noiseLevelKey)
		lineOverlayFilter.setValue(edgeIntensity, forKey: Self.edgeIntensityKey)
		
		colorInvertFilter.setValue(lineOverlayFilter.outputImage, forKey: kCIInputImageKey)
		
		multiplyFilter.setValue(colorInvertFilter.outputImage, forKey: kCIInputImageKey)
		multiplyFilter.setValue(CIImage(color: CIColor(color: penColor)).cropped(to: inputImage!.extent), forKey: kCIInputBackgroundImageKey)
	
		let background = backgroundImage ?? CIImage(color: CIColor(color: .white)).cropped(to: inputImage!.extent)
		compositeFilter.setValue(multiplyFilter.outputImage, forKey: kCIInputImageKey)
		compositeFilter.setValue(background, forKey: kCIInputBackgroundImageKey)
		return compositeFilter.outputImage
	}
}
