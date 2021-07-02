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
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey {
			inputImage = value as? CIImage
		}
	}
	
	func setBrightness(for component: FilterParameter.RGBColor,
					   values: [FilterParameter.Threshold: CGFloat]) {
		let selectedValues: [CGFloat] = [values[.black] ?? 0, values[.shadow] ?? 0, values[.highlight] ?? 0, values[.white] ?? 0]
	
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
			CIVector(x: $0[0] + 1,
					 y: $0[1] + 1,
					 z: $0[2] + 1,
					 w: $0[3] + 1)
		}
		return kernel.apply(
			extent: input.extent,
			roiCallback: { index, rect in
				rect
			},
			arguments: [input,
						vectorValues[0],
						vectorValues[1],
						vectorValues[2]
			])
	}
}
