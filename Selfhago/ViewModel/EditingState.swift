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
	private(set) var imageOrientaion: CGImagePropertyOrientation?
	var lastFilterTrigger: TimeInterval?
	var currentExcutingFilterTrigger: TimeInterval?
	var ciImage: CIImage {
		CIImage(
			cgImage: originalCgImage!,
			options: [.applyOrientationProperty: true,
					  .properties: [kCGImagePropertyOrientation: imageOrientaion!.rawValue]])
	}
	
	/// [ Filter name : CI Filter] key = String(describing: FilterType.self)
	private(set) var applyingFilters: [String: CIFilter]
	@Published var control = ControlValue()
	@Published var isRecording = false
	@Published var depthDataAvailable = false
	var presetThumnails: [String: UIImage] = [:]
	var glitterPresetImages = [UIImage]()
	
	func setNewImage(_ image: UIImage) {
		originalCgImage = image.cgImage
		if originalCgImage == nil {
			assertionFailure("Missing cg image")
			return
		}
		imageOrientaion = image.imageOrientation.cgOrientation
	}
	
	func getFilter<T>(_ filterType: T.Type, name: String? = nil) -> T where T: CIFilter {
		let key = name ?? String(describing: T.self)
		
		if applyingFilters[key] == nil {
			applyingFilters[key] = name != nil ? CIFilter(name: name!): T()
		}
		return applyingFilters[key] as! T
	}
	
	func getMetalFilter<T>(initClosure: @escaping () -> T) -> T where T: MetalFilter {
		let key = String(describing: T.self)
		if applyingFilters[key] == nil {
			let filter = initClosure()
			applyingFilters[key] = filter
		}
		return applyingFilters[key] as! T
	}
	
	func reset() {
		DispatchQueue.main.async { [self] in
			control = ControlValue()
			applyingFilters.removeAll()
		}
	}
	
	func clearTextIfDefault() {
		if control.textStampContent == EditingState.ControlValue.defaultText {
			control.textStampContent = ""
		}
	}
	
	init() {
		control = ControlValue()
		applyingFilters = .init()
	}
	
	struct ControlValue {
		static let defaultText = "기본 텍스트"
		var blurIntensity: CGFloat = 10
		var blurMaskWidth: CGFloat = 30
		var averageLuminance: CGFloat = 0.5
		var outlineControl: (bias: CGFloat, weight: CGFloat) = (0.1, 0.1)
		var bilateralControl: (radius: CGFloat, intensity: CGFloat) = (0.1, 0.1)
		var vignetteControl: (radius: CGFloat, intensity: CGFloat, edgeBrightness: CGFloat) = (0, 0, 0)
		var textStampFont: (fontSize: CGFloat, descriptor: UIFontDescriptor) = (30, .init())
		var textStampControl: (opacity: CGFloat, rotation: CGFloat) = (1, 0)
		var textStampContent = Self.defaultText
		var textStampColor: UIColor = .black
		var thresholdBrightness: CGFloat = 1.0
		var painterRadius: CGFloat = 0
		var selectedLUTName: String?
		var glitterAnglesAndRadius: [CGFloat: CGFloat] = [:]
		var depthFocus: CGFloat = 0.1
		
		var colorControl: [SingleSliderFilterControl: CGFloat] = [.brightness, .contrast, .saturation].reduce(into: [:]) {
			dict, control in
			dict[control] = control.defaultValue
		}
		var colorChannelControl = [ColorChannel.InputParameter.Component.red, .green, .blue].reduce(
			into: [:]) { dict , rgbComponent in
			dict[rgbComponent] = ColorChannel.emptyValues
		}
	}
}
