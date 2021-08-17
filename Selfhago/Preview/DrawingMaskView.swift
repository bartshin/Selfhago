//
//  DrawingMaskView.swift
//  Selfhago
//
//  Created by bart Shin on 25/06/2021.
//

import SwiftUI
import PencilKit

struct DrawingMaskView: UIViewRepresentable {
	
	private let canvas: PKCanvasView
	private var drawingTool: PKInkingTool
	private var isDrawing: Bool
	private let gestureDelegate: GestureDelegate
	
	func makeUIView(context: Context) -> PKCanvasView {
		canvas.drawingPolicy = .anyInput
		canvas.tool = isDrawing ? drawingTool: PKEraserTool(.bitmap)
		canvas.backgroundColor = .clear
		canvas.addGestureRecognizer(gestureDelegate.pinchGestureRecognizer)
		canvas.addGestureRecognizer(gestureDelegate.panGestureRecognizer)
		canvas.addGestureRecognizer(gestureDelegate.doubleTapGestureRecognizer)
		return canvas
	}
	
	func updateUIView(_ uiView: PKCanvasView, context: Context) {
		if isDrawing {
			canvas.tool = drawingTool
		}else {
			canvas.tool = PKEraserTool(.bitmap)
		}
	}
	
	init(canvas: PKCanvasView, drawingTool: PKInkingTool, isDrawing: Bool, gestureDelegate: GestureDelegate) {
		self.canvas = canvas
		self.drawingTool = drawingTool
		self.isDrawing = isDrawing
		self.gestureDelegate = gestureDelegate
	}
}
