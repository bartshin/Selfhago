//
//  HomeMenu.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

struct HomeMenu: View {
	
	@Binding var navigationTag: String?
	private let editor = ImageEditor()
	private var recorder: CameraRecorder {
		let recorder = CameraRecorder()
		recorder.videoOutputDelegate = editor
		return recorder
	}
	
	var body: some View {
		HStack {
			createNavigationLink(for: EditView()
								 	.environmentObject(editor)
									.environmentObject(editor.editingState),
								 image: Image(systemName: "slider.horizontal.below.rectangle"))
			createNavigationLink(for: CameraView(recorder: recorder)
									.environmentObject(editor)
									.environmentObject(editor.editingState),
								 image: Image(systemName: "camera"))
		}
	}
	
	private func createNavigationLink<D>(for destination: D, image: Image) -> some View where D: View  {
		NavigationLink(
			destination: destination,
			tag: String(describing: D.self),
			selection: $navigationTag)
		{
			drawButton(for: D.self, image: image)
				.padding(.horizontal)
		}
	}
	
	private func drawButton<D>(for destination: D.Type, image: Image) -> some View where D: View{
		Button(action: {
			navigationTag = String(describing: D.self)
		} ) {
			image
				.resizable()
				.frame(width: Constant.bottomButtonSize.width,
					   height: Constant.bottomButtonSize.height)
				.padding()
		}
		.buttonStyle(BottomNavigation())
	}
	
	struct Constant {
		static let bottomButtonSize = CGSize(width: 50, height: 50)
	}
}

