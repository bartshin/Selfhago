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
	private var videoOutput: AVCaptureVideoDataOutput!
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
	private(set) var position: AVCaptureDevice.Position!
	private var settings: AVCapturePhotoSettings!
	private let captureQueue: DispatchQueue
	private let videoOutputQueue: DispatchQueue
	var videoOutputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!
	
	private var authorization: Authorization
	
	func setupCamera(position: AVCaptureDevice.Position, cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera) {
		if self.position != nil, self.position == position {
			return
		}
		self.position = position
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [cameraType], mediaType: .video, position: position)
		device = discoverySession.devices.first
		if device == nil {
			assertionFailure("No camera is available for video \(cameraType), \(position)")
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
		captureQueue.sync {
			self.captureSession.startRunning()
		}
	}
	
	func stopRecording() {
		captureQueue.async {
			self.captureSession.stopRunning()
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
			if captureSession.canSetSessionPreset(.photo) {
				captureSession.sessionPreset = .photo
			}else if captureSession.canSetSessionPreset(.high) {
				captureSession.sessionPreset = .high
			}
			videoOutput = AVCaptureVideoDataOutput()
			videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): NSNumber(value: kCVPixelFormatType_32BGRA)]
			videoOutput.alwaysDiscardsLateVideoFrames = true
			setMaxFramerate(for: device)
			videoOutput.setSampleBufferDelegate(videoOutputDelegate, queue: videoOutputQueue)
			if captureSession.canAddInput(input), captureSession.canAddOutput(videoOutput) {
				captureSession.addInput(input)
				captureSession.addOutput(videoOutput)
			}
		}
		catch {
			assertionFailure("Fail to set input by \(device!)")
		}
	}
	private func setMaxFramerate(for camera: AVCaptureDevice) {
		for vFormat in camera.formats {
			//see available types
			
			let ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
			guard let frameRates = ranges.sorted(by: { lhs, rhs in
				lhs.maxFrameRate > rhs.maxFrameRate
			}).first else {
				return
			}
			
			do {
				
				try camera.lockForConfiguration()
				camera.activeFormat = vFormat as AVCaptureDevice.Format
				//for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
				camera.activeVideoMinFrameDuration = frameRates.minFrameDuration
				camera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
				
			}
			catch {
				print("Could not set active format")
				print(error)
			}
		}
	}
	override init() {
		authorization = Authorization()
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = .photo
		captureQueue = DispatchQueue(label: "capture queue")
		videoOutputQueue = DispatchQueue(label: "video output queue")
		super.init()
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
