//
//  ColorRotateRing.swift
//  ColorRotateRing
//
//  Created by bart Shin on 2021/09/09.
//

import SwiftUI
import ColorPickerRing
import DynamicColor

struct ColorRotateRing: View {
   
	typealias ColorMap = (from: DynamicColor, to: DynamicColor)
	@Binding var colors: [ColorMap]
	@State private var rotationAngle: Angle = .zero
	
	let strokeWidth: CGFloat = 20
	
	var body: some View {
		GeometryReader { geometry in
			let frame = geometry.frame(in: .local)
			ZStack(alignment: .center) {
				// Color Gradient
				Circle()
					.strokeBorder(AngularGradient.createConic(for: 0.3),  lineWidth: strokeWidth)
					.gesture (dragColor( in: frame))
				// Color Selection Indicator
				ForEach (colors, id: \.from.angle.radians) { colorMap in
					Circle()
						.fill(Color(getRotatedColor(for: colorMap.to)))
						.frame(width: strokeWidth, height: strokeWidth, alignment: .center)
						.fixedSize()
						.allowsHitTesting(false)
						.offset(calcOffset(for: colorMap.to, in: frame))
						.overlay(
							Circle()
								.stroke(Color(colorMap.from.angle.color), lineWidth: 3)
								.offset(calcOffset(for: colorMap.to, in: frame))
								.allowsHitTesting(false)
						)
				}
			}
			.onChange(of: colors.count) { _ in
				
			}
		}
		.aspectRatio(1, contentMode: .fit)
	}
	
	private func getRotatedColor(for color: DynamicColor) -> DynamicColor {
		var angle = color.angle + rotationAngle
		while angle.radians < 0 {
			angle.radians += .pi * 2
		}
		return angle.color
	}
	
	private func calcOffset(for color: DynamicColor, in frame: CGRect) -> CGSize {
		CGSize(
			width: cos(color.angle.radians + rotationAngle.radians) * Double(frame.midX - strokeWidth / 2),
			height: -sin(color.angle.radians + rotationAngle.radians) * Double(frame.midY - strokeWidth / 2))
	}
	
	private func dragColor(in frame: CGRect) -> some Gesture {
		DragGesture()
			.onChanged { dragValue in
				let start = CGPoint(x: dragValue.startLocation.x - frame.midX,
									y: frame.midY - dragValue.startLocation.y)
				let startAngle = Angle(radians: atan2(start.y, start.x))
				let current = CGPoint(x: dragValue.location.x - frame.midX,
									  y: frame.midY - dragValue.location.y)
				let currentAngle = Angle(radians: atan2(current.y, current.x))
				rotationAngle = currentAngle - startAngle
			}
			.onEnded { dragValue in
				for (index, colorMap) in colors.enumerated() {
					colors[index].to = getRotatedColor(for: colorMap.to)
				}
				
				rotationAngle = .zero
			}
	}
}

struct ColorRotateRing_Previews: PreviewProvider {
	@State private static var colors: [(from: UIColor, to: UIColor)] = [(.blue, .blue)]
    static var previews: some View {
		ColorRotateRing(colors: $colors)
			.frame(width: 200, height: 200)
    }
}

