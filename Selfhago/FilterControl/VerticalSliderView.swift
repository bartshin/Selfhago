//
//  VerticalSliderView.swift
//  iOS
//
//  Created by bart Shin on 2021/08/05.
//

import SwiftUI

struct VerticalSliderView<T>: ControlView where T: BinaryFloatingPoint{
	
	private let title: String
	private let drawGraph: Bool
	private let numberOfSliders: Int
	private let ranges: [ClosedRange<T>]
	private var bindingValues: [Binding<T>]
	private let onValueChanging: (Int) -> Void
	private let horizontalMargin: CGFloat
	
    var body: some View {
		VStack (alignment: .leading, spacing: 14) {
			Text(title)
				.font(Constant.titleFont)
			GeometryReader { geometry in
				ZStack {
					if drawGraph {
						CurveGraph(points: getAllPoints(in: geometry.size))
							.size(geometry.size)
							.stroke(Constant.graphColor, lineWidth: 2)
					}
					Group {
						ForEach(0..<numberOfSliders, id: \.self) { index in
							drawSlider(at: index, in: geometry.size)
								.position(x: calcXPotionOfSlider(at: index, in: geometry.size),
										  y: geometry.size.height / 2)
						}
					}
				}
			}
		}
	}
	
	private func getAllPoints(in size: CGSize) -> [CGPoint] {
		let marginBetweenSliders = calcMarginBetweenSliders(in: size)
		let normalizedValues = bindingValues.enumerated().map { index, value in
			CGFloat(Self.normalizeValue(value.wrappedValue, in: ranges[index]))
		}
		return normalizedValues.enumerated().map {
			CGPoint(x: (horizontalMargin + marginBetweenSliders * CGFloat($0.offset)) / size.width,
					y: 1 - $0.element)
		}
	}
	
	private func drawSlider(at index: Int, in size: CGSize) -> some View {
		ZStack (alignment: .bottom) {
			RoundedRectangle(cornerRadius: 10)
				.size(width: Constant.sliderWidth,
					  height: size.height)
				.fill(Constant.sliderBackgroundColor)
			RoundedRectangle(cornerRadius: 10, style: .circular)
				.fill(Constant.sliderForegroundColor)
				.frame(height: calcHeightOfSlider(at: index, in: size))
		}
		.frame(width: Constant.sliderWidth,
			   height: size.height)
		.gesture(createGesture(for: index, in: size))
	}
	
	private func createGesture(for index: Int, in size: CGSize) -> some Gesture {
		DragGesture(minimumDistance: size.height / 10)
			.onChanged { value in
				let ratio = max(0, min(1 - value.location.y / size.height, 1))
				setValueToBinding(ratio, at: index)
				onValueChanging(index)
			}
	}
	
	private func calcHeightOfSlider(at index: Int, in size: CGSize) -> CGFloat {
		let value = CGFloat(Self.normalizeValue(bindingValues[index].wrappedValue, in: ranges[index]))
		return min(max(size.height * value, 0), size.height)
	}
	

	private func calcXPotionOfSlider(at index: Int, in size: CGSize) -> CGFloat {
		return horizontalMargin + calcMarginBetweenSliders(in: size) * CGFloat(index)
	}
	
	private func calcMarginBetweenSliders(in size: CGSize) -> CGFloat {
		(size.width - CGFloat(numberOfSliders) * Constant.sliderWidth - horizontalMargin * 2) / CGFloat(numberOfSliders - 1)
	}
	
	private func getNormalizedValue(at index: Int) -> CGFloat {
		CGFloat(Self.normalizeValue(bindingValues[index].wrappedValue, in: ranges[index]))
	}
	
	private func setValueToBinding(_ value: CGFloat, at index: Int) {
		bindingValues[index].wrappedValue = Self.deNormalizeValue(T(value), in: ranges[index])
	}
	
	init(title: String,
		 values: [Binding<T>],
		 ranges: [ClosedRange<T>],
		 drawGraph: Bool,
		 onValueChanging: @escaping (Int) -> Void = {_ in},
		 onValueChanged: @escaping (Int) -> Void = {_ in}) {
		self.title = title
		self.numberOfSliders = values.count
		self.ranges = ranges
		self.bindingValues = values
		self.drawGraph = drawGraph
		self.onValueChanging = onValueChanging
		horizontalMargin = Constant.sliderHMargin * pow(CGFloat(5) / CGFloat(numberOfSliders), 2.5)
	}
}

class Values: ObservableObject {
	let numberOfSliders = 5
	var mainValue: CGFloat = 0.5
	var values: [CGFloat] = [
		4,
		2,
		4,
		2,
		1
	]
	let ranges: [ClosedRange<CGFloat>] = [
		0...10,
		1...5.5,
		0...10,
		1...5.5,
		1...2
	]
}
fileprivate struct Constant {
	static let titleFont: Font = .title3
	static let sliderWidth: CGFloat = 4
	static let sliderBackgroundColor: Color = Color(.lightGray).opacity(0.4)
	static let sliderForegroundColor: Color = .blue
	static let graphColor: Color = .blue.opacity(0.5)
	static let sliderHMargin: CGFloat = 12
}

 struct VerticalSliderView_Previews: PreviewProvider {
	@StateObject static var values = Values()
    static var previews: some View {
		VStack {
			VerticalSliderView(title: "Brightness(Advanced)",
							   values: (0..<2).map({ index in
								$values.values[index]
							   }),
							   ranges: values.ranges,
							   drawGraph: true
			)
			.frame(width: /*@START_MENU_TOKEN@*/375.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/140.0/*@END_MENU_TOKEN@*/)
			VerticalSliderView(title: "Brightness(Advanced)",
							   values: (0..<3).map({ index in
								$values.values[index]
							   }),
							   ranges: values.ranges,
							   drawGraph: true
			)
			.frame(width: /*@START_MENU_TOKEN@*/375.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/140.0/*@END_MENU_TOKEN@*/)
		}
    }
}
