//
//  ImageEditor.swift
//  Selfhago
//
//  Created by bart Shin on 21/06/2021.
//

import CoreImage
import SwiftUI
import AVFoundation
import Combine

class ImageEditor: NSObject, ObservableObject {
	
	private(set) var uiImage: UIImage?
	@Published private(set) var materialImage: UIImage?
	private let analyst: ImageAnalyst
	let historyManager: HistoryManager
	let editingState: EditingState
	var savingDelegate: SavingDelegation?
	var textImageProvider: TextImageProvider?
	private lazy var ciContext = CIContext(options: [.cacheIntermediates: false])
	var previousImage: UIImage? {
		if let ciImage = historyManager.previousImage,
		   let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent){
			return UIImage(cgImage: cgImage)
		}else {
			return nil
		}
	}
	
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
	
	func storeCurrentState() {
		guard var state = historyManager.detachCurrentState(),
			  let lastFilter = historyManager.lastFilter else {
				  return
			  }
		state.afterState = state.captureState(from: lastFilter)
		if let editingImage = editingState.detachEditingImage() {
			historyManager.writeHistory(filter: lastFilter, state: state, image: editingImage)
		}
	}
	
	// MARK: - Set Distortion Filter
	
	func applyCrop() {
		let filter = CIFilter(name: "CICrop")!
		filter.setValue(historyManager.currentImage, forKey: kCIInputImageKey)
		let cropRect = editingState.control.viewFinderRect
		let originalRect = historyManager.currentImage.extent
		filter.setValue(CIVector(x: originalRect.minX + cropRect.minX, y: originalRect.minY + originalRect.height - cropRect.maxY,
								 z: cropRect.width, w: cropRect.height), forKey: "inputRectangle")
		if let output = filter.outputImage {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: output)
			editingState.setViewFinderRatio(nil)
			setImageForDisplay()
			editingState.setImageSize(uiImage!.size)
			editingState.resetViewFinder()
		}
	}
	
	func applyRotation() {
		let filter = CIFilter(name: "CIAffineTransform")!
		let angle = -editingState.control.rotation * .pi / 180
		let transform = CGAffineTransform(rotationAngle: angle)
		filter.setValue(historyManager.currentImage, forKey: kCIInputImageKey)
		filter.setValue(transform, forKey: kCIInputTransformKey)
		if let output = filter.outputImage {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: output)
			editingState.control.rotation = 0
			setImageForDisplay()
			editingState.setImageSize(uiImage!.size)
			editingState.resetViewFinder()
		}
	}
	
	func applyFlip(horizontal: Bool) {
		let filter = CIFilter(name: "CIAffineTransform")!
		let transform: CGAffineTransform = horizontal ? .init(scaleX: -1, y: 1): .init(scaleX: 1, y: -1)
		filter.setValue(historyManager.currentImage, forKey: kCIInputImageKey)
		filter.setValue(transform, forKey: kCIInputTransformKey)
		if let output = filter.outputImage{
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: output)
			editingState.imageFlipped = (horizontal: horizontal, vertical: !horizontal)
			DispatchQueue.global(qos: .userInitiated).async { [self] in
				if let cgImage = ciContext.createCGImage(output, from: output.extent) {
					uiImage = UIImage(cgImage: cgImage)
					Thread.sleep(forTimeInterval: 0.5) // Sync with animation
					publishOnMainThread()
				}
			}
		}
	}
	
	// MARK: - Set modifiable filter
	
	func setCIColorControl(with key: String){
		let colorControlFilter = editingState.getFilter(CIFilter.self, name: "CIColorControls")
		let colorChannelFilter = editingState.getFilter(ColorChannel.self)
		processFilter(colorControlFilter, with: key, associatedFilters: [colorChannelFilter])
	}
	
	private func setValueForColorControl(_ filter: CIFilter) {
		filter.setValue(editingState.control.ciColorControl[.brightness], forKey: kCIInputBrightnessKey)
		filter.setValue(editingState.control.ciColorControl[.contrast], forKey: kCIInputContrastKey)
		filter.setValue(editingState.control.ciColorControl[.saturation], forKey: kCIInputSaturationKey)
	}
	
	func setGamma() -> [Double] {
		let filter = editingState.getFilter(GammaAdjustment.self)
		processFilter(filter)
		return filter.valuesForCharts
	}
	
	private func setValueForFilter(_ filter: GammaAdjustment) {
		filter.setValue(editingState.control.gammaParameter,
						forKey: kCIInputIntensityKey)
	}
	
	func setColorChannel() {
		let colorChannelFilter = editingState.getFilter(ColorChannel.self)
		let colorControlFilter = editingState.getFilter(CIFilter.self, name: "CIColorControls")
		processFilter(colorChannelFilter, associatedFilters: [colorControlFilter])
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
		processFilter(filter)
	}
	
	private func setValueForFilter(_ filter: Bilateral) {
		filter.setValue(editingState.control.bilateralControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.control.bilateralControl.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(historyManager.currentImage.extent, forKey: kCIInputExtentKey)
		filter.setValue(analyst.faceRegions, forKey: Bilateral.faceRegionsKey)
	}
	
	func setLutCube() {
		let filter = editingState.getFilter(LUTCube.self)
		processFilter(filter)
	}
	
	func setOutline() {
		let filter: CIFilter
		switch editingState.control.selectedOutlineFilter {
			case .grayscale:
				filter = editingState.getFilter(Sketch.self)
				editingState.removeFilter(SobelEdgeDetection3x3.self)
			case .color:
				filter = editingState.getFilter(SobelEdgeDetection3x3.self)
				editingState.removeFilter(Sketch.self)
		}
		
		processFilter(filter)
	}
	
	private func setValueForFilter(_ filter: Sketch) {
		let backgroundImage = CIImage(color: CIColor(color: editingState.control.outlineBackgroundColor)).cropped(to: CGRect(origin: .zero, size: editingState.imageSize!))
		filter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
		filter.setValue(editingState.control.outlineSketchColor, forKey: kCIInputColorKey)
		filter.setValue(editingState.control.outlineControl[0], forKey: "inputThreshold")
		filter.setValue(editingState.control.outlineControl[1], forKey: "inputNRNoiseLevel")
		filter.setValue(editingState.control.outlineControl[2], forKey: "inputEdgeIntensity")
	}
	
	private func setValueForFilter(_ filter: SobelEdgeDetection3x3) {
		filter.setValue(editingState.control.outlineControl[0], forKey: kCIInputBiasKey)
		filter.setValue(editingState.control.outlineControl[1], forKey: kCIInputWeightsKey)
	}
	
	func setVignette() {
		let filter = editingState.getFilter(Vignette.self)
		processFilter(filter)
	}
	
	private func setValueForFilter(_ filter: Vignette) {
		filter.setValue(editingState.control.vignetteControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.control.vignetteControl.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(editingState.control.vignetteControl.edgeBrightness, forKey: kCIInputBrightnessKey)
	}
	
	func setGlitter() {
		let filter = editingState.getFilter(Glitter.self)
		processFilter(filter)
	}
	
	private func setValueForFilter(_ filter: Glitter) {
		filter.setValue(editingState.control.thresholdBrightness, forKey: kCIInputBrightnessKey)
		filter.setValue(editingState.control.glitterAnglesAndRadius, forKey: kCIInputAngleKey)
	}
	
	func setPainter() {
		let filter = editingState.getFilter(Kuwahara.self)
		processFilter(filter)
	}
	
	private func setValueForFilter(_ filter: Kuwahara) {
		filter.setValue(editingState.control.painterRadius, forKey: kCIInputRadiusKey)
	}
	
	func setBackgroundToneRetouch() {
		let filter = editingState.getFilter(BackgroundToneRetouch.self)
		processFilter(filter)
	}
	
	func setPerspective() {
		let filter = editingState.getFilter(CIFilter.self, name: "CIPerspectiveTransform")
		processFilter(filter, with: "perspective")
		editingState.setImageSize(uiImage!.size)
		editingState.resetViewFinder()
	}
	
	func setValueForPerspective(_ filter: CIFilter) {
		let size = historyManager.sourceImage.extent.size
		let topLeft = editingState.control.perspectiveControl[0]
		let topRight = editingState.control.perspectiveControl[1]
		let bottomLeft = editingState.control.perspectiveControl[2]
		let bottomRight = editingState.control.perspectiveControl[3]
		filter.setValue(CIVector(x: topLeft.x * size.width, y: (1 - topLeft.y) * size.height), forKey: "inputTopLeft")
		filter.setValue(CIVector(x: topRight.x * size.width, y: (1 - topRight.y) * size.height), forKey: "inputTopRight")
		filter.setValue(CIVector(x: bottomLeft.x * size.width, y: (1 - bottomLeft.y) * size.height), forKey: "inputBottomLeft")
		filter.setValue(CIVector(x: bottomRight.x * size.width, y: (1 - bottomRight.y) * size.height), forKey: "inputBottomRight")
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
		
		filter.ciContext = ciContext
		filter.setValue(materialImage, forKey: kCIInputBackgroundImageKey)
		filter.setValue(depthMask, forKey: kCIInputMaskImageKey)
		filter.setValue(editingState.control.depthFocus, forKey: kCIInputIntensityKey)
	}
	
	private func processFilter<T>(_ filter: T, with key: String? = nil, associatedFilters: [CIFilter] = []) where T: CIFilter {
		guard !editingState.isRecording else {
			setValueForFilter(filter)
			return
		}
		markTrigger()
		setValueForFilter(filter)
		if !historyManager.isCurrentEditingFilter(filter) {
			historyManager.changeCurrentState(for: filter, specificKey: key)
			historyManager.imageWithoutCurrentFilter = iterateFilters(except: [filter] + associatedFilters)
		}
		if filter is VImageFilter {
			applyVImageFilter(filter as! VImageFilter)
		}else {
			applyFilters([filter] + associatedFilters)
			setImageForDisplay()
		}
	}
	
	private func setValueForFilter<T>(_ filter: T) where T: CIFilter {
		if filter.name == "CIColorControls"{
			setValueForColorControl(filter)
		}
		else if filter.name == "CIPerspectiveTransform" {
			setValueForPerspective(filter)
		}
		else if filter is ColorChannel {
			setValueForFilter(filter as! ColorChannel)
		}
		else if filter is Bilateral {
			setValueForFilter(filter as! Bilateral)
		}
		else if filter is LUTCube {
			filter.setValue(editingState.control.selectedLutName!, forKey: kCIInputMaskImageKey)
		}
		else if filter is SobelEdgeDetection3x3 {
			setValueForFilter(filter as! SobelEdgeDetection3x3)
		}
		else if filter is Sketch {
			setValueForFilter(filter as! Sketch)
		}
		else if filter is Vignette {
			setValueForFilter(filter as! Vignette)
		}
		else if filter is Glitter {
			setValueForFilter(filter as! Glitter)
		}
		else if filter is Kuwahara {
			setValueForFilter(filter as! Kuwahara)
		}
		else if filter is BackgroundToneRetouch {
			setValueForFilter(filter as! BackgroundToneRetouch)
		}
		else if filter is GammaAdjustment {
			setValueForFilter(filter as! GammaAdjustment)
		}
		else {
			assertionFailure("Fail to set value for \(filter)")
		}
	}
	
	/// Apply all  filters and write history for given filter
	private func iterateFilters(except filters: [CIFilter]) -> CIImage{
		guard editingState.originalCgImage != nil else{
			return historyManager.currentImage
		}
		var ciImage: CIImage? = historyManager.sourceImage
		editingState.applyingCIFilters.forEach {
			guard !filters.contains($0.value) else {
				return
			}
			let filter = $0.value
			filter.setValue(ciImage, forKey: kCIInputImageKey)
			ciImage = filter.outputImage
		}
	
		guard let finalImage = ciImage else {
			assertionFailure("Fail to iterate except \(filters)")
			return historyManager.currentImage
		}
		if !editingState.applyingVImageFilters.isEmpty {
			var cgImage = ciContext.createCGImage(finalImage, from: finalImage.extent)
			editingState.applyingVImageFilters.forEach {
				guard !filters.contains($0.value) else {
					return
				}
				let filter = $0.value
				filter.setValue(cgImage, forKey: kCIInputImageKey)
				cgImage = filter.outputCGImage
			}
			guard cgImage != nil else {
				fatalError("Output cg image is nil")
			}
			return CIImage(cgImage: cgImage!)
		}
		return finalImage
	}
	
	private func applyFilters(_ filters: [CIFilter]) {
		var ciImage = historyManager.imageWithoutCurrentFilter
		filters.forEach { filter in
			filter.setValue(ciImage, forKey: kCIInputImageKey)
			ciImage = filter.outputImage
		}
		
		if ciImage != nil {
			editingState.changeCurrentEditingImage(ciImage)
		}else {
			assertionFailure("No output image from \(filters)")
		}
	}
	
	private func applyVImageFilter(_ filter: VImageFilter) {
		if editingState.isRecording || isContinuouCall(){
			return
		}
		DispatchQueue.global(qos: .userInitiated).async { [self] in
			guard let ciImage = historyManager.imageWithoutCurrentFilter,
				  let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
					  fatalError("Fail to create input cg image")
				  }
			filter.setValue(cgImage, forKey: kCIInputImageKey)
			guard let cgImage = filter.outputCGImage else {
				fatalError("Fail to get output cg image")
			}
			uiImage = UIImage(cgImage: cgImage)
			publishOnMainThread()
			editingState.currentExcutingFilterTrigger = nil
		}
		
	}
	
	private func markTrigger() {
		let trigger = Date().timeIntervalSinceReferenceDate
		editingState.lastFilterTrigger = trigger
		if editingState.currentExcutingFilterTrigger == nil {
			editingState.currentExcutingFilterTrigger = trigger
		}
	}
	
	func applyMaskBlur() {
		let sourceImage = historyManager.currentImage
		guard let mask = CIImage(
			image: editingState.drawingMaskView.drawing.image(
				from: sourceImage.extent, scale: 1)
		) else {
			assertionFailure("Fail to create mask image")
			return
		}
		let filter = CIFilter(name: "CIMaskedVariableBlur")!
		filter.setValue(mask, forKey: "inputMask")
		filter.setValue(editingState.control.blurIntensity, forKey: kCIInputRadiusKey)
		filter.setValue(historyManager.currentImage, forKey: kCIInputImageKey)
		if let filteredImage = filter.outputImage?.cropped(to: sourceImage.extent) {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: filteredImage)
		}
		setImageForDisplay()
	}
	
	func addDrawing() {
		let sourceImage = historyManager.currentImage
		var canvasImage: UIImage?
		UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
			canvasImage = editingState.drawingMaskView.drawing.image(
				from: CGRect(origin: .zero, size: editingState.imageSize!), scale: 1)
		}
		guard canvasImage != nil,
			let drawing = CIImage(
			image: canvasImage!) else {
					assertionFailure("Fail to get drawing image")
					return
				}
		let filter = CIFilter(name: "CISourceAtopCompositing")!
		filter.setValue(drawing, forKey: kCIInputImageKey)
		filter.setValue(sourceImage, forKey: kCIInputBackgroundImageKey)
		if let filteredImage = filter.outputImage {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: filteredImage)
		}
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
		filter.setValue(historyManager.currentImage, forKey: kCIInputBackgroundImageKey)
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
		if editingState.isRecording || isContinuouCall(){
			return
		}
		DispatchQueue.global(qos: .userInitiated).async { [self] in
			let ciImage = editingState.currentEditingImage ?? historyManager.currentImage
			if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent){
				self.uiImage = UIImage(cgImage: cgImage)
			}
			publishOnMainThread()
			editingState.currentExcutingFilterTrigger = nil
		}
	}
	
	private func isContinuouCall() -> Bool {
		editingState.currentExcutingFilterTrigger != nil &&
		editingState.currentExcutingFilterTrigger! < editingState.lastFilterTrigger!
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
		analyst = ImageAnalyst()
		historyManager = HistoryManager()
		editingState = EditingState()
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
				editingState.control.ciColorControl[.brightness] = brightness
				editingState.control.ciColorControl[.saturation] = saturation
				editingState.control.ciColorControl[.contrast] = contrast
				setValueForColorControl(editingState.getFilter(CIFilter.self, name: "CIColorControls"))
			case .LUTCube:
				if let lutName = state[kCIInputMaskImageKey] as? String {
					editingState.control.selectedLutName = lutName
					let filter = editingState.getFilter(LUTCube.self)
					filter.setValue(lutName, forKey: kCIInputMaskImageKey)
				}else {
					editingState.control.selectedLutName = nil
				}
			case .SobelEdgeDetection3x3:
				guard let bias = state[kCIInputBiasKey] as? CGFloat,
					  let weight = state[kCIInputWeightsKey] as? CGFloat else {
					return
				}
				
				editingState.applyingCIFilters[String(describing: SobelEdgeDetection3x3.self)]?.setValue(bias, forKey: kCIInputBiasKey)
				editingState.applyingCIFilters[String(describing: SobelEdgeDetection3x3.self)]?.setValue(weight, forKey: kCIInputWeightsKey)
				editingState.control.outlineControl = [max(bias, 0.1), max(weight, 0.1)]
				setValueForFilter(editingState.getFilter(SobelEdgeDetection3x3.self))
			case .Sketch:
				let keys = [Sketch.thresholdKey, Sketch.noiseLevelKey, Sketch.edgeIntensityKey,
								   kCIInputColorKey, kCIInputBackgroundImageKey]
				keys.forEach {
					print($0, state[$0] ?? "nil")
				}
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
			case .perspective:
				guard let topLeft = state["inputTopLeft"],
					  let topRight = state["inputTopRight"],
					  let bottomLeft = state["inputBottomLeft"],
					  let bottomRight = state["inputBottomRight"] else {
						  return
					  }
				print(topLeft, topRight, bottomLeft, bottomRight)
			case .GammaAdjustment:
				guard let parameter = state[kCIInputIntensityKey] as? GammaAdjustment.Parameter else{
					assertionFailure("Fail to get parameter")
					return
				}
				print("Gamma adjustment parameter: \(parameter)")
			case .unManaged:
				setImageForDisplay()
				break
		}
	}
}

extension ImageEditor: AVCaptureVideoDataOutputSampleBufferDelegate {
	
	func applyFilterToVideo(input: CIImage) -> CIImage? {
		var ciImage: CIImage? = input
		editingState.setImageSize(input.extent.size)
		editingState.applyingCIFilters.enumerated().forEach {
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
