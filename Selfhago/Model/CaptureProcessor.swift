//
//  CaptureProcessor.swift
//  Selfhago
//
//  Created by bart Shin on 28/07/2021.
//

import Photos

class CaptureProcessor: NSObject {
	private lazy var ciContext = CIContext()
	private(set) var requestedPhotoSetting: AVCapturePhotoSettings
	private(set) var maxiumProcessingTime: CMTime?
	private let passImage: (CGImage) -> Void
	
	init(with settings: AVCapturePhotoSettings, passImage: @escaping (CGImage) -> Void) {
		requestedPhotoSetting = settings
		self.passImage = passImage
	}
}

extension CaptureProcessor: AVCapturePhotoCaptureDelegate {
	
	func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
		maxiumProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
	}
	
	func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
		guard maxiumProcessingTime != nil else {
			return
		}
		
		let processingTimeToSecond = maxiumProcessingTime!.seconds
		print("Image capture will take \(processingTimeToSecond) seconds")
	}
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		guard error == nil else {
			print("Error with processing photo \(error!.localizedDescription)")
			return
		}
		
		guard let cgImage = photo.cgImageRepresentation() else {
			print("Fail to get cg image from \(photo.metadata)")
			return
		}
		passImage(cgImage)
		
	}
	
}
