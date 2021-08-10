//
//  LimitedImagePicker.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/04.
//

import SwiftUI
import PhotosUI

struct LimitedImagePicker: UIViewControllerRepresentable {

	@Binding var isPresented: Bool
	
	func makeUIViewController(context: Context) -> some UIViewController {
		let viewController = UIViewController()
		viewController.modalPresentationStyle = .fullScreen
		viewController.modalTransitionStyle = .crossDissolve
		viewController.view.isOpaque = false
		viewController.view.backgroundColor = .clear
		
		PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
		context.coordinator.trackCompletion(in: viewController)
		return viewController
	}
	
	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
		
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(isPresented: $isPresented)
	}
	
	init(isPresenting: Binding<Bool>) {
		self._isPresented = isPresenting
	}
	
	class Coordinator: NSObject {
		private var isPresented: Binding<Bool>
		init(isPresented: Binding<Bool>) {
			self.isPresented = isPresented
		}
		
		func trackCompletion(in controller: UIViewController) {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak controller] in
				if controller?.presentedViewController == nil {
					self?.isPresented.wrappedValue = false
				} else if let controller = controller {
					self?.trackCompletion(in: controller)
				}
			}
		}
	}
}
