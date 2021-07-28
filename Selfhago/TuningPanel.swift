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
			FilterControlView(currentCategory: $currentCategory)
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
	
	init(category: Binding<FilterCategory<Any>>) {
		self._currentCategory = category
		let filters = SingleSliderFilterControl.allCases.compactMap{ $0.rawValue } +
			[
			MultiSliderFilterControl.bilateral.rawValue, MultiSliderFilterControl.vignette.rawValue,
				MultiSliderFilterControl.outline.rawValue,
				MultiSliderFilterControl.textStamp.rawValue,
				DrawableFilterControl.mask.rawValue, AngleAndSliderFilterControl.glitter.rawValue
			] +
			LUTFilterControl.allCases.compactMap { $0.rawValue }
		allCategories = filters.map {
			FilterCategory(rawValue: $0)!
		}
	}
	
	struct Constant {
		static let horizontalPadding: CGFloat = 50
	}
}

struct ImageTuningPanel_Previews: PreviewProvider {
    static var previews: some View {
		TuningPanel(category:
						.constant(.init(rawValue: MultiSliderFilterControl.rgb.rawValue)!))
			.environmentObject(ImageEditor.forPreview)
			.preferredColorScheme(.dark)
    }
}
