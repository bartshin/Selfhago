//
//  Kuwahara.swift
//  Selfhago
//
//  Created by bart Shin on 22/07/2021.
//

import CoreImage

class Kuwahara: CIFilter {
	
	private var inputImage: CIImage?
	private var radius: CGFloat = 0
	private lazy var kernel = findKernel("kuwahara")
		
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey{
			inputImage = value as? CIImage
		}
		else if key == kCIInputRadiusKey,
				let radius = value as? CGFloat{
			self.radius = radius
		}
	}
	
	override func value(forKey key: String) -> Any? {
		if key == kCIInputRadiusKey {
			return radius
		}
		else {
			return nil
		}
	}
	
	override var outputImage: CIImage?{
		guard let input = inputImage else { return nil}
		if radius == 0 {
			return input
		}
		return kernel.apply(extent: input.extent,
					 roiCallback: { index, rect in
						rect
					 },
					 arguments: [
						input,
						radius
					 ])
		
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterName: String(describing: Self.self)
		]
	}
	
}
