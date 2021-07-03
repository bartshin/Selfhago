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
	
	private lazy var kernel: CIKernel = {
		let data = CIFilter.metalLibData
		let kernelName = "selectiveBrightness"
		if let kernel = try? CIKernel(functionName: kernelName, fromMetalLibraryData: data) {
			return kernel
		}else {
			assertionFailure("Fail to find \(kernelName)")
			return CIKernel()
		}
	}()
	
	private var inputImage: CIImage?
	private var red = emptyValues
	private var green = emptyValues
	private var blue = emptyValues
	private var averageLumiance: Float = 0.5
	private let brightnessRange: (dark: CGFloat, shadow: CGFloat, highlight: CGFloat, white: CGFloat) = (0.1, 0.4, 0.7, 1.0)
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey {
			inputImage = value as? CIImage
		}
	}
	
	func setBrightness(for component: FilterParameter.RGBColor,
					   values: [FilterParameter.Threshold: CGFloat],
					   with averageLumiance: Float) {
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
			x: max(brightnessRange.dark + intercept, 0.05),
			y: brightnessRange.shadow + intercept,
			z: brightnessRange.highlight + intercept,
			w: min(brightnessRange.white + intercept, 0.9))
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
}
