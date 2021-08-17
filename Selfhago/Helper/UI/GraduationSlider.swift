//
//  GraduationSlider.swift
//  iOS
//
//  Created by bart Shin on 2021/08/13.
// 

import SwiftUI

struct GraduationSlider<T>: View where T: BinaryFloatingPoint{
	
	@Binding var bindingValue:T
	@State private var value: T
	@State private var range: ClosedRange<T>
	private let step: T
	private let ratio: T
	private var width: T {
		range.upperBound - range.lowerBound
	}
	var body: some View {
		GeometryReader { geometry in
			let frame = geometry.frame(in: .local)
			let offset = -CGFloat(value) * frame.width/CGFloat(width) * 2
			ZStack {
				GraduationRuler(step: step, range: range)
					.stroke(drawGradient(for: offset, in: geometry.size.width))
					.frame(width: geometry.size.width, height: geometry.size.height)
					.offset(x: offset)
				Rectangle()
					.fill(Color.red)
					.frame(width: 2, height: geometry.size.height)
					.position(x: frame.midX, y: frame.midY)
			}
			.gesture(dragGesture)
			.onChange(of: bindingValue) { newValue in
				let offset = newValue - value
				if abs(offset) >= width {
					value = newValue
					range = range.lowerBound + offset ... range.upperBound + offset
				}
			}
		}
	}
	
	private func drawGradient(for offset: CGFloat, in width: CGFloat) -> LinearGradient {
		return LinearGradient(
			gradient: Gradient(
				colors: [.black.opacity(0.3), .black.opacity(0.6), .black, .black.opacity(0.6), .black.opacity(0.3)]),
			startPoint: .init(x: -offset/width, y: 0), endPoint: .init(x: (width - offset)/width, y: 0))
	}
	
	
	@State private var translationX: CGFloat = 0
	private var dragGesture: some Gesture {
		DragGesture()
			.onChanged { dragValue in
				let translation = dragValue.translation
				let offset = T(translationX - translation.width)
				guard abs(offset) > step else {
					return
				}
				withAnimation {
					value = ((value + offset * ratio) * 10).rounded(.toNearestOrAwayFromZero) / 10
					value = min(max(range.lowerBound, value), range.upperBound)
				}
				translationX = translation.width
				bindingValue = value
			}
			.onEnded { dragValue in
				let endTranslation = dragValue.predictedEndTranslation
				let offset = T(translationX - endTranslation.width)
				let normalizedOffset = (value + offset * ratio * ratio * 10).rounded(.toNearestOrAwayFromZero) / 10
				translationX = 0
				guard abs(normalizedOffset) > width/5 else {
					return
				}
				withAnimation (.easeOut(duration: 0.5)) {
					value = min(max(range.lowerBound, value + normalizedOffset), range.upperBound)
				}
				bindingValue = value
			}
	}
	
	init(bindingTo value: Binding<T>, range: T, step: T, width: CGFloat) {
		_bindingValue = value
		_value = State<T>(initialValue: value.wrappedValue)
		_range = State<ClosedRange<T>>(initialValue: value.wrappedValue - range...value.wrappedValue + range)
		self.step = step
		self.ratio = T(min(0.3, width/UIScreen.main.bounds.width))
	}
}

struct GraduationSlider_Previews: PreviewProvider {
	
    static var previews: some View {
		GraduationSlider(bindingTo: .constant(CGFloat(0.5)), range: 30, step: 0.5, width: 300)
			.frame(width: 300, height: 20)
			.border(Color.red)
    }
}
