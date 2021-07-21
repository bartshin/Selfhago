//
//  EditingState.swift
//  moody
//
//  Created by bart Shin on 17/07/2021.
//

import CoreImage
import UIKit

class EditingState: ObservableObject {
	
	// MARK: Image data
	private(set) var originalCgImage: CGImage?
	private(set) var imageExtent: CGRect?
	var averageLuminace: CGFloat
	var faceRegions: [CGRect]
	
	// MARK: Filter
	/// [ Filter name : CI Filter] key = String(describing: FilterType.self)
	private(set) var filters: [String: CIFilter]
	
	// Blur
	@Published var blurMarkerWidth: CGFloat
	var blurIntensity: Double
	// Bilateral
	var bilateralControl: (radius: CGFloat, intensity: CGFloat)
	// Outline
	var outlineControl: (bias: CGFloat, weight: CGFloat)
	// CIColor
	var colorControl: [CIColorFilterControl: Double]
	// SeletivBrightness
	var selectiveControl: [SelectiveBrightness.FilterParameter.RGBColor: SelectiveBrightness.selectableValues]
	// Vignette
	var vignetteControl: (radius: CGFloat, intensity: CGFloat, edgeBrightness: CGFloat)
	// Glitter
	var thresholdBrightness: CGFloat
	var glitterAnglesAndRadius: [CGFloat: CGFloat]
	// LUT
	var selectedLUTName: String?
	
	func setNewImageData(_ image: UIImage) -> CIImage {
		originalCgImage = image.cgImage
		if originalCgImage == nil {
			assertionFailure("Missing cg image")
			return CIImage()
		}
		let ciImage = CIImage(
			cgImage: originalCgImage!,
			options: [.applyOrientationProperty: true,
					  .properties: [kCGImagePropertyOrientation: image.imageOrientation.cgOrientation.rawValue]])
		imageExtent = ciImage.extent
		return ciImage
	}
	
	func getFilter<T>(_ filterType: T.Type, name: String? = nil) -> T where T: CIFilter {
		let key = name ?? String(describing: T.self)
		if filters[key] == nil {
			filters[key] = name != nil ? CIFilter(name: name!): T()
		}
		return filters[key] as! T
	}
	
	func resetControls() {
		colorControl = CIColorFilterControl.defaults
		blurIntensity = DefaultValues.blurIntensity
		blurMarkerWidth = DefaultValues.blurMaskWidth
		averageLuminace = DefaultValues.averageLuminance
		bilateralControl = DefaultValues.bilateralControl
		outlineControl = DefaultValues.outlineControl
		vignetteControl = DefaultValues.vignetteControl
		thresholdBrightness = DefaultValues.thresholdBrightness
		selectiveControl.keys.forEach { rgbComponent in
			selectiveControl[rgbComponent] = SelectiveBrightness.emptyValues
		}
		glitterAnglesAndRadius.removeAll()
		faceRegions.removeAll()
		filters.removeAll()
	}
	
	init() {
		colorControl = CIColorFilterControl.defaults
		blurIntensity = DefaultValues.blurIntensity
		blurMarkerWidth = DefaultValues.blurMaskWidth
		averageLuminace = DefaultValues.averageLuminance
		bilateralControl = DefaultValues.bilateralControl
		outlineControl = DefaultValues.outlineControl
		vignetteControl = DefaultValues.vignetteControl
		thresholdBrightness = DefaultValues.thresholdBrightness
		glitterAnglesAndRadius = .init()
		faceRegions = .init()
		filters = .init()
		selectiveControl = SelectiveBrightness.FilterParameter.RGBColor.allCases.reduce(
			into: .init()) { dict , rgbComponent in
			dict[rgbComponent] = SelectiveBrightness.emptyValues
		}
	}
	
	struct DefaultValues {
		static let blurIntensity: Double = 10
		static let blurMaskWidth: CGFloat = 30
		static let averageLuminance: CGFloat = 0.5
		static let outlineControl: (CGFloat, CGFloat) = (0.1, 0.1)
		static let bilateralControl: (CGFloat, CGFloat) = (0.1, 0.1)
		static let vignetteControl: (CGFloat, CGFloat, CGFloat) = (1, 2, -0.3)
		static let thresholdBrightness: CGFloat = 1.0
	}
}
