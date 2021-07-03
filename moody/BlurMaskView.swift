//
//  BlurMaskView.swift
//  moody
//
//  Created by bart Shin on 25/06/2021.
//

import SwiftUI
import PencilKit

struct BlurMaskView: UIViewRepresentable {
	
	@Binding var canvas: PKCanvasView
	@Binding var markerWidth: CGFloat
	private let colorScheme: ColorScheme
	
	private var tool: PKInkingTool {
		PKInkingTool(.marker,
					 color: colorScheme == .light ? .black: .white,
					 width: markerWidth)
			
	}
	
	func makeUIView(context: Context) -> PKCanvasView {
		canvas.drawingPolicy = .anyInput
		canvas.tool = tool
		canvas.backgroundColor = .clear
		return canvas
	}
	
	func updateUIView(_ uiView: PKCanvasView, context: Context) {
		canvas.tool = tool
	}
	
	init(canvas: Binding<PKCanvasView>, markerWidth: Binding<CGFloat>, in colorScheme: ColorScheme) {
		_canvas = canvas
		_markerWidth = markerWidth
		self.colorScheme = colorScheme
	}
}
