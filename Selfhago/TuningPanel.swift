//
//  TuningPanel.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

struct TuningPanel: View {
	
	@EnvironmentObject var editor: ImageEditor
	@EnvironmentObject var editingState: EditingState
	@Binding var currentCategory: FilterCategory<Any>
	@State private var isShowingPicker = false
	
	private let allCategories: [FilterCategory<Any>]

	var body: some View {
		VStack {
			ScrollView (.horizontal, showsIndicators: false) {
				HStack {
					ForEach(allCategories, id: \.self) {
						drawButton(for: $0)
					}
				}
			}
			HStack {
				if currentCategory.isNeedPreviewImage {
					previewImage
				}
				FilterControlView(currentCategory: $currentCategory)
			}
		}
		.padding(.horizontal, Constant.horizontalPadding)
	}
	
	private func drawButton(for category: FilterCategory<Any>) -> some View {
		Button(action: {
			withAnimation{
				currentCategory = category
			}
		}) {
			category.labelImage
		}
		.buttonStyle(BottomNavigation())
		.foregroundColor(category == currentCategory ? .yellow: .white)
		.scaleEffect(category == currentCategory ? 1.3: 1)
		.padding(.horizontal)
	}
	
	private var previewImage: some View {
		Group {
			if editor.materialImage == nil {
				Button(action: showPreviewPicker) {
					Image(systemName: "photo")
				}
			}else {
				Image(uiImage: editor.materialImage!)
					.resizable()
					.frame(width: Constant.previewImageSize.width,
						   height: Constant.previewImageSize.height)
					.onTapGesture(perform: showPreviewPicker)
			}
		}
		.padding(.horizontal)
		.sheet(isPresented: $isShowingPicker, content: createImagePicker)
		.onDisappear {
			editor.clearMaterialImage()
		}
	}
	private func showPreviewPicker() {
		withAnimation {
			isShowingPicker = true
		}
	}
	private func createImagePicker () -> ImagePicker {
		ImagePicker(
			isPresenting: $isShowingPicker,
			passImageData: editor.setMaterialImage)
	}
	
	init(selected category: Binding<FilterCategory<Any>>, in categories: [FilterCategory<Any>]) {
		_currentCategory = category
		allCategories = categories
	}
	
	struct Constant {
		static let horizontalPadding: CGFloat = 50
		static let previewImageSize = CGSize(width: 50, height: 50)
	}
}
#if DEBUG
struct ImageTuningPanel_Previews: PreviewProvider {
	
    static var previews: some View {
		TuningPanel(selected:
						.constant(.init(rawValue: MultiSliderFilterControl.rgb.rawValue)!),
					in: FilterCategory.allCategories)
			.environmentObject(ImageEditor.forPreview)
			.preferredColorScheme(.dark)
    }
}
#endif
