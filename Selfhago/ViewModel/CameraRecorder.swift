//
//  CameraRecorder.swift
//  Selfhago
//
//  Created by bart Shin on 27/07/2021.
//

import AVFoundation
import UIKit

class CameraRecorder: NSObject, ObservableObject {
	
	private var device: AVCaptureDevice!
	private(set) var captureSession: AVCaptureSession!
	private var stillImageOutput: AVCapturePhotoOutput!
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
	private(set) var position: AVCaptureDevice.Position!
	private var settings: AVCapturePhotoSettings!
	private var processor: CaptureProcessor!
	private let queue: DispatchQueue
	var passImage: (CGImage) -> Void =  { image in
		print("Photo captured \(image.bitmapInfo)")
	}
	
	@Published private(set) var status: Status
	
	private var authorization: Authorization
	
	func setupCamera(position: AVCaptureDevice.Position) {
		if self.position != nil, self.position == position {
			return
		}
		self.position = position
		device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position == .front ? .front: .back)
		if device == nil {
			assertionFailure("No camera is available for video")
		}
		initInputAndOutput()
	}
	
	func checkAuthorization(grantedHandler: @escaping () -> Void, deniedHandler: @escaping () -> Void) {
		if authorization.status == .notDetermined {
			AVCaptureDevice.requestAccess(for: .video) {[self] granted in
				if granted {
					authorization.changeStatus(to: .authorized)
				}else {
					authorization.changeStatus(to: .denied)
				}
			}
		}else if authorization.status == .denied {
			deniedHandler()
		}else if authorization.status == .authorized {
			grantedHandler()
		}
	}
	
	func startRecording() {
		status = .recording
		queue.async {
			self.captureSession.startRunning()
		}
	}
	
	func stopRecording() {
		queue.async {
			self.captureSession.stopRunning()
			DispatchQueue.main.async {
				self.status = .notRecording
			}
		}
	}
	
	func capturePhoto() {
		guard status == .recording else {
			return
		}
		status = .processing
		queue.async { [self] in
			stillImageOutput.capturePhoto(with: settings, delegate: processor)
		}
	}
	
	private func initInputAndOutput() {
		captureSession.beginConfiguration()
		if !captureSession.inputs.isEmpty {
			captureSession.removeInput(captureSession.inputs.first!)
		}
		defer {
			captureSession.commitConfiguration()
		}
		do {
			let input = try AVCaptureDeviceInput(device: device)
			stillImageOutput = AVCapturePhotoOutput()
			if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
				captureSession.addInput(input)
				captureSession.addOutput(stillImageOutput)
				stillImageOutput.isHighResolutionCaptureEnabled = true
				stillImageOutput.maxPhotoQualityPrioritization = .quality
			}
			if let connection = stillImageOutput.connection(with: .video) {
				connection.videoOrientation = .portrait
			}
			if stillImageOutput.availablePhotoCodecTypes.contains(.hevc) {
				settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
			}else {
				settings = AVCapturePhotoSettings()
			}
			settings.isHighResolutionPhotoEnabled = true
			// Sets the preview thumbnail pixel format
			if !settings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
				settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: settings.__availablePreviewPhotoPixelFormatTypes.first!]
			}
			settings.photoQualityPrioritization = .quality
			processor = CaptureProcessor(with: settings, passImage: passImage)
		}
		catch {
			assertionFailure("Fail to set input by \(device!)")
		}
	}
	
	override init() {
		authorization = Authorization()
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = .photo
		status = .preparing
		queue = DispatchQueue(label: String(describing: Self.self))
		
		super.init()
	}
	
	enum Status {
		case recording
		case processing
		case preparing
		case notRecording
	}
	
	private struct Authorization {
		
		private(set) var status: AVAuthorizationStatus
		
		mutating func changeStatus(to newStatus: AVAuthorizationStatus) {
			self.status = newStatus
		}
		
		init() {
			
			switch AVCaptureDevice.authorizationStatus(for: .video) {
				case .authorized:
					self.status = .authorized
				case .denied, .restricted:
					self.status = .denied
				case .notDetermined:
					self.status = .notDetermined
				@unknown default:
					self.status = .notDetermined
			}
			
		}
	}
}
