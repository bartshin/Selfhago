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
		return canvas
	}
	
	func updateUIView(_ uiView: PKCanvasView, context: Context) {
		canvas.tool = tool
	}
	
	init(canvas: Binding<PKCanvasView>, markerWidth: Binding<CGFloat>) {
		_canvas = canvas
		_markerWidth = markerWidth
	}
}
