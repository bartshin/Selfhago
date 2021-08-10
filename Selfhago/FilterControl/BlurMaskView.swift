//
//  BlurMaskView.swift
//  moody
//
//  Created by bart Shin on 25/06/2021.
//

import SwiftUI
import PencilKit

struct BlurMaskView: UIViewRepresentable {
	
	private let canvas: PKCanvasView
	@Binding var markerWidth: CGFloat
	private let gestureDelegate: GestureDelegate
	
	private var tool: PKInkingTool {
		let colorScheme = UIApplication.shared.windows.first?.traitCollection.userInterfaceStyle
		let color: UIColor = colorScheme == .dark ? .black: .white
		return PKInkingTool(.marker,
					 color: color,
					 width: markerWidth)
	}
	
	func makeUIView(context: Context) -> PKCanvasView {
		canvas.drawingPolicy = .anyInput
		canvas.tool = tool
		canvas.backgroundColor = .clear
		canvas.addGestureRecognizer(gestureDelegate.pinchGestureRecognizer)
		canvas.addGestureRecognizer(gestureDelegate.panGestureRecognizer)
		canvas.addGestureRecognizer(gestureDelegate.doubleTapGestureRecognizer)
		return canvas
	}
	
	func updateUIView(_ uiView: PKCanvasView, context: Context) {
		canvas.tool = tool
	}
	
	init(canvas: PKCanvasView, markerWidth: Binding<CGFloat>, gestureDelegate: GestureDelegate) {
		self.canvas = canvas
		_markerWidth = markerWidth
		self.gestureDelegate = gestureDelegate
	}
}
