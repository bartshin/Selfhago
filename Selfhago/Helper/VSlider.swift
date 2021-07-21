//
//  VSlider.swift
//  moody
//
//  Created by bart Shin on 30/06/2021.
//

import SwiftUI

struct VSlider<T: BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
	var value: Binding<T>
	var range: ClosedRange<T>
	var step: T?
	var sliderSize: CGSize?
	
	var body: some View {
		horizontalSlider
			.frame(width: sliderSize?.height)
			.rotationEffect(.degrees(-90))
			.frame(width: sliderSize?.width)
	}
	
	private var horizontalSlider: some View {
		if step == nil {
			return Slider(value: value, in: range)
		}
		else {
			return Slider(value: value, in: range, step: T.Stride(step!))
		}
	}
	
	init(value: Binding<T>, in range: ClosedRange<T>, step: T? = nil, sliderSize: CGSize? = nil) {
		self.value = value
		self.range = range
		self.step = step
		self.sliderSize = sliderSize
	}
}

struct VSlider_Previews: PreviewProvider {
	
    static var previews: some View {
		VSlider(value: .constant(0.5), in: 0...1, step: 0.05)
    }
}
