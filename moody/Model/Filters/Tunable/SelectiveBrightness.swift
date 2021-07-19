//
//  SelectiveBrightness.swift
//  moody
//
//  Created by bart Shin on 30/06/2021.
//

import CoreImage

class SelectiveBrightness: CIFilter {
	
	typealias selectableValues = [CGFloat]
	static let emptyValues: selectableValues = [0, 0, 0, 0]
	
	private lazy var kernel: CIKernel = findKernel(by: "selectiveBrightness")
	
	private var inputImage: CIImage?
	private(set) var red = emptyValues
	private(set) var green = emptyValues
	private(set) var blue = emptyValues
	private(set) var averageLumiance: CGFloat = 0.5
	private let brightnessRange: (dark: CGFloat, shadow: CGFloat, highlight: CGFloat, white: CGFloat) = (0.0, 0.4, 0.7, 1.0)
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey {
			inputImage = value as? CIImage
		}
	}
	
	func setBrightness(for component: FilterParameter.RGBColor,
					   values: [FilterParameter.Threshold: CGFloat],
					   with averageLumiance: CGFloat) {
		let selectedValues: [CGFloat] = [values[.black] ?? 0, values[.shadow] ?? 0, values[.highlight] ?? 0, values[.white] ?? 0]
		self.averageLumiance = averageLumiance
		switch component {
			case .red:
				red = selectedValues
			case .green:
				green = selectedValues
			case .blue:
				blue = selectedValues
		}
	}
	
	override func value(forKey key: String) -> Any? {
		switch key {
			case "red":
				return red
			case "blue":
				return blue
			case "green":
				return green
			case "averageLumiance":
			return averageLumiance
			default:
				return nil
		}
	}
	
	override var outputImage: CIImage? {
		guard let input = inputImage else { return nil }
		let vectorValues = [red, green, blue].map {
			CIVector(x: $0[0],
					 y: $0[1],
					 z: $0[2],
					 w: $0[3])
		}
		let intercept = pow(CGFloat(averageLumiance) - 0.5, 3) * 10
		let ranges = CIVector(
			x: max(brightnessRange.dark + intercept, 0.0),
			y: brightnessRange.shadow + intercept,
			z: brightnessRange.highlight + intercept,
			w: min(brightnessRange.white + intercept, 1.0))
		
		return kernel.apply(
			extent: input.extent,
			roiCallback: { index, rect in
				rect
			},
			arguments: [input,
						vectorValues[0],
						vectorValues[1],
						vectorValues[2],
						ranges
			])
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterName: String(describing: Self.self)
		]
	}
	
	
	struct FilterParameter {
		
		enum Threshold: CGFloat {
			case black = 0.25
			case shadow = 0.5
			case highlight = 0.75
			case white = 1.0
		}
		
		enum RGBColor: Int, CaseIterable {
			case red
			case green
			case blue
		}
	}
}
