//
//  DrawingToolPicker.swift
//  DrawingToolPicker
//
//  Created by bart Shin on 2021/08/17.
//

import SwiftUI
import PencilKit

struct DrawingToolPicker: UIViewRepresentable {
	
	@Binding var isPresenting: Bool
	let canvas: PKCanvasView
	let picker: PKToolPicker
	
	func makeUIView(context: Context) -> some UIView {
		let placeHolderView = UIView()
		picker.setVisible(isPresenting, forFirstResponder: canvas)
		picker.addObserver(canvas)
		picker.colorUserInterfaceStyle = .light
		DispatchQueue.main.async {
			canvas.becomeFirstResponder()
		}
		return placeHolderView
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) {
		picker.setVisible(isPresenting, forFirstResponder: canvas)
	}
}
