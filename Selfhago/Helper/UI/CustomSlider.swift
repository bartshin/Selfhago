//
//  CustomSlider.swift
//  CustomSlider
//
// Aubree Quiroz
// https://betterprogramming.pub/reusable-components-in-swiftui-custom-sliders-8c115914b856

import SwiftUI

struct CustomSliderComponents {
	let barLeft: CustomSliderModifier
	let barRight: CustomSliderModifier
	let knob: CustomSliderModifier
}

struct CustomSliderModifier: ViewModifier {
	enum Name {
		case barLeft
		case barRight
		case knob
	}
	let name: Name
	let size: CGSize
	let offset: CGFloat
	
	func body(content: Content) -> some View {
		content
			.frame(width: size.width)
			.position(x: size.width*0.5, y: size.height*0.5)
			.offset(x: offset)
	}
}

struct CustomSlider<Component: View, T>: View where T: BinaryFloatingPoint{
	
	@Binding var value: T
	var range: ClosedRange<T>
	var knobWidth: CGFloat?
	let viewBuilder: (CustomSliderComponents) -> Component
	
	var body: some View {
		GeometryReader { geometry in

			ZStack {
				viewBuilder(createModifiers(in: geometry))
					.gesture(
						DragGesture(minimumDistance: 0)
							.onChanged {
								onDragChange(dragValue: $0, size: geometry.size)
							}
					)
			}
		}
	}
	
	private func createModifiers(in geometry: GeometryProxy) -> CustomSliderComponents {
		let frame = geometry.frame(in: .global)
		let offsetX = getOffsetX(frame: frame)
		
		let knobSize = CGSize(width: knobWidth ?? frame.height, height: frame.height)
		let barLeftSize = CGSize(width: CGFloat(offsetX + knobSize.width * 0.5), height:  frame.height)
		let barRightSize = CGSize(width: frame.width - barLeftSize.width, height: frame.height)
		
		return CustomSliderComponents(
			barLeft: CustomSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
			barRight: CustomSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width),
			knob: CustomSliderModifier(name: .knob, size: knobSize, offset: offsetX))
	}
	
	private func onDragChange(dragValue: DragGesture.Value, size: CGSize) {
		let width = (knob: Double(knobWidth ?? size.height), view: Double(size.width))
		let xrange = T(0)...T(width.view - width.knob)
		var value = T(dragValue.startLocation.x + dragValue.translation.width) // knob center x
		value -= 0.5*T(width.knob) // offset from center to leading edge of knob
		value = max(min(value, xrange.upperBound), xrange.lowerBound)
		value = convert(value: value, fromRange: xrange, toRange: range)
		self.value = value
	}
	
	private func convert<T>(value: T, fromRange: ClosedRange<T>, toRange: ClosedRange<T>) -> T where T: BinaryFloatingPoint {
		// Example: if self = 1, fromRange = (0,2), toRange = (10,12) -> solution = 11
		var value = value
		value -= fromRange.lowerBound
		value /= (fromRange.upperBound - fromRange.lowerBound)
		value *= toRange.upperBound - toRange.lowerBound
		value += toRange.lowerBound
		return value
	}
	
	private func getOffsetX(frame: CGRect) -> CGFloat {
		let width = (knob: knobWidth ?? frame.size.height, view: frame.size.width)
		let xrange = 0...T(width.view - width.knob)
		let result = convert(value: value, fromRange: range, toRange: xrange)
		return CGFloat(result)
	}
	
	init(value: Binding<T>, range: ClosedRange<T>, knobWidth: CGFloat? = nil,
		 _ viewBuilder: @escaping (CustomSliderComponents) -> Component
	) {
		_value = value
		self.range = range
		self.viewBuilder = viewBuilder
		self.knobWidth = knobWidth
	}
}
