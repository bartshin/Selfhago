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
	
	/// [ Filter name : CI Filter]
	private var editingFilters = [String: CIFilter]()
	private(set) var cgImage: CGImage?
	private var imageOrientation: UIImage.Orientation?
	var imageForDisplay: UIImage?
	var blurMask: PKCanvasView
	var blurIntensity: Double
	@Published var blurMarkerWidth: CGFloat
	private var averageLuminace: Float
	
	var colorControl: [BuiltInColorControl: Double] {
		didSet {
			setColorControlFilter()
			setImageForDisplay()
		}
	}
	var selectiveControl: [FilterParameter.RGBColor: SelectiveBrightness.selectableValues]
	
	var delegate: EditorDelegation?
	private lazy var ciContext = CIContext(options: [.cacheIntermediates: false])
	
	func resetControls() {
		colorControl = BuiltInColorControl.defaults
		selectiveControl.keys.forEach {
			selectiveControl[$0] = SelectiveBrightness.emptyValues
		}
		editingFilters[String(describing: LUTCubeFilter.self)] = nil
		setSelectiveBrightness()
	}
	
	func setNewImage(_ image: UIImage) {
		ciContext.clearCaches()
		cgImage = image.cgImage
		imageOrientation = image.imageOrientation
		setImageForDisplay()
		DispatchQueue.global(qos: .userInitiated).async {
			self.setAverageLuminace()
		}
	}
	
	func setLutFilter(_ lutName: String) {
		let filter = LUTCubeFilter()
		filter.setLut(lutName)
		editingFilters[String(describing: LUTCubeFilter.self)] = filter
		setImageForDisplay()
	}
		
	fileprivate func setColorControlFilter(){
		let filter = CIFilter(name: "CIColorControls")!
		filter.setValue(colorControl[.brightness], forKey: kCIInputBrightnessKey)
		filter.setValue(colorControl[.contrast], forKey: kCIInputContrastKey)
		filter.setValue(colorControl[.saturation], forKey: kCIInputSaturationKey)
		editingFilters["CIColorControls"] = filter
	}
	
	func setSelectiveBrightness() {
		let filter = SelectiveBrightness()
		selectiveControl.keys.forEach { rgb in
			filter.setBrightness(for: rgb, values: [
				.black : selectiveControl[rgb]![0],
				.shadow: selectiveControl[rgb]![1],
				.highlight: selectiveControl[rgb]![2],
				.white: selectiveControl[rgb]![3]
			],
			with: averageLuminace)
		}
		editingFilters[String(describing: SelectiveBrightness.self)] = filter
		setImageForDisplay()
	}
	// FIXME:- Not working
	func applyBilateral() {
		let filter = BilateralFilter()
		filter.setValue(CIImage(cgImage: cgImage!), forKey: kCIInputImageKey)
		if let ciImage = filter.outputImage,
		   let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent){
			imageForDisplay = UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation!)
			publishOnMainThread()
		}else {
			print("Fail to apply bilateral")
		}
	}
	
	/// Edit image immediately not reversible
	func applyBlurByMask() {
		let sourceImage = CIImage(cgImage: cgImage!)
		guard let mask = CIImage(image: blurMask.drawing.image(from: sourceImage.extent, scale: 1)) else {
			assertionFailure("Fail to create mask image")
			return
		}
		let blurFilter = CIFilter(name: "CIMaskedVariableBlur")!
		blurFilter.setValue(mask, forKey: "inputMask")
		blurFilter.setValue(sourceImage, forKey: kCIInputImageKey)
		blurFilter.setValue(blurIntensity, forKey: kCIInputRadiusKey)
		if let outputImage = blurFilter.outputImage,
		   let bluredImage = ciContext.createCGImage(outputImage, from: sourceImage.extent) {
			cgImage = bluredImage
			setImageForDisplay()
		}else {
			print("Fail to apply blur")
		}
	}
	
	func saveImage() {
		guard imageForDisplay != nil else {
			savingCompletion(UIImage(),
							 didFinishSavingWithError: ProcessError.convertingError, contextInfo: nil)
			return
		}
		UIImageWriteToSavedPhotosAlbum(imageForDisplay!, self,
									   #selector(savingCompletion(_:didFinishSavingWithError:contextInfo:)), nil)
	}
	
	@objc fileprivate func savingCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
		delegate?.savingCompletion(error: error)
	}
	
	private func setImageForDisplay() {
		DispatchQueue.global(qos:.userInteractive).sync { [self] in
			if let ciImage = applyFilters(),
			   let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent),
			   imageOrientation != nil{
				imageForDisplay = UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation!)
				publishOnMainThread()
			}
		}
	}
	
	private func applyFilters() -> CIImage?{
		guard cgImage != nil else{
			return nil
		}
		var ciImage: CIImage? = CIImage(cgImage: cgImage!)
		editingFilters.enumerated().forEach {
			let filter = $0.element.value
			filter.setValue(ciImage, forKey: kCIInputImageKey)
			ciImage = filter.outputImage
		}
		return ciImage
	}
	
	private func setAverageLuminace() {
		guard let image = cgImage ,
			  let imageData = image.dataProvider?.data ,
			  let ptr = CFDataGetBytePtr(imageData) else { return  }
		let length = CFDataGetLength(imageData)
		var luminance: Float = 0
		for i in stride(from: 0, to: length, by: 4) {
			let r = ptr[i]
			let g = ptr[i + 1]
			let b = ptr[i + 2]
			luminance += ((0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b))) / 255
		}
		averageLuminace = luminance / Float(length/4)
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
		colorControl = BuiltInColorControl.defaults
		blurMask = PKCanvasView()
		blurIntensity = 10
		blurMarkerWidth = 30
		averageLuminace = 0.5
		selectiveControl = FilterParameter.RGBColor.allCases.reduce(into: [FilterParameter.RGBColor: SelectiveBrightness.selectableValues]()) {
			$0[$1] = SelectiveBrightness.emptyValues
		}
		super.init()
		blurMask.delegate = self
	}
	
}

extension ImageEditor: PKCanvasViewDelegate {
	func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
		guard !canvasView.drawing.strokes.isEmpty else {
			return
		}
		DispatchQueue.global(qos: .userInitiated).async {
			self.applyBlurByMask()
		}
	}
}

protocol EditorDelegation {
	func savingCompletion(error: Error?) -> Void
}
