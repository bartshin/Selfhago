//
//  EditingState.swift
//  Selfhago
//
//  Created by bart Shin on 17/07/2021.
//

import CoreImage
import UIKit
import CoreHaptics
import PencilKit
import Accelerate

class EditingState: ObservableObject {
	
	// MARK: Image data
	private(set) var originalCgImage: CGImage?
	private(set) var imageOrientaion: CGImagePropertyOrientation?
	var lastFilterTrigger: TimeInterval?
	var currentExcutingFilterTrigger: TimeInterval?
	private(set) var currentEditingImage: CIImage?
	var ciImage: CIImage {
		CIImage(
			cgImage: originalCgImage!,
			options: [.applyOrientationProperty: true,
					  .properties: [kCGImagePropertyOrientation: imageOrientaion!.rawValue]])
	}
	/// [ Filter name : CI Filter] key = String(describing: FilterType.self)
	private(set) var applyingCIFilters: [String: CIFilter]
	private(set) var applyingVImageFilters: [String: VImageFilter]
	@Published var control: ControlValue {
		willSet {
			generateHapticIfNeeded(newValue)
		}
	}
	private(set) var drawingMaskView: PKCanvasView
	@Published var isRecording = false
	@Published var depthDataAvailable: Bool?
	@Published var imageFlipped = (horizontal: false, vertical: false) {
		didSet {
			restoreFlip()
		}
	}
	var presetThumnails: [String: UIImage] = [:]
	var glitterPresetImages = [UIImage]()
	private var hapticEngine: CHHapticEngine?
	let drawingToolPicker: PKToolPicker
	private(set) var imageSize: CGSize?
	var originalRatio: CGFloat? {
		if imageSize != nil {
			return imageSize!.width / imageSize!.height
		}else {
			return nil
		}
	}
	
	func setNewImage(_ image: UIImage) {
		originalCgImage = image.cgImage
		if originalCgImage == nil {
			assertionFailure("Missing cg image")
			return
		}
		imageOrientaion = image.imageOrientation.cgOrientation
		setImageSize(image.size)
	}
	
	func setImageSize(_ size: CGSize) {
		self.imageSize = size
	}
	
	func changeCurrentEditingImage(_ image: CIImage?) {
		currentEditingImage = image
	}
	
	func getFilter<T>(_ filterType: T.Type, name: String? = nil) -> T where T: CIFilter {
		let key = name ?? String(describing: T.self)
		
		if T.self is VImageFilter.Type {
		   if applyingVImageFilters[key] == nil {
			   applyingVImageFilters[key] = (T() as! VImageFilter)
		   }
			return applyingVImageFilters[key] as! T
		}
		else if	applyingCIFilters[key] == nil {
			applyingCIFilters[key] = name != nil ? CIFilter(name: name!): T()
		}
		return applyingCIFilters[key] as! T
	}
	
	func getMetalFilter<T>(initClosure: @escaping () -> T) -> T where T: MetalFilter {
		let key = String(describing: T.self)
		if applyingCIFilters[key] == nil {
			let filter = initClosure()
			applyingCIFilters[key] = filter
		}
		return applyingCIFilters[key] as! T
	}
	
	func removeFilter<T>(_ filterType: T.Type, name: String? = nil) {
		let key = name ?? String(describing: T.self)
		applyingCIFilters[key] = nil
	}
	
	func reset() {
		DispatchQueue.main.async { [self] in
			control = ControlValue.defaultValue
			applyingCIFilters.removeAll()
			depthDataAvailable = nil
		}
	}
	
	func resetViewFinder() {
		control.viewFinderRect = CGRect(origin: .zero, size: imageSize!)
	}
	
	func detachEditingImage() -> CIImage? {
		defer {
			currentEditingImage = nil
		}
		return currentEditingImage
	}
	
	func clearTextIfDefault() {
		if control.textStampContent == EditingState.ControlValue.defaultText {
			control.textStampContent = ""
		}
	}
	
	func setViewFinderRatio(_ ratio: CGFloat?) {
		guard let ratio = ratio,
			  let imageSize = imageSize else {
				  control.viewFinderRatio = nil
				  return
		}
		if ratio < 1 {
			let scaledWidth = imageSize.height * ratio
			let newOriginX = (imageSize.width - scaledWidth)/2
			control.viewFinderRect = CGRect(x: newOriginX, y: 0,
											width: scaledWidth, height: imageSize.height)
		}
		else {
			let scaledHeight = imageSize.width * 1/ratio
			let newOriginY = (imageSize.height - scaledHeight)/2
			control.viewFinderRect = CGRect(x: 0, y: newOriginY,
											width: imageSize.width, height: scaledHeight)
		}
		control.viewFinderRatio = ratio
	}
	
	private func generateHapticIfNeeded(_ newControl: ControlValue) {
		guard hapticEngine != nil else {
			return
		}
		
		let angleOffset = abs(newControl.rotation - control.rotation)
		
		guard angleOffset >= 0.5 else {
			return
		}
		var events = [CHHapticEvent]()
		if angleOffset < 10 {
			events.append( CHHapticEvent(eventType: .hapticTransient,
									  parameters: [.init(parameterID: .hapticIntensity,
														 value: Float(max(0.1 + angleOffset/10, 0.3)))],
									  relativeTime: 0))
		}
		else {
			for sec in stride(from: 0, to: 0.3, by: 0.1) {
				events.append(
					CHHapticEvent(eventType: .hapticTransient,
										  parameters: [.init(parameterID: .hapticIntensity,
															 value: Float(1 - sec)/2)], relativeTime: sec))
			}
			for sec in stride(from: 0.4, to: 0.1, by: 0.2) {
				events.append(
					CHHapticEvent(eventType: .hapticTransient,
								  parameters: [.init(parameterID: .hapticIntensity,
													 value: Float(1 - sec)/3)], relativeTime: sec))
			}
		}
		if let pattern = try? CHHapticPattern(events: events, parameters: []),
		   let player = try? hapticEngine!.makePlayer(with: pattern) {
			try? player.start(atTime: CHHapticTimeImmediate)
		}
	}
	
	func changeDrawingTool(type: PKInkingTool.InkType? = nil, width: CGFloat? = nil, color: UIColor? = nil) {
		control.drawingTool = PKInkingTool(type ?? control.drawingTool.inkType,
										   color: color ?? control.drawingTool.color,
										   width: width ?? control.drawingTool.width)
	}
	
	func resetDrawing() {
		drawingMaskView.drawing.strokes.removeAll()
		control.isDrawing = false
	}
	
	private func restoreFlip() {
		if imageFlipped != (false, false) {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				self.imageFlipped = (false, false)
			}
		}
	}
	
	func resetPerspectiveControl() {
		control.perspectiveControl = [
			CGPoint(x: 0, y: 0),
			CGPoint(x: 1, y: 0),
			CGPoint(x: 0, y: 1),
			CGPoint(x: 1, y: 1)
		]
	}
	
	func resetOutlineColor(to filter: MultiSliderFilterControl.OutlineFilter) {
		control.selectedOutlineFilter = filter
		control.outlineControl = ControlValue.defaultValues(for: filter)
	}
	
	init() {
		control = ControlValue.defaultValue
		applyingCIFilters = .init()
		applyingVImageFilters = .init()
		drawingMaskView = PKCanvasView()
		drawingMaskView.overrideUserInterfaceStyle = .light
		drawingToolPicker = PKToolPicker()
		if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
			hapticEngine = try? CHHapticEngine()
			try? hapticEngine?.start()
		}
		drawingToolPicker.selectedTool = control.drawingTool
	}
	
	struct ControlValue {
		// Color
		var averageLuminance: CGFloat = 0.5
		var ciColorControl: [SingleSliderFilterControl: CGFloat] = [
			.brightness: 0,
			.saturation: 1,
			.contrast: 1
		]
		var colorChannelControl = [ColorChannel.InputParameter.Component.red, .green, .blue].reduce(
			into: [:]) { dict , rgbComponent in
				dict[rgbComponent] = ColorChannel.emptyValues
			}
		
		var gammaParameter = GammaAdjustment.Parameter(
			inputGamma: 1.0,
			exponentialCoefficients: [1, 0, 0],
			linearCoefficients: [1, 0],
			linearBoundary: 0.5)
		
		// Drawing
		var isDrawing = false
		var drawingTool: PKInkingTool = {
			let color: UIColor = DesignConstant.isDarkMode ? .black: .white
			return PKInkingTool(.marker,
								color: color,
								width: 20)
		}()
		
		var blurIntensity: CGFloat = 10
		
		// Out line
		static func defaultValues(for outlineFilter: MultiSliderFilterControl.OutlineFilter) -> [CGFloat] {
			switch outlineFilter {
				case .grayscale:
					return [0.1, 0.07, 0.25]
				case .color:
					return [0.3, 0.3]
			}
		}
		var selectedOutlineFilter: MultiSliderFilterControl.OutlineFilter = .grayscale
		var outlineControl: [CGFloat] = defaultValues(for: .grayscale)
		var outlineSketchColor: UIColor = .black
		var outlineBackgroundColor: UIColor = .white
		
		var bilateralControl: (radius: CGFloat, intensity: CGFloat) = (0.1, 0.1)
		
		var vignetteControl: (radius: CGFloat, intensity: CGFloat, edgeBrightness: CGFloat) = (0, 0, 0)
		
		// Text
		static let defaultText = "기본 텍스트"
		var textStampFont: (fontSize: CGFloat, descriptor: UIFontDescriptor) = (30, .init())
		var textStampControl: (opacity: CGFloat, rotation: CGFloat) = (1, 0)
		var textStampContent = Self.defaultText
		var textStampColor: UIColor = .black
		
		var painterRadius: CGFloat = 0
		
		var selectedLutName: String?
		
		// Glitter
		var thresholdBrightness: CGFloat = 1.0 
		var glitterAnglesAndRadius: [CGFloat: CGFloat] = [:]
		
		var depthFocus: CGFloat = 0 // Background tone
		
		// Distortion
		fileprivate(set) var viewFinderRatio: CGFloat? 
		var viewFinderRect: CGRect = .zero
		var rotation: Double = 0
		var perspectiveControl = [
			CGPoint(x: 0, y: 0),
			CGPoint(x: 1, y: 0),
			CGPoint(x: 0, y: 1),
			CGPoint(x: 1, y: 1)
		]
		
		
		fileprivate static let defaultValue = ControlValue()
		private init() { }
		
		var isBrightnessChanged: Bool {
			ciColorControl[.brightness] != Self.defaultValue.ciColorControl[.brightness] ||
			(colorChannelControl[.red] != Self.defaultValue.colorChannelControl[.red] &&
			 colorChannelControl[.blue] != Self.defaultValue.colorChannelControl[.blue] &&
			 colorChannelControl[.green] != Self.defaultValue.colorChannelControl[.green])
		}
		
		var isSaturationChanged: Bool {
			ciColorControl[.saturation] != Self.defaultValue.ciColorControl[.saturation] ||
			(!((colorChannelControl[.red] == colorChannelControl[.blue]) && (colorChannelControl[.red] == colorChannelControl[.green]))
			 &&
			(colorChannelControl[.red] != Self.defaultValue.colorChannelControl[.red] ||
			 colorChannelControl[.blue] != Self.defaultValue.colorChannelControl[.blue] ||
			 colorChannelControl[.green] != Self.defaultValue.colorChannelControl[.green]))
		}
		
		var isContrastChanged: Bool {
			ciColorControl[.contrast] != Self.defaultValue.ciColorControl[.contrast]
		}
		
		var isPainterChanged: Bool {
			painterRadius != Self.defaultValue.painterRadius
		}
		
		var isToneCopyChanged: Bool {
			depthFocus != Self.defaultValue.depthFocus
		}
		
		var isGlitterChanged: Bool {
			glitterAnglesAndRadius != Self.defaultValue.glitterAnglesAndRadius
		}
		
		var isBilateralChanged: Bool {
			bilateralControl != Self.defaultValue.bilateralControl
		}
		
		var isVignetteChanged: Bool {
			vignetteControl != Self.defaultValue.vignetteControl
		}
		
		var isOutlineChanged: Bool {
			outlineControl != Self.defaultValue.outlineControl
		}
		
		var isLutChanged: Bool {
			selectedLutName != nil
		}
	}
}
