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
			if let colorControl = CIColorFilterControl(rawValue: currentControl) {
				drawSlider(for: colorControl)
			}else if DrawableFilterControl(rawValue: currentControl) != nil {
				blurmaskControlSlider
			}else if let presetFilter = PresetFilterControl(rawValue: currentControl) {
				drawPresetControl(for: presetFilter)
			}else if let tunableFilter = TunableFilterControl(rawValue: currentControl) {
				drawVerticalSliders(for: tunableFilter)
			}
		}
		.padding(.horizontal, Constant.horizontalPadding)
	}
	
	private func getLabel(for control: String) -> Image {
		if let colorControl = CIColorFilterControl(rawValue: control) {
			return colorControl.label
		}else if let blurControl = DrawableFilterControl(rawValue: control) {
			return blurControl.label
		}else if let selectiveControl = TunableFilterControl(rawValue: control) {
			return selectiveControl.label
		}else if let presetFilter = PresetFilterControl(rawValue: control) {
			return presetFilter.label
		}else {
			return Image(uiImage: UIImage())
		}
	}
	
	private var blurmaskControlSlider: some View {
		VStack {
			HStack {
				Text("강도")
				Slider(value: $editingState.blurIntensity, in: 0...20, step: 1)
			}
			HStack {
				Text("범위")
				Slider(value: $editingState.blurMarkerWidth, in: 10...60, step: 5)
			}
		}
		.padding(.top, Constant.verticalPadding)
	}
	
	private func drawButton<L>(for control: String, label: L) -> some View where L: View {
		Button(action: {
			withAnimation{
				currentControl = control
			}
		}) {
			label
		}
		.buttonStyle(BottomNavigation())
		.foregroundColor(control == currentControl ? .yellow: .white)
		.scaleEffect(control == currentControl ? 1.3: 1)
		.padding(.horizontal)
	}
		
	private func drawSlider(for colorControl: CIColorFilterControl) -> some View {
		VStack {
			Slider(value: createBinding(to: colorControl, with: colorControl.rawValue), in: -0.5...0.5,
			   step: 0.01)
			if colorControl == .brightness {
				drawVerticalSliders(for: .rgb)
					.layoutPriority(1)
			}
		}
		.padding(.top, colorControl != .brightness ? Constant.verticalPadding: 0)
	}
	
	private func createBinding(to colorControl: CIColorFilterControl, with key: String) -> Binding<Double> {
		Binding<Double> {
			editingState.colorControl[colorControl]! - colorControl.defaultValue
		} set: {
			editingState.colorControl[colorControl] = $0 + colorControl.defaultValue
			editor.setCIColorControl(with: key)
		}
	}
	
	private func drawVerticalSliders(for filter: TunableFilterControl) -> some View {
		GeometryReader { geometry in
			HStack {
				ForEach(0..<filter.tunableFactors) {
					VSlider(value: createBinding(
								to: filter, at: $0),
							in: filter.getRange(for: $0),
							step: 0.01,
							sliderSize:
								.init(width: geometry.size.width * 0.25,
									  height: geometry.size.height ))
				}
			}
			.frame(width: geometry.size.width, height: geometry.size.height)
		}
	}
	
	private func createBinding(to tunableControl: TunableFilterControl, at index: Int) -> Binding<CGFloat> {
		switch tunableControl {
			case .rgb:
				return Binding<CGFloat> {
					var value: CGFloat = 0
					SelectiveBrightness.FilterParameter.RGBColor.allCases.forEach {
						value += editingState.selectiveControl[$0]![index]
					}
					return value/3 // Average of rgb
				} set: { value in
					SelectiveBrightness.FilterParameter.RGBColor.allCases.forEach { component in
						editingState.selectiveControl[component]![index] = value
					}
					editor.setSelectiveBrightness()
				}
			case .bilateral:
				return Binding<CGFloat> {
					index == 0 ? editingState.bilateralControl.radius:
						editingState.bilateralControl.intensity
				}set: {
					if index == 0 {
						editingState.bilateralControl.radius = $0
					}else {
						editingState.bilateralControl.intensity = $0
					}
					editor.setBilateral()
				}
			case .vignette:
				return Binding<CGFloat> {
					if index == 0 {
						return editingState.vignetteControl.radius
					}
					else if index == 1 {
						return editingState.vignetteControl.intensity
					}
					else {
						return editingState.vignetteControl.edgeBrightness
					}
				}set: {
					if index == 0 {
						editingState.vignetteControl.radius = $0
					}
					else if index == 1 {
						editingState.vignetteControl.intensity = $0
					}
					else {
						editingState.vignetteControl.edgeBrightness = $0
					}
					editor.setVignette()
				}
		}
	}
	@ViewBuilder
	private func drawPresetControl(for presetFilter: PresetFilterControl) -> some View {
		HStack (spacing: 30) {
			if let luts = presetFilter.luts {
				ForEach(luts.enumerated().sorted(by: { lhs, rhs in
					lhs.element < rhs.element
				}), id: \.element) { filter in
					Button("\(presetFilter.lutCode!)\(filter.offset)") {
						editor.setLutCube(filter.element)
					}
				}
			}else {
				HStack (spacing: 20) {
					VSlider(value: Binding<CGFloat>(
								get: { editingState.outlineControl.bias
								}, set: {
									editingState.outlineControl.bias = $0
									editor.setOutline()
								}),
							in: 0.1...2,
							sliderSize: .init(width: 30,
											  height: 100))
					VSlider(value: Binding<CGFloat>(
								get: { editingState.outlineControl.weight
								}, set: {
									editingState.outlineControl.weight = $0
									editor.setOutline()
								}),
							in: 0.1...4,
							sliderSize: .init(width: 30,
											  height: 100))
				}
				.padding(.vertical, 20)
			}
		}
	}
	
	struct Constant {
		static let horizontalPadding: CGFloat = 50
		static let verticalPadding: CGFloat = 30
	}
	
	init(currentControl: Binding<String>) {
		self._currentControl = currentControl
		allControls = CIColorFilterControl.allCases.compactMap{ $0.rawValue } + [
			TunableFilterControl.bilateral.rawValue, TunableFilterControl.vignette.rawValue,
			DrawableFilterControl.mask.rawValue] + PresetFilterControl.allCases.compactMap { $0.rawValue }
	}
}

struct ImageTuningPanel_Previews: PreviewProvider {
    static var previews: some View {
		TuningPanel(currentControl: Binding<String>.constant(TunableFilterControl.rgb.rawValue))
			.environmentObject(ImageEditor.forPreview)
			.preferredColorScheme(.dark)
    }
}
