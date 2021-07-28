//
//  ImageEditor.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import CoreImage
import SwiftUI
import PencilKit

class ImageEditor: NSObject, ObservableObject {
	
	private(set) var uiImage: UIImage?
	private let analyst: ImageAnalyst
	let historyManager: HistoryManager
	let editingState: EditingState
	var drawingMaskView: PKCanvasView
	var savingDelegate: EditorDelegation?
	private lazy var ciContext = CIContext(options: [.cacheIntermediates: false])
	
	func resetControls() {
		editingState.reset()
	}
	
	func setNewImage(_ image: UIImage) {
		ciContext.clearCaches()
		let ciImage = editingState.setNewImageData(image)
		historyManager.clearHistory(with: ciImage)
		setImageForDisplay()
		calcAverageLuminance()
		calcFaceRegions(for: image.imageOrientation.cgOrientation)
	}
	
	// MARK: - Set Tunable filter
	
	func setCIColorControl(with key: String){
		let filter = editingState.getFilter(CIFilter.self, name: "CIColorControls")
		let filterState = historyManager.createState(for: filter, specificKey: key)
		filter.setValue(editingState.control.colorControl[.brightness], forKey: kCIInputBrightnessKey)
		filter.setValue(editingState.control.colorControl[.contrast], forKey: kCIInputContrastKey)
		filter.setValue(editingState.control.colorControl[.saturation], forKey: kCIInputSaturationKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setSelectiveBrightness() {
		let filter = editingState.getFilter(SelectiveBrightness.self)
		let filterState = historyManager.createState(for: filter)
		editingState.control.selectiveControl.keys.forEach { rgb in
			filter.setBrightness(for: rgb, values: [
				.black : editingState.control.selectiveControl[rgb]![0],
				.shadow: editingState.control.selectiveControl[rgb]![1],
				.highlight: editingState.control.selectiveControl[rgb]![2],
				.white: editingState.control.selectiveControl[rgb]![3]
			],
			with: editingState.averageLuminace)
		}
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setBilateral() {
		let filter = editingState.getFilter(Bilateral.self)
		let filterState = historyManager.createState(for: filter)
		filter.setValue(editingState.control.bilateralControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.control.bilateralControl.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(editingState.imageExtent, forKey: kCIInputExtentKey)
		filter.setValue(editingState.faceRegions, forKey: Bilateral.faceRegionsKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setLutCube(_ lutName: String) {
		let filter = editingState.getFilter(LUTCube.self)
		let filterState = historyManager.createState(for: filter)
		filter.setValue(lutName, forKey: kCIInputMaskImageKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setOutline() {
		let outlineFilter = editingState.getFilter(SobelEdgeDetection3x3.self)
		let key = String(describing: SobelEdgeDetection3x3.self)
		let filterState = historyManager.createState(for: outlineFilter, specificKey: key)
		outlineFilter.setValue(editingState.control.outlineControl.bias, forKey: kCIInputBiasKey) 
		outlineFilter.setValue(editingState.control.outlineControl.weight, forKey: kCIInputWeightsKey)
		applyFilter(outlineFilter, with: filterState)
		setImageForDisplay()
	}
	
	func setVignette() {
		let filter = editingState.getFilter(Vignette.self)
		let filterState = historyManager.createState(for: filter)
		filter.setValue(editingState.control.vignetteControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.control.vignetteControl.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(editingState.control.vignetteControl.edgeBrightness, forKey: kCIInputBrightnessKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setGlitter() {
		let filter = editingState.getFilter(Glitter.self)
		let filterState = historyManager.createState(for: filter)
		let gilterControl: [CGFloat: CGFloat] = editingState.control.glitterAnglesAndRadius
		filter.setValue(editingState.control.thresholdBrightness, forKey: kCIInputBrightnessKey)
		filter.setValue(gilterControl, forKey: kCIInputAngleKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setPainter() {
		let filter = editingState.getMetalFilter(initClosure: KuwaharaMetal.init, ciContext: ciContext)
		let filterState = historyManager.createState(for: filter)
		filter.setValue(editingState.control.painterRadius, forKey: kCIInputRadiusKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	/// Apply all  filters and write history for given filter
	private func applyFilter(_ filter: CIFilter, with state: HistoryManager.FilterState){
		guard editingState.originalCgImage != nil else{
			return
		}
		
		var ciImage: CIImage? = historyManager.sourceImage
		editingState.applyingFilters.enumerated().forEach {
			let filter = $0.element.value
			filter.setValue(ciImage, forKey: kCIInputImageKey)
			ciImage = filter.outputImage
		}
		guard let finalImage = ciImage else {
			assertionFailure("Fail to apply \(filter)")
			return
		}
		historyManager.writeHistory(filter: filter, state: state, image: finalImage)
	}
	
	func applyMaskBlur() {
		let sourceImage = historyManager.lastImage
		guard let mask = CIImage(
			image: drawingMaskView.drawing.image(
				from: sourceImage.extent, scale: 1)
		) else {
			assertionFailure("Fail to create mask image")
			return
		}
		let filter = CIFilter(name: "CIMaskedVariableBlur")!
		filter.setValue(mask, forKey: "inputMask")
		filter.setValue(editingState.control.blurIntensity, forKey: kCIInputRadiusKey)
		filter.setValue(historyManager.lastImage, forKey: kCIInputImageKey)
		if let filteredImage = filter.outputImage?.cropped(to: sourceImage.extent) {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: filteredImage)
		}
		drawingMaskView.drawing.strokes = []
		setImageForDisplay()
	}
	
	func applyRefractedText() {
		let sourceImage = historyManager.lastImage
		let filter = RefractedText()
		let font = UIFont(descriptor: editingState.control.textStampFont.descriptor,
						  size: editingState.control.textStampFont.fontSize)
		filter.setValue(sourceImage, forKey: kCIInputImageKey)
		filter.setValue(editingState.control.textStampControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.control.textStampControl.lensScale, forKey: kCIInputScaleKey)
		filter.setValue(font, forKey: RefractedText.fontKey)
		filter.setValue(editingState.control.textStampContent, forKey: RefractedText.inputTextKey)
		filter.setValue(editingState.control.textStampAlignment, forKey: RefractedText.alignmentKey)
		if let filteredImage = filter.outputImage {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: filteredImage)
		}
		
		setImageForDisplay()
	}
	
	// MARK: - Save
	func saveImage() {
		guard uiImage != nil else {
			savingCompletion(UIImage(),
							 didFinishSavingWithError: ProcessError.savingError, contextInfo: nil)
			return
		}
		UIImageWriteToSavedPhotosAlbum(uiImage!, self,
									   #selector(savingCompletion(_:didFinishSavingWithError:contextInfo:)), nil)
	}
	
	
	@objc fileprivate func savingCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
		savingDelegate?.savingCompletion(error: error)
	}
	
	// MARK: - Analize image
	
	private func calcAverageLuminance() {
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			guard let strongSelf = self,
				  let cgImage = strongSelf.editingState.originalCgImage,
				  let luminace = strongSelf.analyst.calcAverageLuminace(from: cgImage) else { return }
			strongSelf.editingState.averageLuminace = luminace
		}
	}
	
	private func calcFaceRegions(for orientation: CGImagePropertyOrientation) {
		DispatchQueue.global(qos: .userInitiated).async {
			self.analyst.requestFaceDetection(self.editingState.originalCgImage!, orientation: orientation)
				.observe { [weak weakSelf = self] result in
					if case .success(let regions) = result {
						weakSelf?.editingState.faceRegions = regions
					}else if case .failure(let error) = result {
						print(error)
						weakSelf?.editingState.faceRegions = []
					}
				}
		}
	}
	
	// MARK: - Display
	
	private func setImageForDisplay() {
		DispatchQueue.global(qos:.userInteractive).sync { [self] in
			let ciImage = historyManager.lastImage
			if let cgImage = ciContext.createCGImage(ciImage, from: editingState.imageExtent!){
				uiImage = UIImage(cgImage: cgImage)
				publishOnMainThread()
			}
		}
	}
	
	private func publishOnMainThread() {
		if Thread.isMainThread {
			objectWillChange.send()
		}else {
			DispatchQueue.main.async {
				self.objectWillChange.send()
			}
		}
	}
	
	enum ProcessError: Error {
		case savingError
	}
	
	override init() {
		drawingMaskView = PKCanvasView()
		analyst = ImageAnalyst()
		historyManager = HistoryManager()
		editingState = EditingState()
		super.init()
		drawingMaskView.delegate = self
	}
	
	#if DEBUG
	static var forPreview: ImageEditor {
		let editor = ImageEditor()
		editor.setNewImage(UIImage(named: "selfie_dummy")!)
		return editor
	}
	#endif
}


// MARK: - History
extension ImageEditor {
	
	func undo() {
		let toLoad = historyManager.undo()
		loadState(filter: toLoad.filter, state: toLoad.beforeState)
		setImageForDisplay()
	}
	
	func redo() {
		let toLoad = historyManager.redo()
		loadState(filter: toLoad.filter, state: toLoad.afterState)
		
		setImageForDisplay()
	}
	
	/// Load previous setting for UI
	func loadState(filter: HistoryManager.FilterState.Filter, state: [String: Any]) {
		switch filter {
			case .Bilateral:
				guard let radius = state[kCIInputRadiusKey] as? CGFloat,
					  let intensity = state[kCIInputIntensityKey] as? CGFloat else {
					return
				}
				editingState.control.bilateralControl = (radius, intensity)
			case .SelectiveBrightness:
				guard let red = state["red"] as? SelectiveBrightness.selectableValues,
					  let blue = state["blue"] as? SelectiveBrightness.selectableValues,
					  let green = state["green"] as? SelectiveBrightness.selectableValues else {
					return
				}
				editingState.control.selectiveControl[.red] = red
				editingState.control.selectiveControl[.blue] = blue
				editingState.control.selectiveControl[.green] = green
			case .brightness, .saturation, .contrast:
				guard let brightness = state[kCIInputBrightnessKey] as? CGFloat,
					  let saturation = state[kCIInputSaturationKey] as? CGFloat,
					  let contrast = state[kCIInputContrastKey] as? CGFloat else {
					return
				}
				editingState.control.colorControl[.brightness] = brightness
				editingState.control.colorControl[.saturation] = saturation
				editingState.control.colorControl[.contrast] = contrast
			case .LUTCube:
				if let lutName = state[kCIInputMaskImageKey] as? String {
					editingState.control.selectedLUTName = lutName
				}else {
					editingState.control.selectedLUTName = nil
				}
			case .SobelEdgeDetection3x3:
				guard let bias = state[kCIInputBiasKey] as? CGFloat,
					  let weight = state[kCIInputWeightsKey] as? CGFloat else {
					return
				}
				
				editingState.applyingFilters[String(describing: SobelEdgeDetection3x3.self)]?.setValue(bias, forKey: kCIInputBiasKey)
				editingState.applyingFilters[String(describing: SobelEdgeDetection3x3.self)]?.setValue(weight, forKey: kCIInputWeightsKey)
				editingState.control.outlineControl = (max(bias, 0.1), max(weight, 0.1))
			case .Vignette:
				guard let edgeBrightness = state[kCIInputBrightnessKey] as? CGFloat,
					  let intensity = state[kCIInputIntensityKey] as? CGFloat,
					  let radius = state[kCIInputRadiusKey] as? CGFloat else {
					return
				}
				editingState.control.vignetteControl = (radius: radius, intensity: intensity, edgeBrightness: edgeBrightness)
			case .Glitter:
				guard let threshold = state[kCIInputBrightnessKey] as? CGFloat,
					  let anglesAndRadius = state[kCIInputAngleKey] as? [CGFloat: CGFloat] else {
					return
				}
				editingState.control.thresholdBrightness = threshold
				editingState.control.glitterAnglesAndRadius = anglesAndRadius
			case .Kuwahara, .KuwaharaMetal:
				guard let radius = state[kCIInputRadiusKey] as? CGFloat else {
					return
				}
				editingState.control.painterRadius = radius
			case .unManaged:
				break
			
		}
	}
}

extension ImageEditor: PKCanvasViewDelegate {
	func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
		guard !canvasView.drawing.strokes.isEmpty else {
			return
		}
		self.applyMaskBlur()
	}
}

protocol EditorDelegation {
	func savingCompletion(error: Error?) -> Void
}
