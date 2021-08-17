//
//  UIFontPickerRepresentable.swift
//  Test
//
//  Created by bart Shin on 23/07/2021.
//

import SwiftUI

struct UIFontPickerRepresentable: UIViewControllerRepresentable {
	
	private let onPickFont: (UIFontDescriptor) -> Void
	
	func makeUIViewController(context: Context) -> UIFontPickerViewController {
		let configuration = UIFontPickerViewController.Configuration()
		configuration.includeFaces = true
		configuration.displayUsingSystemFont = false
		let pickerVC = UIFontPickerViewController(configuration: configuration)
		pickerVC.delegate = context.coordinator
		return pickerVC
	}
	
	func updateUIViewController(_ uiViewController: UIFontPickerViewController, context: Context) {
		
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self, onPickFont: onPickFont)
	}
	
	init(onPickFont: @escaping (UIFontDescriptor) -> Void
		 ) {
		self.onPickFont = onPickFont
	}
	
	class Coordinator: NSObject, UIFontPickerViewControllerDelegate {
		private let parent: UIFontPickerRepresentable
		private let onPickFont: (UIFontDescriptor) -> Void
		
		func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
			guard let descriptor = viewController.selectedFontDescriptor else {
				return
			}
			onPickFont(descriptor)
		}
		
		init(_ parent: UIFontPickerRepresentable,
			 onPickFont: @escaping (UIFontDescriptor) -> Void) {
			self.parent = parent
			self.onPickFont = onPickFont
		}
	}
}
