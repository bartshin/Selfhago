//
//  GammaAdjustment.swift
//  GammaAdjustment
//
//  Created by bart Shin on 2021/08/28.
//

import CoreImage
import Accelerate

class GammaAdjustment: CIFilter, VImageFilter {
	 
	struct Parameter: Equatable {
		var inputGamma: Float
		var exponentialCoefficients: [Float]
		var linearCoefficients: [Float]
		var linearBoundary: Float
	}
	var inputImage: CGImage?
	var sourceBuffer: vImage_Buffer?
	var ciContext: CIContext!
	private var destinationBuffer: vImage_Buffer?
	private lazy var rgbFormat: vImage_CGImageFormat = {
		vImage_CGImageFormat(bitsPerComponent: 8,
							 bitsPerPixel: 8 * 3,
							 colorSpace: CGColorSpaceCreateDeviceRGB(),
							 bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
							 renderingIntent: .defaultIntent)!
	}()
	private var parameter = Parameter(inputGamma: 1.0,
									  exponentialCoefficients: [1, 0, 0],
									  linearCoefficients: [1, 0],
									  linearBoundary: 0)
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey {
			let newImage = (value as! CGImage)
			if inputImage != newImage {
				createSourceBufferFromCGImage(newImage, format: nil)
				setDestinationBuffer()
			}
			inputImage = newImage
		}
		if key == kCIInputIntensityKey,
		   let newParameter = value as? Parameter {
			parameter = newParameter
		}
	}
	
	override func value(forKey key: String) -> Any? {
		if key == kCIInputIntensityKey {
			return parameter
		}
		return nil
	}
	
	private func setDestinationBuffer() {
		do {
			destinationBuffer = try vImage_Buffer(width: Int(sourceBuffer!.width),
												  height: Int(sourceBuffer!.height),
												  bitsPerPixel: rgbFormat.bitsPerPixel)
		}catch {
			assertionFailure("Fail to set destination buffer")
			return
		}
	}
	
	var outputCGImage: CGImage? {
		vImageConvert_RGBA8888toRGB888(&sourceBuffer!,
									   &destinationBuffer!,
									   vImage_Flags(kvImageNoFlags))
		var planarDestination = vImage_Buffer(data: destinationBuffer!.data,
											  height: destinationBuffer!.height,
											  width: destinationBuffer!.width * 3,
											  rowBytes: destinationBuffer!.rowBytes)
		vImagePiecewiseGamma_Planar8(&planarDestination,
									 &planarDestination,
									 parameter.exponentialCoefficients,
									 parameter.inputGamma,
									 parameter.linearCoefficients,
									 UInt8(parameter.linearBoundary * 255),
									 vImage_Flags(kvImageNoFlags))
		defer {
			planarDestination.free()
		}
		return try? destinationBuffer?.createCGImage(format: rgbFormat)
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterName: String(describing: Self.self)
		]
	}
	
	var valuesForCharts: [Double] {
		return stride(from: 0.1, through: 1.0, by: 0.01).compactMap { x -> Double in
			if x <= Double(parameter.linearBoundary) {
				return Double((parameter.linearCoefficients[0] * Float(x)) + parameter.linearCoefficients[1])
			}else {
				return Double(pow(parameter.exponentialCoefficients[0] * Float(x) + parameter.exponentialCoefficients[1], parameter.inputGamma) + parameter.exponentialCoefficients[2])
			}
		}
	}
}
