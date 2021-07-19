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
	
	static var forPreview: ImageEditor {
		let editor = ImageEditor()
		editor.setNewImage(UIImage(named: "selfie_dummy")!)
		return editor
	}
	private(set) var uiImage: UIImage?
	private let analyst: ImageAnalyst
	let historyManager: HistoryManager
	let editingState: EditingState
	var blurMask: PKCanvasView
	var delegate: EditorDelegation?
	private lazy var ciContext = CIContext(options: [.cacheIntermediates: false])
	
	func resetControls() {
		editingState.resetControls()
	}
	
	func setNewImage(_ image: UIImage) {
		ciContext.clearCaches()
		let ciImage = editingState.setNewImageData(image)
		historyManager.clearHistory(with: ciImage)
		setImageForDisplay()
		setAverageLuminance()
		setFaceRegions(for: image.imageOrientation.cgOrientation)
	}
	
	// MARK: - Set Tunable filter
	
	func setCIColorControl(with key: String){
		let filter = editingState.getFilter(CIFilter.self, name: "CIColorControls")
		let filterState = historyManager.createState(for: filter, specificKey: key)
		filter.setValue(editingState.colorControl[.brightness], forKey: kCIInputBrightnessKey)
		filter.setValue(editingState.colorControl[.contrast], forKey: kCIInputContrastKey)
		filter.setValue(editingState.colorControl[.saturation], forKey: kCIInputSaturationKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setSelectiveBrightness() {
		let filter = editingState.getFilter(SelectiveBrightness.self)
		let filterState = historyManager.createState(for: filter)
		editingState.selectiveControl.keys.forEach { rgb in
			filter.setBrightness(for: rgb, values: [
				.black : editingState.selectiveControl[rgb]![0],
				.shadow: editingState.selectiveControl[rgb]![1],
				.highlight: editingState.selectiveControl[rgb]![2],
				.white: editingState.selectiveControl[rgb]![3]
			],
			with: editingState.averageLuminace)
		}
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	func setBilateral() {
		let filter = editingState.getFilter(Bilateral.self)
		let filterState = historyManager.createState(for: filter)
		filter.setValue(editingState.bilateralControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.bilateralControl.intensity, forKey: kCIInputIntensityKey)
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
		editingState.filters[key] = outlineFilter
		outlineFilter.setValue(editingState.outlineControl.bias, forKey: kCIInputBiasKey)
		outlineFilter.setValue(editingState.outlineControl.weight, forKey: kCIInputWeightsKey)
		applyFilter(outlineFilter, with: filterState)
		setImageForDisplay()
	}
	
	func setVignette() {
		let filter = editingState.getFilter(Vignette.self)
		let filterState = historyManager.createState(for: filter)
		filter.setValue(editingState.vignetteControl.radius, forKey: kCIInputRadiusKey)
		filter.setValue(editingState.vignetteControl.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(editingState.vignetteControl.edgeBrightness, forKey: kCIInputBrightnessKey)
		applyFilter(filter, with: filterState)
		setImageForDisplay()
	}
	
	/// Apply all  filters and write history for given filter
	private func applyFilter(_ filter: CIFilter, with state: HistoryManager.FilterState){
		guard editingState.originalCgImage != nil else{
			return
		}
		
		var ciImage: CIImage? = historyManager.sourceImage
		editingState.filters.enumerated().forEach {
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
	
	func setMaskBlur() {
		let sourceImage = historyManager.lastImage
		guard let mask = CIImage(
			image: blurMask.drawing.image(
				from: sourceImage.extent, scale: 1)
		) else {
			assertionFailure("Fail to create mask image")
			return
		}
		let filter = CIFilter(name: "CIMaskedVariableBlur")!
		filter.setValue(mask, forKey: "inputMask")
		filter.setValue(editingState.blurIntensity, forKey: kCIInputRadiusKey)
		filter.setValue(historyManager.lastImage, forKey: kCIInputImageKey)
		if let filteredImage = filter.outputImage?.cropped(to: sourceImage.extent) {
			historyManager.writeHistory(filter: filter, state: .unManagedFilter, image: filteredImage)
		}
		blurMask.drawing.strokes = []
		setImageForDisplay()
	}
	
	// MARK: - Save
	func saveImage() {
		guard uiImage != nil else {
			savingCompletion(UIImage(),
							 didFinishSavingWithError: ProcessError.convertingError, contextInfo: nil)
			return
		}
		UIImageWriteToSavedPhotosAlbum(uiImage!, self,
									   #selector(savingCompletion(_:didFinishSavingWithError:contextInfo:)), nil)
	}
	
	
	@objc fileprivate func savingCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
		delegate?.savingCompletion(error: error)
	}
	
	// MARK: - Analize image
	
	private func setAverageLuminance() {
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			guard let strongSelf = self,
				  let cgImage = strongSelf.editingState.originalCgImage,
				  let luminace = strongSelf.analyst.calcAverageLuminace(from: cgImage) else { return }
			strongSelf.editingState.averageLuminace = luminace
		}
	}
	
	private func setFaceRegions(for orientation: CGImagePropertyOrientation) {
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
		case convertingError
	}
	
	override init() {
		blurMask = PKCanvasView()
		analyst = ImageAnalyst()
		historyManager = HistoryManager()
		editingState = EditingState()
		super.init()
		blurMask.delegate = self
	}
	
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
	
	func loadState(filter: HistoryManager.FilterState.Filter, state: [String: Any]) {
		switch filter {
			case .Bilateral:
				guard let radius = state[kCIInputRadiusKey] as? CGFloat,
					  let intensity = state[kCIInputIntensityKey] as? CGFloat else {
					return
				}
				editingState.bilateralControl = (radius, intensity)
			case .SelectiveBrightness:
				guard let red = state["red"] as? SelectiveBrightness.selectableValues,
					  let blue = state["blue"] as? SelectiveBrightness.selectableValues,
					  let green = state["green"] as? SelectiveBrightness.selectableValues else {
					return
				}
				editingState.selectiveControl[.red] = red
				editingState.selectiveControl[.blue] = blue
				editingState.selectiveControl[.green] = green
			case .brightness, .saturation, .contrast:
				guard let brightness = state[kCIInputBrightnessKey] as? Double,
					  let saturation = state[kCIInputSaturationKey] as? Double,
					  let contrast = state[kCIInputContrastKey] as? Double else {
					return
				}
				editingState.colorControl[.brightness] = brightness
				editingState.colorControl[.saturation] = saturation
				editingState.colorControl[.contrast] = contrast
			case .LUTCube:
				guard let lutName = state[kCIInputMaskImageKey] as? String else {
					return
				}
				print("lut \(lutName)")
			case .SobelEdgeDetection3x3:
				guard let bias = state[kCIInputBiasKey] as? CGFloat,
					  let weight = state[kCIInputWeightsKey] as? CGFloat else {
					return
				}
				
				editingState.filters[String(describing: SobelEdgeDetection3x3.self)]?.setValue(bias, forKey: kCIInputBiasKey)
				editingState.filters[String(describing: SobelEdgeDetection3x3.self)]?.setValue(weight, forKey: kCIInputWeightsKey)
				editingState.outlineControl = (max(bias, 0.1), max(weight, 0.1))
			case .Vignette:
				guard let edgeBrightness = state[kCIInputBrightnessKey] as? CGFloat,
					  let intensity = state[kCIInputIntensityKey] as? CGFloat,
					  let radius = state[kCIInputRadiusKey] as? CGFloat else {
					return
				}
				print("edge \(edgeBrightness), intensity \(intensity), radius \(radius)")
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
		self.setMaskBlur()
	}
}

protocol EditorDelegation {
	func savingCompletion(error: Error?) -> Void
}
