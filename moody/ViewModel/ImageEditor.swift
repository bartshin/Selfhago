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
		
	private let analyst: ImageAnalyst
	
	/// [ Filter name : CI Filter]
	private var editingFilters = [String: CIFilter]()
	private var cgImage: CGImage?
	private(set) var ciImage: CIImage?
	private var imageSize: CGSize?
	var imageForDisplay: UIImage?
	private var averageLuminace: Float
	private var faceRegions: [CGRect]
	// MARK:- Filter adjust factor
	var blurMask: PKCanvasView
	var blurIntensity: Double
	var bilateralFactor: (radius: Float, intensity: Float) 
	@Published var blurMarkerWidth: CGFloat
	
	
	var colorControl: [CIColorControlFilter: Double] {
		didSet {
			setColorControlFilter()
		}
	}
	var selectiveControl: [FilterParameter.RGBColor: SelectiveBrightness.selectableValues]
	
	var delegate: EditorDelegation?
	private lazy var ciContext = CIContext(options: [.cacheIntermediates: false])
	
	func resetControls() {
		colorControl = CIColorControlFilter.defaults
		selectiveControl.keys.forEach {
			selectiveControl[$0] = SelectiveBrightness.emptyValues
		}
		editingFilters[String(describing: LUTCubeFilter.self)] = nil
		bilateralFactor = (0.1, 0.1)
		editingFilters[String(describing: BilateralFilter.self)] = nil
		setSelectiveBrightness()
	} 
	
	func setNewImage(_ image: UIImage) {
		ciContext.clearCaches()
		imageSize = image.size
		cgImage = image.cgImage
		if cgImage == nil {
			assertionFailure("Missing cg image")
			return
		}
		ciImage = CIImage(
			cgImage: cgImage!,
			options: [.applyOrientationProperty: true,
					  .properties: [kCGImagePropertyOrientation: image.imageOrientation.cgOrientation.rawValue]])
		
		setImageForDisplay()
		setAverageLuminance()
		setFaceRegions(for: image.imageOrientation.cgOrientation)
	}
	
	func setLutFilter(_ lutName: String) {
		let filter = LUTCubeFilter()
		filter.setLut(lutName)
		editingFilters[String(describing: LUTCubeFilter.self)] = filter
		setImageForDisplay()
	}
		
	fileprivate func setColorControlFilter(){
		let filter = getFilter(CIFilter.self, name: "CIColorControls")
		filter.setValue(colorControl[.brightness], forKey: kCIInputBrightnessKey)
		filter.setValue(colorControl[.contrast], forKey: kCIInputContrastKey)
		filter.setValue(colorControl[.saturation], forKey: kCIInputSaturationKey)
		setImageForDisplay()
	}
	
	func setSelectiveBrightness() {
		let filter = getFilter(SelectiveBrightness.self)
		selectiveControl.keys.forEach { rgb in
			filter.setBrightness(for: rgb, values: [
				.black : selectiveControl[rgb]![0],
				.shadow: selectiveControl[rgb]![1],
				.highlight: selectiveControl[rgb]![2],
				.white: selectiveControl[rgb]![3]
			],
			with: averageLuminace)
		}
		setImageForDisplay()
	}
	
	func setBilateral() {
		let filter = getFilter(BilateralFilter.self)
		filter.setValue(bilateralFactor.radius, forKey: kCIInputRadiusKey)
		filter.setValue(bilateralFactor.intensity, forKey: kCIInputIntensityKey)
		filter.setValue(imageSize, forKey: kCIInputExtentKey)
		filter.setValue(faceRegions, forKey: BilateralFilter.faceRegionsKey)
		setImageForDisplay()
	}
	
	/// Edit image immediately not reversible
	func applyBlurByMask() {
		guard let sourceImage = ciImage,
			let mask = CIImage(
			image: blurMask.drawing.image(
				from: sourceImage.extent, scale: 1)
		) else {
			assertionFailure("Fail to create mask image")
			return
		}
		let blurFilter = CIFilter(name: "CIMaskedVariableBlur")!
		blurFilter.setValue(mask, forKey: "inputMask")
		blurFilter.setValue(sourceImage, forKey: kCIInputImageKey)
		blurFilter.setValue(blurIntensity, forKey: kCIInputRadiusKey)
		if let outputImage = blurFilter.outputImage,
		   let bluredImage = ciContext.createCGImage(outputImage, from: sourceImage.extent) {
			ciImage = CIImage(cgImage: bluredImage)
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
	
	fileprivate func getFilter<T>(_ filterType: T.Type, name: String? = nil) -> T where T: CIFilter {
		let key = name ?? String(describing: T.self)
		if editingFilters[key] == nil {
			editingFilters[key] = name != nil ? CIFilter(name: name!): T()
		}
		return editingFilters[key] as! T
	}
	
	@objc fileprivate func savingCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
		delegate?.savingCompletion(error: error)
	}
	
	private func setImageForDisplay() {
		DispatchQueue.global(qos:.userInteractive).sync { [self] in
			if let ciImage = applyFilters(),
			   let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent){
				imageForDisplay = UIImage(cgImage: cgImage)
				publishOnMainThread()
			}
		}
	}
	
	private func setAverageLuminance() {
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			guard let strongSelf = self,
				  let cgImage = strongSelf.cgImage,
				  let luminace = strongSelf.analyst.calcAverageLuminace(from: cgImage) else { return }
			strongSelf.averageLuminace = luminace
		}
	}
	
	private func setFaceRegions(for orientation: CGImagePropertyOrientation) {
		
		analyst.requestFaceDetection(cgImage!, orientation: orientation)
			.observe { [weak weakSelf = self] result in
				if case .success(let regions) = result {
					weakSelf?.faceRegions = regions
				}else if case .failure(let error) = result {
					print(error)
					weakSelf?.faceRegions = []
				}
			
			}
	}
	
	private func applyFilters() -> CIImage?{
		guard cgImage != nil else{
			return nil
		}
		
		var ciImage: CIImage? = ciImage
		editingFilters.enumerated().forEach {
			let filter = $0.element.value
			filter.setValue(ciImage, forKey: kCIInputImageKey)
			ciImage = filter.outputImage
		}
		return ciImage
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
		colorControl = CIColorControlFilter.defaults
		blurMask = PKCanvasView()
		blurIntensity = 10
		blurMarkerWidth = 30
		averageLuminace = 0.5
		bilateralFactor = (0.1, 0.1)
		selectiveControl = FilterParameter.RGBColor.allCases.reduce(into: [FilterParameter.RGBColor: SelectiveBrightness.selectableValues]()) {
			$0[$1] = SelectiveBrightness.emptyValues
		}
		analyst = ImageAnalyst()
		faceRegions = []
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
