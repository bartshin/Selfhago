//
//  ImageEditor.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import CoreImage
import SwiftUI
import PencilKit
import AVFoundation
import Combine

class ImageEditor: NSObject, ObservableObject {
	
	private(set) var uiImage: UIImage?
	@Published private(set) var materialImage: UIImage?
	private let analyst: ImageAnalyst
	let historyManager: HistoryManager
	let editingState: EditingState
	var drawingMaskView: PKCanvasView
	var savingDelegate: SavingDelegation?
	var textImageProvider: TextImageProvider?
	private lazy var ciContext = CIContext(options: [.cacheIntermediates: false])
	
	func setNewImage(from data: Data) {
		guard let image = UIImage(data: data) else {
			return
		}
		editingState.reset()
		historyManager.clearHistory()
		uiImage = image
		publishOnMainThread()
		editingState.setNewImage(image)
		historyManager.setImage(editingState.ciImage)
		analyst.reset()
		analizeImage(from: data)
	}
	
	func captureImage() {
		editingState.setNewImage(uiImage!)
		historyManager.setImage(editingState.ciImage)
	}
	
	func clearAllFilter() {
		editingState.reset()
		historyManager.reset()
		setImageForDisplay()
	}
	
	func setMaterialImage(_ image: UIImage) {
		if Thread.isMainThread {
			materialImage = image
		}
		else {
			DispatchQueue.main.async {
				self.materialImage = image
			}
		}
	}
	
	func clearImage() {
		historyManager.clearHistory()
		uiImage = nil
	}
	
	func clearMaterialImage() {
		materialImage = nil
	}
	
	// MARK: - Set Tunable filter
	
	func setCIColorControl(with key: String){
		let filter = editingState.getFilter(CIFilter.self, name: "CIColorControls")
		let filterState = historyManager.createState(for: filter, specificKey: key)
		setValueForColorControl(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	private func setValueForColorControl(_ filter: CIFilter) {
		filter.setValue(editingState.control.colorControl[.brightness], forKey: kCIInputBrightnessKey)
		filter.setValue(editingState.control.colorControl[.contrast], forKey: kCIInputContrastKey)
		filter.setValue(editingState.control.colorControl[.saturation], forKey: kCIInputSaturationKey)
	}
	
	func setColorChannel() {
		let filter = editingState.getFilter(ColorChannel.self)
		let filterState = historyManager.createState(for: filter)
		setValueForFilter(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	private func setValueForFilter(_ filter: ColorChannel) {
		editingState.control.colorChannelControl.keys.forEach { rgb in
			filter.setValue(for: rgb, values: [
				.black : editingState.control.colorChannelControl[rgb]![0],
				.shadow: editingState.control.colorChannelControl[rgb]![1],
				.highlight: editingState.control.colorChannelControl[rgb]![2],
				.white: editingState.control.colorChannelControl[rgb]![3]
			],
			with: analyst.averageLuminace)
		}
	}
	
	func setBilateral() {
		let filter = editingState.getFilter(Bilateral.self)
		let filterState = historyManager.createState(for: filter)
		setValueForFilter(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	private func setValueForFilter(_ filter: Bilateral) {
		filter.setValue(editingState.control.bilateralControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.control.bilateralControl.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(editingState.ciImage.extent, forKey: kCIInputExtentKey)
		filter.setValue(analyst.faceRegions, forKey: Bilateral.faceRegionsKey)
	}
	
	func setLutCube(_ lutName: String) {
		let filter = editingState.getFilter(LUTCube.self)
		let filterState = historyManager.createState(for: filter)
		filter.setValue(lutName, forKey: kCIInputMaskImageKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setOutline() {
		let filter = editingState.getFilter(SobelEdgeDetection3x3.self)
		let filterState = historyManager.createState(for: filter)
		setValueForFilter(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	private func setValueForFilter(_ filter: SobelEdgeDetection3x3) {
		filter.setValue(editingState.control.outlineControl.bias, forKey: kCIInputBiasKey)
		filter.setValue(editingState.control.outlineControl.weight, forKey: kCIInputWeightsKey)
	}
	
	func setVignette() {
		let filter = editingState.getFilter(Vignette.self)
		let filterState = historyManager.createState(for: filter)
		setValueForFilter(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	private func setValueForFilter(_ filter: Vignette) {
		filter.setValue(editingState.control.vignetteControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.control.vignetteControl.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(editingState.control.vignetteControl.edgeBrightness, forKey: kCIInputBrightnessKey)
	}
	
	func setGlitter() {
		let filter = editingState.getFilter(Glitter.self)
		let filterState = historyManager.createState(for: filter)
		setValueForFilter(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	private func setValueForFilter(_ filter: Glitter) {
		let gilterControl: [CGFloat: CGFloat] = editingState.control.glitterAnglesAndRadius
		filter.setValue(editingState.control.thresholdBrightness, forKey: kCIInputBrightnessKey)
		filter.setValue(gilterControl, forKey: kCIInputAngleKey)
	}
	
	func setPainter() {
		let filter = editingState.getFilter(Kuwahara.self)
		let filterState = historyManager.createState(for: filter)
		setValueForFilter(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	private func setValueForFilter(_ filter: Kuwahara) {
		filter.setValue(editingState.control.painterRadius, forKey: kCIInputRadiusKey)
	}
	
	func setBackgroundToneRetouch() {
		let filter = editingState.getFilter(BackgroundToneRetouch.self)
		let filterState = historyManager.createState(for: filter)
		setValueForFilter(filter)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func createPresetThumnails() {
		let presetLuts = PresetFilter.allCases.reduce(into: []) { allLut, preset in
			allLut += preset.luts
		}
		guard let inputImage = CIImage(image: DesignConstant.presetFilterImage) else {
			assertionFailure("Input image is not available")
			return
		}
		DispatchQueue.global(qos: .userInitiated).async { [self] in
			let filter = LUTCube()
			filter.setValue(inputImage, forKey: kCIInputImageKey)
			presetLuts.forEach { lutName in
				filter.setValue(lutName, forKey: kCIInputMaskImageKey)
				if let outputImage = filter.outputImage,
				   let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent){
					editingState.presetThumnails[lutName] = UIImage(cgImage: cgImage)
				}
			}
			Glitter.createPresetImages().forEach { ciImage in
				if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
					editingState.glitterPresetImages.append(UIImage(cgImage: cgImage))
				}
			}
		}
	}
	
	func createGlitterPreview(for angleAndRadius: [CGFloat: CGFloat], in size: CGSize) -> UIImage {
		let ciImage = Glitter.createPresetImage(for: angleAndRadius, in: size)
		if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
			return UIImage(cgImage: cgImage)
		}else {
			return UIImage()
		}
	}
	
	private func setValueForFilter(_ filter: BackgroundToneRetouch) {
		guard let materialImage = materialImage?.cgImage,
			  let depthMask = analyst.createDepthMask(over: editingState.control.depthFocus) else {
			return
		}
		let targetImage = CIImage(cgImage: materialImage)
		filter.ciContext = ciContext
		filter.setValue(targetImage, forKey: kCIInputBackgroundImageKey)
		filter.setValue(depthMask, forKey: kCIInputMaskImageKey)
		filter.setValue(editingState.control.depthFocus, forKey: kCIInputIntensityKey)
	}
	
	/// Apply all  filters and write history for given filter
	private func applyFilter(_ filter: CIFilter, with state: HistoryManager.FilterState){
		guard editingState.originalCgImage != nil, !editingState.isRecording else{
			return
		}
		let trigger = Date().timeIntervalSinceReferenceDate
		editingState.lastFilterTrigger = trigger
		if editingState.currentExcutingFilterTrigger == nil {
			editingState.currentExcutingFilterTrigger = trigger
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
		drawingMaskView.drawing.strokes.removeAll()
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
	
	func applyTextStamp() {
		guard let textImage = textImageProvider?.provideTextImage(),
			  let ciImage = CIImage(image: textImage) else {
			assertionFailure("Fail to get text image")
			return
		}
		let scaleTransform = CGAffineTransform(scaleX: 1/textImage.scale, y: 1/textImage.scale)
		let scaleCorrectedImage = ciImage.transformed(by: scaleTransform)

		let filter = CIFilter(name: "CISourceAtopCompositing")!
		filter.setValue(scaleCorrectedImage, forKey: kCIInputImageKey)
		filter.setValue(historyManager.lastImage, forKey: kCIInputBackgroundImageKey)
		if let filteredImage = filter.outputImage {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: filteredImage)
		}else {
			print("Oooops no output")
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
	
	private func analizeImage(from data: Data) {
		DispatchQueue.global(qos: .utility).async { [self] in
			guard let cgImage = editingState.originalCgImage,
				  let orientation = editingState.imageOrientaion else {
				return
			}
			analyst.calcAverageLuminace(from: cgImage)
			analyst.calcFaceRegions(editingState.originalCgImage!, orientation: orientation)
			analyst.createImageSource(from: data)
			analyst.createDepthImage()
			publishDepthDataAvailAble()
		}
	}
	
	private func publishDepthDataAvailAble() {
		DispatchQueue.main.async { [self] in
			editingState.depthDataAvailable = analyst.depthImage != nil
		}
	}
	
	
	// MARK: - Display
	
	private func setImageForDisplay() {
		if editingState.isRecording ||
			(editingState.currentExcutingFilterTrigger != nil &&
		   editingState.currentExcutingFilterTrigger! < editingState.lastFilterTrigger!){
			return
		}
		DispatchQueue.global(qos: .userInteractive).async { [self] in
			let ciImage = historyManager.lastImage
			if let cgImage = ciContext.createCGImage(ciImage, from: editingState.ciImage.extent){
				self.uiImage = UIImage(cgImage: cgImage)
				self.publishOnMainThread()
			}
			editingState.currentExcutingFilterTrigger = nil
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
		let state = EditingState()
		editingState = state
		super.init()
		createPresetThumnails()
	}
	
	#if DEBUG
	static var forPreview: ImageEditor {
		let editor = ImageEditor()
		let image = UIImage(named: "selfie_dummy")!
		editor.uiImage = image
		editor.editingState.setNewImage(image)
		editor.historyManager.setImage(editor.editingState.ciImage)
		editor.setImageForDisplay()
		return editor
	}
	#endif
}


// MARK: - History
extension ImageEditor {
	
	func undo() {
		guard historyManager.undoAble else {
			return
		}
		let toLoad = historyManager.undo()
		loadState(filter: toLoad.filter, state: toLoad.beforeState)
		setImageForDisplay()
	}
	
	func redo() {
		guard historyManager.redoAble else {
			return
		}
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
				setValueForFilter(editingState.getFilter(Bilateral.self))
			case .ColorChannel:
				guard let redValues = state["red"] as? ColorChannel.valueForRanges,
					  let blueValues = state["blue"] as? ColorChannel.valueForRanges,
					  let greenValues = state["green"] as? ColorChannel.valueForRanges else {
					return
				}
				editingState.control.colorChannelControl[.red] = redValues
				editingState.control.colorChannelControl[.blue] = blueValues
				editingState.control.colorChannelControl[.green] = greenValues
				setValueForFilter(editingState.getFilter(ColorChannel.self))
			case .brightness, .saturation, .contrast:
				guard let brightness = state[kCIInputBrightnessKey] as? CGFloat,
					  let saturation = state[kCIInputSaturationKey] as? CGFloat,
					  let contrast = state[kCIInputContrastKey] as? CGFloat else {
					return
				}
				editingState.control.colorControl[.brightness] = brightness
				editingState.control.colorControl[.saturation] = saturation
				editingState.control.colorControl[.contrast] = contrast
				setValueForColorControl(editingState.getFilter(CIFilter.self, name: "CIColorControls"))
			case .LUTCube:
				if let lutName = state[kCIInputMaskImageKey] as? String {
					editingState.control.selectedLUTName = lutName
					let filter = editingState.getFilter(LUTCube.self)
					filter.setValue(lutName, forKey: kCIInputMaskImageKey)
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
				setValueForFilter(editingState.getFilter(SobelEdgeDetection3x3.self))
			case .Vignette:
				guard let edgeBrightness = state[kCIInputBrightnessKey] as? CGFloat,
					  let intensity = state[kCIInputIntensityKey] as? CGFloat,
					  let radius = state[kCIInputRadiusKey] as? CGFloat else {
					return
				}
				editingState.control.vignetteControl = (radius: radius, intensity: intensity, edgeBrightness: edgeBrightness)
				setValueForFilter(editingState.getFilter(Vignette.self))
			case .Glitter:
				guard let threshold = state[kCIInputBrightnessKey] as? CGFloat,
					  let anglesAndRadius = state[kCIInputAngleKey] as? [CGFloat: CGFloat] else {
					return
				}
				editingState.control.thresholdBrightness = threshold
				editingState.control.glitterAnglesAndRadius = anglesAndRadius
				setValueForFilter(editingState.getFilter(Glitter.self))
			case .Kuwahara, .KuwaharaMetal:
				guard let radius = state[kCIInputRadiusKey] as? CGFloat else {
					return
				}
				editingState.control.painterRadius = radius
				setValueForFilter(editingState.getFilter(Kuwahara.self))
			case .BackgroundToneRetouch:
				guard let focus = state[kCIInputIntensityKey] as? CGFloat else {
					return
				}
				editingState.control.depthFocus = focus
				setValueForFilter(editingState.getFilter(BackgroundToneRetouch.self))
			case .unManaged:
				setImageForDisplay()
				break
			
		}
	}
}

extension ImageEditor: AVCaptureVideoDataOutputSampleBufferDelegate {
	
	func applyFilterToVideo(input: CIImage) -> CIImage? {
		var ciImage: CIImage? = input
		editingState.applyingFilters.enumerated().forEach {
			let filter = $0.element.value
			filter.setValue(ciImage, forKey: kCIInputImageKey)
			ciImage = filter.outputImage
		}
		return ciImage
	}
	
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		connection.videoOrientation = .portrait
		guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return
		}
		guard let filteredImage = applyFilterToVideo(input: CIImage(cvImageBuffer: buffer)),
			let cgImage = ciContext.createCGImage(filteredImage, from: filteredImage.extent) else {
			assertionFailure("Fail to create cg image from video output")
			return
		}
		
		let previousSize = uiImage?.size
		uiImage = UIImage(cgImage: cgImage)
		if previousSize != uiImage?.size {
			DispatchQueue.main.async {
				self.editingState.isRecording = true
			}
		}
		else {
			publishOnMainThread()
		}
	}
}

protocol SavingDelegation {
	func savingCompletion(error: Error?) -> Void
}

protocol TextImageProvider {
	func provideTextImage() -> UIImage
}
