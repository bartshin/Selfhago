//
//  CameraPreview.swift
//  Selfhago
//
//  Created by bart Shin on 28/07/2021.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
	
	let session: AVCaptureSession
	
	class VideoPreview: UIView {
		class override var layerClass: AnyClass {
			AVCaptureVideoPreviewLayer.self
		}
		
		var previewLayer: AVCaptureVideoPreviewLayer {
			layer as! AVCaptureVideoPreviewLayer
		}
	}
	
	func makeUIView(context: Context) -> VideoPreview {
		let view = VideoPreview()
		view.backgroundColor = .black
		view.previewLayer.cornerRadius = 0
		view.previewLayer.session = session
		view.previewLayer.connection?.videoOrientation = .portrait
		return view
	}
	
	func updateUIView(_ uiView: VideoPreview, context: Context) {
		
	}
	
}
