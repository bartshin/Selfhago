//
//  ImageAnalyst.swift
//  moody
//
//  Created by bart Shin on 14/07/2021.
//

import CoreImage
import Vision

struct ImageAnalyst {
	/// - Returns: Average of Luminace in (0...1)
	func calcAverageLuminace(from image: CGImage) -> Float? {
		guard let imageData = image.dataProvider?.data ,
			  let ptr = CFDataGetBytePtr(imageData) else {
			return nil
		}
		let length = CFDataGetLength(imageData)
		var luminance: Float = 0
		for i in stride(from: 0, to: length, by: 4) {
			let r = ptr[i]
			let g = ptr[i + 1]
			let b = ptr[i + 2]
			luminance += ((0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b))) / 255
		}
		return luminance / Float(length/4)
	}
	
	func requestFaceDetection(_ cgImage: CGImage, orientation: CGImagePropertyOrientation) -> Promise<[CGRect]> {
		let promise = Promise<[CGRect]>()
		
		DispatchQueue.global(qos: .userInitiated).async {
			let request = VNDetectFaceRectanglesRequest { request, error in
				if let result = request.results as? [VNFaceObservation] {
					promise.resolve(with: result.map {
						let box = $0.boundingBox
						return CGRect(x: box.origin.x,
									  y: 1 - box.maxY,
									  width: box.width,
									  height: box.height)
					})
				}else  {
					promise.reject(with: AnalysisError.faceDetection("Error with VNDetectFaceRectanglesRequest\n \(error?.localizedDescription ?? "")"))
				}
			}
			let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
			do {
				try handler.perform([request])
			}catch {
				promise.reject(with: AnalysisError.faceDetection("Error with VNImageRequestHandler \n \(error.localizedDescription)"))
			}
		}
		return promise
	}
	
	enum AnalysisError: Error {
		case faceDetection (String)
	}
}
