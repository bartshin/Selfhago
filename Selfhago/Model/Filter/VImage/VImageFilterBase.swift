//
//  VImageFilters.swift
//  Filterpedia
//
//  Created by Simon Gladman on 21/04/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
// These filters don't work nicely in background threads! Execute in dispatch_get_main_queue()!
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>
import CoreImage
import Accelerate


// MARK Support
protocol VImageFilter: CIFilter {
	var inputImage: CGImage? { get set }
	var ciContext: CIContext! { get set }
	var sourceBuffer: vImage_Buffer? { get set }
	var outputCGImage: CGImage? { get }
}

extension vImage {
	static var cgImageFormat8888: vImage_CGImageFormat {
		let bitmapInfo:CGBitmapInfo = CGBitmapInfo(
			rawValue: CGImageAlphaInfo.last.rawValue)
		return vImage_CGImageFormat(
			bitsPerComponent: 8,
			bitsPerPixel: 32,
			colorSpace: nil,
			bitmapInfo: bitmapInfo,
			version: 0,
			decode: nil,
			renderingIntent: .defaultIntent)
	}
}

extension VImageFilter {
	
	func createSourceBufferFromCGImage(_ cgImage: CGImage, format: vImage_CGImageFormat?)
	{
		guard let format = format ?? vImage_CGImageFormat(cgImage: cgImage) else {
			return
		}
		sourceBuffer?.free()
		do {
			
			sourceBuffer = try vImage_Buffer(cgImage: cgImage,
											 format: format,
											 flags: .noFlags)
		}catch {
			print("Fail to set buffer \(error.localizedDescription)")
		}
	}
}

extension CIImage
{
	convenience init?(fromvImageBuffer: vImage_Buffer)
	{
		var mutableBuffer = fromvImageBuffer
		var error = vImage_Error()
		var format = vImage.cgImageFormat8888
		if let cgImage = vImageCreateCGImageFromBuffer(
			&mutableBuffer,
			&format,
			nil,
			nil,
			UInt32(kvImageNoFlags),
			&error) {
		
			self.init(cgImage: cgImage.takeRetainedValue())
		}else {
			return nil
		}
	}
}
