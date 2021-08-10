//
//  CaptureView.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/09.
//

import SwiftUI

extension View {
	func snapshot() -> UIImage {
		let controller = UIHostingController(rootView: self)
		let view = controller.view
		
		let targetSize = controller.view.intrinsicContentSize
		view?.bounds = CGRect(origin: .zero, size: targetSize)
		view?.backgroundColor = .clear
		view?.isOpaque = false
		let renderer = UIGraphicsImageRenderer(size: targetSize)
		
		return renderer.image { _ in
			view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
		}
	}
}
