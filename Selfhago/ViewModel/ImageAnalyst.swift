//
//  ImageAnalyst.swift
//  moody
//
//  Created by bart Shin on 14/07/2021.
//

import CoreImage
import AVFoundation
import Vision
import UIKit

class ImageAnalyst {
	
	private(set) var averageLuminace: CGFloat = 0.5
	private(set) var faceRegions = [CGRect]()
	private(set) var depthImage: CIImage?
	private var imageSource: CGImageSource?
	private let depthConfig: (slope: CGFloat, width: CGFloat) = (1.0, 0.5)
	private var imageSize: CGSize?
	
	func reset() {
		averageLuminace = 0.5
		faceRegions = []
		imageSource = nil
		imageSize = nil
		depthImage = nil
	}
	
	/// - Returns: Average of Luminace in (0...1)
	func calcAverageLuminace(from image: CGImage) {
		guard let imageData = image.dataProvider?.data ,
			  let ptr = CFDataGetBytePtr(imageData) else {
			return
		}
		let length = CFDataGetLength(imageData)
		var luminance: CGFloat = 0
		for i in stride(from: 0, to: length, by: 4) {
			let r = ptr[i]
			let g = ptr[i + 1]
			let b = ptr[i + 2]
			luminance += ((0.299 * CGFloat(r) + 0.587 * CGFloat(g) + 0.114 * CGFloat(b))) / 255
		}
		averageLuminace = luminance / CGFloat(length/4)
	}
	
	func calcFaceRegions(_ cgImage: CGImage, orientation: CGImagePropertyOrientation){
	
		let request = VNDetectFaceRectanglesRequest { [weak weakSelf = self] request, error in
			if let result = request.results as? [VNFaceObservation] {
				weakSelf?.faceRegions = result.map { face in
					let box = face.boundingBox
					return CGRect(x: box.origin.x,
								  y: 1 - box.maxY,
								  width: box.width,
								  height: box.height)
				}
			}
			
		}
		let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
		do {
			try handler.perform([request])
		}catch {
			print("Error with VNImageRequestHandler \n \(error.localizedDescription)")
		}
		
	}
	
	func createImageSource(from data: Data) {
		imageSource = CGImageSourceCreateWithData(data as CFData, nil)
	}
	
	func createDepthMask(over focus: CGFloat) -> CIImage?  {
		guard depthImage != nil,
			  imageSize != nil else {
			return nil
		}
		
		
		let filterWidth = 2 / depthConfig.slope + depthConfig.width
		let bias = depthConfig.slope * (focus + filterWidth / 2)
		
		let mask = depthImage!
			.applyingFilter("CIColorMatrix", parameters: [
				"inputRVector": CIVector(x: -depthConfig.slope, y: 0, z: 0, w: 0),
				"inputGVector": CIVector(x: 0, y: -depthConfig.slope, z: 0, w: 0),
				"inputBVector": CIVector(x: 0, y: 0, z: -depthConfig.slope, w: 0),
				"inputBiasVector": CIVector(x: bias, y: bias, z: bias, w: 0)
			])
			.applyingFilter("CIColorClamp")
		let originalSize = max(imageSize!.width, imageSize!.height)
		let depthImageSize = max(depthImage!.extent.size.width, depthImage!.extent.size.height)
		let scale = originalSize / depthImageSize
		return mask.applyingFilter("CILanczosScaleTransform", parameters: [
			"inputScale": scale
		])
		.applyingFilter("CIColorClamp")
	}
	
	func createDepthImage() {
		
		guard imageSource != nil,
			  let depthMap = extractDepthData() else {
			depthImage = nil
			return
		}
		
		normalizeDepthData(cvPixelBuffer: depthMap)
		depthImage = CIImage(cvImageBuffer: depthMap)
		
	}
	
	private func extractDepthData() -> CVPixelBuffer? {
		
		let cfAuxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(
			imageSource!,
			0,
			kCGImageAuxiliaryDataTypeDisparity
		)
		guard let auxDataInfo = cfAuxDataInfo as? [AnyHashable : Any] else {
			return nil
		}
		
		let cfProperties = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil)
		guard
			let properties = cfProperties as? [CFString: Any],
			let orientationValue = properties[kCGImagePropertyOrientation] as? UInt32,
			let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
			let height = properties[kCGImagePropertyPixelHeight] as? CGFloat,
			let orientation = CGImagePropertyOrientation(rawValue: orientationValue)
		else {
			return nil
		}
		imageSize = CGSize(width: width, height: height)
		guard var depthData = try? AVDepthData(
			fromDictionaryRepresentation: auxDataInfo
		) else {
			return nil
		}
		
		if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
			depthData = depthData.converting(
				toDepthDataType: kCVPixelFormatType_DisparityFloat32
			)
		}
		return depthData.applyingExifOrientation(orientation).depthDataMap
	}
	
	private func normalizeDepthData(cvPixelBuffer: CVPixelBuffer) {
		let width = CVPixelBufferGetWidth(cvPixelBuffer)
		let height = CVPixelBufferGetHeight(cvPixelBuffer)
		
		CVPixelBufferLockBaseAddress(cvPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
		let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(cvPixelBuffer), to: UnsafeMutablePointer<Float>.self)
		
		var minPixel: Float = 1.0
		var maxPixel: Float = 0.0
		
		/// You might be wondering why the for loops below use `stride(from:to:step:)`
		/// instead of a simple `Range` such as `0 ..< height`?
		/// The answer is because in Swift 5.1, the iteration of ranges performs badly when the
		/// compiler optimisation level (`SWIFT_OPTIMIZATION_LEVEL`) is set to `-Onone`,
		/// which is eactly what happens when running this sample project in Debug mode.
		/// If this was a production app then it might not be worth worrying about but it is still
		/// worth being aware of.
		
		for y in stride(from: 0, to: height, by: 1) {
			for x in stride(from: 0, to: width, by: 1) {
				let pixel = floatBuffer[y * width + x]
				minPixel = min(pixel, minPixel)
				maxPixel = max(pixel, maxPixel)
			}
		}
		
		let range = maxPixel - minPixel
		for y in stride(from: 0, to: height, by: 1) {
			for x in stride(from: 0, to: width, by: 1) {
				let pixel = floatBuffer[y * width + x]
				floatBuffer[y * width + x] = (pixel - minPixel) / range
			}
		}
		
		CVPixelBufferUnlockBaseAddress(cvPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
	}
	
	enum AnalysisError: Error {
		case faceDetection (String)
	}
}
