//
//  TuningPanel.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

struct TuningPanel: View {
	
	@EnvironmentObject var editor: ImageEditor
	@Binding var currentControl: String
	private let allControls: [String]

	var body: some View {
		VStack {
			ScrollView (.horizontal, showsIndicators: false) {
				HStack {
					ForEach(allControls, id: \.self) {
						drawButton(for: $0, label: getLabel(for: $0))
					}
				}
			}
			if let colorControl = BuiltInColorControl(rawValue: currentControl) {
				drawSlider(for: colorControl)
			}else if ImageBlurControl(rawValue: currentControl) != nil {
				blurmaskControlSlider
			}else if let presetFilter = PresetFilter(rawValue: currentControl) {
				drawPresetControl(for: presetFilter)
			}
		}
		.padding(.horizontal, Constant.horizontalPadding)
	}
	
	private func getLabel(for control: String) -> Image {
		if let colorControl = BuiltInColorControl(rawValue: control) {
			return colorControl.label
		}else if let blurControl = ImageBlurControl(rawValue: control) {
			return blurControl.label
		}else if let selectiveControl = ImageSelectiveControl(rawValue: control) {
			return selectiveControl.label
		}else if let presetFilter = PresetFilter(rawValue: control) {
			return presetFilter.label
		}else {
			return Image(uiImage: UIImage())
		}
	}
	
	private var blurmaskControlSlider: some View {
		VStack {
			HStack {
				Text("강도")
				Slider(value: $editor.blurIntensity, in: 0...20, step: 1)
			}
			HStack {
				Text("범위")
				Slider(value: $editor.blurMarkerWidth, in: 10...60, step: 5)
			}
		}
		.padding(.top, Constant.verticalPadding)
	}
	
	private func drawButton<L>(for control: String, label: L) -> some View where L: View {
		Button(action: {
			if currentControl == control {
				withAnimation {
					editor.resetControls()
				}
			}else {
				withAnimation{
					currentControl = control
				}
			}
		}) {
			label
		}
		.buttonStyle(BottomNavigation())
		.foregroundColor(control == currentControl ? .yellow: .white)
		.scaleEffect(control == currentControl ? 1.3: 1)
		.padding(.horizontal)
	}
		
	private func drawSlider(for colorControl: BuiltInColorControl) -> some View {
		VStack {
		Slider(value: createBinding(to: colorControl), in: -0.5...0.5,
			   step: 0.05)
			if colorControl == .brightness {
				drawSliders(for: .brightness)
					.layoutPriority(1)
			}
		}
		.padding(.top, colorControl != .brightness ? Constant.verticalPadding: 0)
	}
	
	private func createBinding(to colorControl: BuiltInColorControl) -> Binding<Double> {
		Binding<Double> {
			editor.colorControl[colorControl]! - colorControl.defaultValue
		} set: {
			editor.colorControl[colorControl] = $0 + colorControl.defaultValue
		}
	}
	
	private func drawSliders(for selectiveControl: ImageSelectiveControl) -> some View {
		GeometryReader { geometry in
			HStack {
				ForEach(0..<4) {
					VSlider(value: createBinding(
								to: selectiveControl, at: $0),
							in: calcRange(for: $0), step: 0.05,
							sliderSize: .init(width: geometry.size.width * 0.25,
											  height: geometry.size.height ))
						
				}
			}
			.frame(width: geometry.size.width, height: geometry.size.height)
		}
	}
	
	private func calcRange(for index: Int) -> ClosedRange<CGFloat> {
		let min = -(1.0*(1 - CGFloat(index)*0.1))
		let max = 1.0*(1 - CGFloat(index)*0.1)
		return min...max
	}
	
	private func createBinding(to selectiveControl: ImageSelectiveControl, at index: Int) -> Binding<CGFloat> {
		switch selectiveControl {
			case .brightness:
				return Binding<CGFloat> {
					var value: CGFloat = 0
					FilterParameter.RGBColor.allCases.forEach {
						value += editor.selectiveControl[$0]![index]
					}
					return value/3
				} set: { value in
					FilterParameter.RGBColor.allCases.forEach { rgb in
						editor.selectiveControl[rgb]![index] = value
					}
					editor.setSelectiveBrightness()
				}
		}
	}
	
	private func drawPresetControl(for presetFilter: PresetFilter) -> some View {
		HStack (spacing: 30) {
			ForEach(presetFilter.luts.enumerated().sorted(by: { lhs, rhs in
				lhs.element < rhs.element
			}), id: \.element) { filter in
				Button("\(presetFilter.code)\(filter.offset)") {
					editor.setLutFilter(filter.element)
				}
			}
		}
	}
	
	struct Constant {
		static let horizontalPadding: CGFloat = 50
		static let verticalPadding: CGFloat = 30
	}
	
	init(currentControl: Binding<String>) {
		self._currentControl = currentControl
		allControls = BuiltInColorControl.allCases.compactMap{ $0.rawValue } + [ImageBlurControl.mask.rawValue, PresetFilter.portrait.rawValue,  PresetFilter.landscape.rawValue]
	}
}

struct ImageTuningPanel_Previews: PreviewProvider {
    static var previews: some View {
		TuningPanel(currentControl: Binding<String>.constant(ImageSelectiveControl.brightness.rawValue))
			.environmentObject(ImageEditor.forPreview)
			.preferredColorScheme(.dark)
    }
}
