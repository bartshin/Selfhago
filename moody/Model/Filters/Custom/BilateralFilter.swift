//
//  BilateralFilter.swift
//  moody
//
//  Created by bart Shin on 04/07/2021.
//

import CoreImage

class BilateralFilter: CIFilter {
	
	private var sigmaRangeBlur: Float = 15.0
	private var sigmaSpatial: Float = 0.2
	
	private lazy var kernel: CIKernel = {
		let data = CIFilter.metalLibData
		let kernelName = "bilateral"
		if let kernel = try? CIKernel(functionName: kernelName, fromMetalLibraryData: data) {
			return kernel
		}else {
			assertionFailure("Fail to find \(kernelName)")
			return CIKernel()
		}
	}()
	
	
	private var inputImage: CIImage?
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey {
			inputImage = value as? CIImage
		}
	}
	
	override var outputImage: CIImage? {
		guard let input = inputImage else {
			assertionFailure("Input image is missing")
			return nil
		}
		
		return kernel.apply(
			extent: input.extent,
			roiCallback: { index, rect in
				rect
			},
			arguments: [input,
						sigmaRangeBlur,
						sigmaSpatial
			])
	}
}
