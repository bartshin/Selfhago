//
//  FilterControlView.swift
//  moody
//
//  Created by bart Shin on 19/07/2021.
//

import SwiftUI

struct FilterControlView: View {
	
	@EnvironmentObject var editor: ImageEditor
	@EnvironmentObject var editingState: EditingState
	@Binding var currentCategory: FilterCategory<Any>
	
	var body: some View {
		
		if let colorControl = currentCategory.control as? CIColorFilterControl {
			drawSlider(for: colorControl)
		}else if currentCategory.control is DrawableFilterControl{
			blurmaskControlSlider
		}else if let LUTFilter = currentCategory.control as? LUTFilterControl {
			drawLUTControl(for: LUTFilter)
		}else if let multiSliderFilter = currentCategory.control as? MultiSliderFilterControl {
			drawVerticalSliders(for: multiSliderFilter)
		}else if let angleAndSliderFilter = currentCategory.control as? AngleAndSliderFilterControl {
			drawControls(for: angleAndSliderFilter)
		}
	}
	
	private func drawSlider(for colorControl: CIColorFilterControl) -> some View {
		VStack {
			Slider(value: binding(to: colorControl, with: colorControl.rawValue), in: -0.5...0.5,
				   step: 0.01)
			if colorControl == .brightness {
				drawVerticalSliders(for: .rgb)
					.layoutPriority(1)
			}
		}
		.padding(.top, colorControl != .brightness ? Constant.verticalPadding: 0)
	}
	
	private func binding(to colorControl: CIColorFilterControl, with key: String) -> Binding<Double> {
		Binding<Double> {
			editingState.colorControl[colorControl]! - colorControl.defaultValue
		} set: {
			editingState.colorControl[colorControl] = $0 + colorControl.defaultValue
			editor.setCIColorControl(with: key)
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
	
	private func drawVerticalSliders(for filter: MultiSliderFilterControl) -> some View {
		GeometryReader { geometry in
			HStack {
				ForEach(0..<filter.tunableFactors, id: \.self) {
					VSlider(value: binding(
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
	
	private func binding(to multiSliderControl: MultiSliderFilterControl, at index: Int) -> Binding<CGFloat> {
		switch multiSliderControl {
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
			case .outline:
				return Binding<CGFloat> {
					if index == 0 {
						return editingState.outlineControl.bias
					}else {
						return editingState.outlineControl.weight
					}
				} set: {
					if index == 0 {
						editingState.outlineControl.bias = $0
					}else {
						editingState.outlineControl.weight = $0
					}
					editor.setOutline()
				}
		}
	}
	
	private func drawLUTControl(for LUTFilter: LUTFilterControl) -> some View {
		HStack (spacing: 30) {
			ForEach(LUTFilter.luts.enumerated().sorted(by: { lhs, rhs in
				lhs.element < rhs.element
			}), id: \.element) { filter in
				Button("\(LUTFilter.lutCode)\(filter.offset)") {
					editor.setLutCube(filter.element)
				}
			}
		}
		.padding(.vertical, 20)
	}
	
	private func drawControls(for filter: AngleAndSliderFilterControl) -> some View {
		GeometryReader { geometry in
			HStack {
				ForEach(0..<filter.scalarFactorCount) { index in
					VSlider(value: binding(to: filter, at: index),
							in: filter.getRange(for: index),
							step: 0.02,
							sliderSize: .init(width: geometry.size.width * 0.25,
											  height: geometry.size.height * 0.8 ))
				}
				CircularSlider(
					anglesAndRadius: $editingState.glitterAnglesAndRadius,
					handleValueChanged: editor.setGlitter,
					displayCallback: { pair in
						[]
					}, backgroundView: Color(.lightGray)) { size in
					Image(systemName: "plus.circle")
						.resizable()
						.renderingMode(.template)
						.foregroundColor(.white)
						.frame(width: size.width, height: size.height)
						.background(Color.black)
						.clipShape(Circle())
				}
			}
			.frame(width: geometry.size.width, height: geometry.size.height)
		}
	}
	
	private func binding(to filter: AngleAndSliderFilterControl, at index: Int) -> Binding<CGFloat> {
		switch filter {
			case .glitter:
				return Binding<CGFloat> {
					1 - editingState.thresholdBrightness
				} set: {
					editingState.thresholdBrightness =  1 - $0
					editor.setGlitter()
				}
		}
	}
	
	struct Constant {
		static let verticalPadding: CGFloat = 30
	}
}
