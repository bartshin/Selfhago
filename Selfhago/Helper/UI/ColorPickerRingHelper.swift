//
//  ColorExtension.swift
//  ColorPickerRing
//
//  Created by Hendrik Ulbrich on 16.07.19.
//

import SwiftUI
import DynamicColor

extension Angle {
	var color: DynamicColor {
		DynamicColor(hue: CGFloat(self.radians / (2 * .pi)), saturation: 1, brightness: 1, alpha: 1)
	}
	
	func swiftUIColor(for alpha: CGFloat) -> Color {
		Color(DynamicColor(hue: CGFloat(self.radians / (2 * .pi)), saturation: 1, brightness: 1, alpha: alpha))
	}
}

extension DynamicColor {
	var angle: Angle {
		Angle(radians: Double(2 * .pi * self.hueComponent))
	}
}

extension AngularGradient {
	static func createConic(for alpha: CGFloat) -> AngularGradient {
		AngularGradient(gradient: Gradient.wheelSpectrum(for: alpha), center: .center, angle: .degrees(-90))
	}
}

extension Gradient {
	static func wheelSpectrum(for alpha: CGFloat) -> Gradient {
		Gradient(colors: [
			Angle(radians: 3/6 * .pi).swiftUIColor(for: alpha),
			
			Angle(radians: 2/6 * .pi).swiftUIColor(for: alpha),
			Angle(radians: 1/6 * .pi).swiftUIColor(for: alpha),
			Angle(radians: 12/6 * .pi).swiftUIColor(for: alpha),
			
			Angle(radians: 11/6 * .pi).swiftUIColor(for: alpha),
			
			Angle(radians: 10/6 * .pi).swiftUIColor(for: alpha),
			Angle(radians: 9/6 * .pi).swiftUIColor(for: alpha),
			Angle(radians: 8/6 * .pi).swiftUIColor(for: alpha),
			
			Angle(radians: 7/6 * .pi).swiftUIColor(for: alpha),
			
			Angle(radians: 6/6 * .pi).swiftUIColor(for: alpha),
			Angle(radians: 5/6 * .pi).swiftUIColor(for: alpha),
			Angle(radians: 4/6 * .pi).swiftUIColor(for: alpha),
			
			Angle(radians: 3/6 * .pi).swiftUIColor(for: alpha),
		])
	}
}

