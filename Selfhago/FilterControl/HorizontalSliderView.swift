//
//  HorizontalSliderView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/05.
//

import SwiftUI

struct HorizontalSliderView<T>: ControlView where T: BinaryFloatingPoint{
	
	let title: String
	/// Normalize value in 0...1
	private var normalizedValue: Binding<CGFloat>
	
    var body: some View {
		VStack (alignment: .leading) {
			Text(title)
				.font(Constant.titleFont)
			Slider(value: normalizedValue, in: 0...1) {
				Text(title)
			}
		}
    }
	
	init(title: String, value: Binding<T>, in range: ClosedRange<T>, onValueChange: @escaping () -> Void = {}) {
		self.title = title
		self.normalizedValue = Binding<CGFloat> {
			CGFloat(Self.normalizeValue(value.wrappedValue, in: range))
		} set: { newValue in
			value.wrappedValue = Self.deNormalizeValue(T(newValue), in: range)
			onValueChange()
		}
	}
}

fileprivate struct Constant {
	static let titleFont: Font = DesignConstant.getFont(.init(family: .NotoSansCJKkr, style: .Regular), size: 17)
}

struct HorizontalSliderView_Previews: PreviewProvider {
	@State static var value: CGFloat = 0.5
    static var previews: some View {
		HorizontalSliderView(title: "Brightness", value: $value, in: 0...1)
    }
}
