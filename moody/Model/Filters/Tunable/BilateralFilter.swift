//
//  BilateralFilter.swift
//  moody
//
//  Created by bart Shin on 04/07/2021.
//

import CoreImage

class BilateralFilter: CIFilter {
	
	static let faceRegionsKey = "faceRegionsKey"
	private let maxVetor = 10
	private var faceRegion = CIVector(x: 0, y: 0, z: 0, w: 0)
	private var spacialSigma: Float = 1.0
	private var luminaceSigma: Float = 0.1
	private var minimumDistance: Float = 1.0
	
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
		else if key == kCIInputRadiusKey,
		   let value = value as? Float{
			spacialSigma = value
		}
		else if key == kCIInputIntensityKey ,
		   let value = value as? Float{
			luminaceSigma = value
		}
		else if key == kCIInputExtentKey ,
				let size = value as? CGSize{
			let scale = max(Int(log10(size.width)), Int(log10(size.height)))
			minimumDistance = pow(0.1, Float(scale))
		}
		else if key == Self.faceRegionsKey,
				let regions = value as? [CGRect] {
			if let firstRegion = regions.sorted(by: { lhs, rhs in
				lhs.width * lhs.height > rhs.width * rhs.height
			}).first {
				faceRegion = CIVector(x: firstRegion.minX,
									   y: firstRegion.maxX,
									   z: firstRegion.minY,
									   w: firstRegion.maxY)
			}
			else {
				faceRegion = CIVector(x: 0, y: 0, z: 0, w: 0)
			}
		}
	}
	
	override var outputImage: CIImage? {
		guard let input = inputImage
		else {
			assertionFailure("Input image is missing")
			return nil
		}
		
		return kernel.apply(
			extent: input.extent,
			roiCallback: { index, rect in
				rect.insetBy(dx: 3, dy: 3)
			},
			arguments: [input,
						faceRegion,
						spacialSigma,
						luminaceSigma,
						minimumDistance
			])
	}
}
