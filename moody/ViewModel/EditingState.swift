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
	/// [ Filter name : CI Filter]
	var filters: [String: CIFilter]
	
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
		selectiveControl.keys.forEach {
			selectiveControl[$0] = SelectiveBrightness.emptyValues
		}
		bilateralControl = (0.1, 0.1)
		filters = [:]
	}
	
	init() {
		colorControl = CIColorFilterControl.defaults
		blurIntensity = 10
		blurMarkerWidth = 30
		averageLuminace = 0.5
		bilateralControl = (0.1, 0.1)
		outlineControl = (0.1, 0.1)
		vignetteControl = (1, 2, -0.3)
		faceRegions = []
		filters = [:]
		selectiveControl = SelectiveBrightness.FilterParameter.RGBColor.allCases.reduce(into: [SelectiveBrightness.FilterParameter.RGBColor: SelectiveBrightness.selectableValues]()) {
			$0[$1] = SelectiveBrightness.emptyValues
		}
	}
}
