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
	
	/// [ Filter name : CI Filter] key = String(describing: FilterType.self)
	private(set) var applyingFilters: [String: CIFilter]
	@Published var control = ControlValue()
	
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
		
		if applyingFilters[key] == nil {
			applyingFilters[key] = name != nil ? CIFilter(name: name!): T()
		}
		return applyingFilters[key] as! T
	}
	
	func getMetalFilter<T>(initClosure: @escaping () -> T, ciContext: CIContext) -> T where T: MetalFilter {
		let key = String(describing: T.self)
		if applyingFilters[key] == nil {
			let filter = initClosure()
			filter.ciContext = ciContext
			applyingFilters[key] = filter
		}
		return applyingFilters[key] as! T
	}
	
	func reset() {
		control = ControlValue()
		averageLuminace = 0.5
		faceRegions.removeAll()
		applyingFilters.removeAll()
	}
	
	func clearTextIfDefault() {
		if control.textStampContent == EditingState.ControlValue.defaultText {
			control.textStampContent = ""
		}
	}
	
	init() {
		control = ControlValue()
		averageLuminace = 0.5
		faceRegions = .init()
		applyingFilters = .init()
	}
	
	struct ControlValue {
		static let defaultText = "기본 텍스트"
		var blurIntensity: CGFloat = 10
		var blurMaskWidth: CGFloat = 30
		var averageLuminance: CGFloat = 0.5
		var outlineControl: (bias: CGFloat, weight: CGFloat) = (0.1, 0.1)
		var bilateralControl: (radius: CGFloat, intensity: CGFloat) = (0.1, 0.1)
		var vignetteControl: (radius: CGFloat, intensity: CGFloat, edgeBrightness: CGFloat) = (1, 2, -0.3)
		var textStampFont: (fontSize: CGFloat, descriptor: UIFontDescriptor) = (30, .init())
		var textStampControl: (radius: CGFloat, lensScale: CGFloat) = (10, 50)
		var textStampContent = Self.defaultText
		var textStampAlignment: TextMask.Alignment = .center
		var thresholdBrightness: CGFloat = 1.0
		var painterRadius: CGFloat = 0
		var selectedLUTName: String?
		var glitterAnglesAndRadius: [CGFloat: CGFloat] = [:]
		
		var colorControl: [SingleSliderFilterControl: CGFloat] = [.brightness, .contrast, .saturation].reduce(into: [:]) {
			dict, control in
			dict[control] = control.defaultValue
		}
		var selectiveControl: [SelectiveBrightness.FilterParameter.RGBColor: SelectiveBrightness.selectableValues] = SelectiveBrightness.FilterParameter.RGBColor.allCases.reduce(
			into: .init()) { dict , rgbComponent in
			dict[rgbComponent] = SelectiveBrightness.emptyValues
		}
	}
}
