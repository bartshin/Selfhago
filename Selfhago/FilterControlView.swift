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
		
		if let colorControl = currentCategory.control as? SingleSliderFilterControl {
			drawSlider(for: colorControl)
		}else if currentCategory.control is DrawableFilterControl{
			blurmaskControlSlider
		}else if let onOffFilter = currentCategory.control as? OnOffFilter {
			drawControl(for: onOffFilter)
		}else if let multiSliderFilter = currentCategory.control as? MultiSliderFilterControl {
			drawVerticalSliders(for: multiSliderFilter)
		}else if let angleAndSliderFilter = currentCategory.control as? AngleAndSliderFilterControl {
			drawControls(for: angleAndSliderFilter)
		}
	}
	
	private func drawSlider(for control: SingleSliderFilterControl) -> some View {
		VStack {
			Slider(value: binding(to: control, with: control.rawValue),
				   in: control.getRange(),
				   step: 0.01)
				.disabled(control == .backgroundTone && (!editingState.depthDataAvailable || editor.materialImage == nil))
			drawDetailConfigPanel(for: control)
				.layoutPriority(1)
		}
		.padding(.top, control.hasAdditionalControl ? 0: Constant.verticalPadding)
	}
	
	private func drawDetailConfigPanel(for control: SingleSliderFilterControl) -> some View {
		Group {
			if control == .brightness {
				drawVerticalSliders(for: .rgb)
			}
			else if control == .saturation {
				rgbControlPanel
			}
		}
	}
	
	@State private var currentComponent: MultiSliderFilterControl = .red
	private var rgbControlPanel: some View {
		HStack {
			VStack {
				ForEach([MultiSliderFilterControl.red, .blue, .green], id: \.rawValue) {
					drawRgbSelectButton(for: $0)
				}
			}
			drawVerticalSliders(for: currentComponent)
		}
	}
	
	private func drawRgbSelectButton(for component: MultiSliderFilterControl) -> some View {
		Button {
			withAnimation {
				currentComponent = component
			}
		} label: {
			Text("\(component.rawValue.first!.uppercased())")
		}
	}
	
	
	private var selectedFont: Font {
		Font(UIFont(descriptor: editingState.control.textStampFont.descriptor,
					size: editingState.control.textStampFont.fontSize) as CTFont)
	}
	
	private func binding(to control: SingleSliderFilterControl, with key: String) -> Binding<CGFloat>{
		switch control {
			case .brightness, .saturation, .contrast:
				return Binding<CGFloat>  {
					editingState.control.colorControl[control]! - control.defaultValue
				} set: {
					editingState.control.colorControl[control] = $0 + control.defaultValue
					editor.setCIColorControl(with: key)
				}
			case .painter:
				return Binding<CGFloat> {
					editingState.control.painterRadius
				} set: {
					editingState.control.painterRadius = $0
					editor.setPainter()
				}
			case .backgroundTone:
				return Binding<CGFloat> {
					editingState.control.depthFocus
				} set:  {
					editingState.control.depthFocus = $0
					editor.setBackgroundToneRetouch()
				}
		}
		
	}
	
	private var blurmaskControlSlider: some View {
		VStack {
			HStack {
				Text("강도")
				Slider(value: Binding<CGFloat> {
					editingState.control.blurIntensity
				} set: {
					editingState.control.blurIntensity = $0
				}, in: 0...20, step: 1)
			}
			HStack {
				Text("범위")
				Slider(value:Binding<CGFloat> {
					editingState.control.blurMaskWidth
				} set: {
					editingState.control.blurMaskWidth = $0
				}, in: 10...60, step: 5)
			}
		}
		.padding(.top, Constant.verticalPadding)
	}
	
	private func drawControl(for onOffFilter: OnOffFilter ) -> some View {
		HStack (spacing: 30) {
			if let luts = onOffFilter.luts?.enumerated().sorted(by: { lhs, rhs in
				lhs.element < rhs.element
			}) {
				ForEach(luts, id: \.element) { lut in
					Button("\(onOffFilter.lutCode!)\(lut.offset)") {
						editor.setLutCube(lut.element)
					}
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
					anglesAndRadius: $editingState.control.glitterAnglesAndRadius,
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
					1 - editingState.control.thresholdBrightness
				} set: {
					editingState.control.thresholdBrightness =  1 - $0
					editor.setGlitter()
				}
		}
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
				if filter == .textStamp {
					TextConfigPanel()
						.layoutPriority(1)
				}
			}
			.frame(width: geometry.size.width, height: geometry.size.height)
		}
	}
	
	private func binding(to multiSliderControl: MultiSliderFilterControl, at index: Int) -> Binding<CGFloat> {
		switch multiSliderControl {
			
			case .bilateral:
				return Binding<CGFloat> {
					index == 0 ? editingState.control.bilateralControl.radius:
						editingState.control.bilateralControl.intensity
				}set: {
					if index == 0 {
						editingState.control.bilateralControl.radius = $0
					}else {
						editingState.control.bilateralControl.intensity = $0
					}
					editor.setBilateral()
				}
			case .vignette:
				return Binding<CGFloat> {
					if index == 0 {
						return editingState.control.vignetteControl.radius
					}
					else if index == 1 {
						return editingState.control.vignetteControl.intensity
					}
					else {
						return editingState.control.vignetteControl.edgeBrightness
					}
				}set: {
					if index == 0 {
						editingState.control.vignetteControl.radius = $0
					}
					else if index == 1 {
						editingState.control.vignetteControl.intensity = $0
					}
					else {
						editingState.control.vignetteControl.edgeBrightness = $0
					}
					editor.setVignette()
				}
			case .outline:
				return Binding<CGFloat> {
					if index == 0 {
						return editingState.control.outlineControl.bias
					}else {
						return editingState.control.outlineControl.weight
					}
				} set: {
					if index == 0 {
						editingState.control.outlineControl.bias = $0
					}else {
						editingState.control.outlineControl.weight = $0
					}
					editor.setOutline()
				}
			case .textStamp:
				return Binding<CGFloat> {
					if index == 0 {
						return editingState.control.textStampControl.radius
					}else {
						return editingState.control.textStampControl.lensScale
					}
				}set: {
					if index == 0 {
						editingState.control.textStampControl.radius = $0
					}else {
						editingState.control.textStampControl.lensScale = $0
					}
				}
			case .rgb:
				return Binding<CGFloat> {
					var value: CGFloat = 0
					ColorChannel.InputParameter.Component.allCases.forEach {
						value += editingState.control.colorChannelControl[$0]![index]
					}
					return value/3 // Average of rgb
				} set: { value in
					ColorChannel.InputParameter.Component.allCases.forEach { component in
						editingState.control.colorChannelControl[component]![index] = value
					}
					editor.setColorChannel()
				}
			case .red:
				return Binding<CGFloat> {
					return editingState.control.colorChannelControl[.red]![index]
				} set: { value in
					editingState.control.colorChannelControl[.red]![index] = value
					editor.setColorChannel()
				}
			case .green:
				return Binding<CGFloat> {
					return editingState.control.colorChannelControl[.green]![index]
				} set: { value in
					editingState.control.colorChannelControl[.green]![index] = value
					editor.setColorChannel()
				}
			case .blue:
				return Binding<CGFloat> {
					return editingState.control.colorChannelControl[.blue]![index]
				} set: { value in
					editingState.control.colorChannelControl[.blue]![index] = value
					editor.setColorChannel()
				}
		}
	}
	
	struct Constant {
		static let verticalPadding: CGFloat = 30
	}
}
