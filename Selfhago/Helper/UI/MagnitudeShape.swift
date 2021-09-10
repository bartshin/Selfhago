//
//  MagnitudeShape.swift
//  MagnitudeShape
//
// Aubree Quiroz
// https://betterprogramming.pub/reusable-components-in-swiftui-custom-sliders-8c115914b856

import SwiftUI

struct MagnitudeChart<T>: Shape where T: BinaryFloatingPoint {
	var values: [T]
	func path(in rect: CGRect) -> Path {
		
		var path = Path()
		path.move(to: rect.origin)
		for (index,value) in values.enumerated() {
			let padding = rect.height*(1-CGFloat(value))
			let barWidth: CGFloat = 3
			let spacing = (rect.width - barWidth*CGFloat(values.count))/CGFloat(values.count - 1)
			let barRect = CGRect(x: (CGFloat(barWidth)+spacing)*CGFloat(index),
								 y: rect.origin.y + padding*0.5,
								 width: barWidth,
								 height: rect.height - padding)
			path.addRoundedRect(in: barRect, cornerSize: CGSize(width:1, height: 1))
		}
		let bounds = path.boundingRect
		let scaleX = rect.size.width/bounds.size.width
		let scaleY = rect.size.height/bounds.size.height
		return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
	}
}

struct MagnitudeChart_Previews: PreviewProvider {
	
	static var values: [Double] =  [0, 0.2, 0.4, 0.1, 0.3, 0.5, 0.4, 0.3, 0.1, 0.3, 0.4, 0.5, 0.7, 0.9, 0.7, 0.9, 0.5, 0.3, 0.4, 0.7, 0.6, 0.3, 0.2, 0.3, 0.4, 0.5, 0.2, 0.3, 0.1, 0.1, 0]
	static var previews: some View {
		MagnitudeChart(values: values)
			.stroke(Color.blue)
			.frame(height: 100)
	}
}
