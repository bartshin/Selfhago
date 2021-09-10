//
//  ColorDropper.swift
//  Note_iOS_SwiftUI
//
//  Created by bart Shin on 2021/08/22.
//

import SwiftUI

struct ColorDropper: View {
	@State private var mignifyingImage: UIImage?
	@Binding  var location: CGPoint?
	let frame: CGRect
	let selectColor: (UIColor) -> Void
	let size = CGSize(width: 20, height: 20)
	let scale: CGFloat = 2
	
	var position: CGPoint {
		if let location = location {
			return CGPoint(x: location.x - size.width * 1.5, y: location.y - size.height * 1.5 - frame.minY)
		}else {
			return .zero
		}
	}
	
	var body: some View {
		ZStack {
			if mignifyingImage != nil {
				Image(uiImage: mignifyingImage!)
					.scaleEffect(scale)
				Circle()
					.stroke(Color.white)
					.frame(width: size.width * scale,
						   height: size.height * scale)
				Rectangle()
					.stroke(Color.white)
					.frame(width: 5, height: 5)
			}
		}
		.frame(width: size.width * scale,
			   height: size.height * scale)
		.clipShape(Circle())
		.position(position)
		.onChange(of: location) { newValue in
			if let location = newValue {
				let rect = CGRect(origin:
									CGPoint(x: location.x - size.width/2,
											y: location.y - size.height/2),
								  size: size)
				mignifyingImage = UIApplication.shared.windows[0].rootViewController?.view.asImage(rect: rect)
			}else {
				selectColor(mignifyingImage!.centerPixelColor)
				mignifyingImage = nil
			}
		}
	}
	init(location: Binding<CGPoint?>, frame: CGRect, selectColor: @escaping (UIColor) -> Void) {
		_location = location
		self.frame = frame
		self.selectColor = selectColor
	}
}


extension UIView {
	fileprivate func asImage(rect: CGRect) -> UIImage {
		let renderer = UIGraphicsImageRenderer(bounds: rect)
		return renderer.image { rendererContext in
			layer.render(in: rendererContext.cgContext)
		}
	}
}

extension UIImage {
	
	var centerPixelColor: UIColor {
		let size = CGSize(width: cgImage!.width,
						  height: cgImage!.height)
		let center: CGPoint = CGPoint(x: size.width/2, y: size.height/2)
		
		let pixelData = cgImage!.dataProvider!.data
		
		let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
		let sampleSize = 2
		
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var pixelCount = 0
		for i in -sampleSize..<sampleSize {
			for j in -sampleSize..<sampleSize {
				let pixelIndex = ((Int(size.width) * (Int(center.y) + j)) + Int(center.x) + i) * 4
				r += CGFloat(data[pixelIndex]) / 255
				g += CGFloat(data[pixelIndex+1]) / 255
				b += CGFloat(data[pixelIndex+2]) / 255
				pixelCount += 1
			}
		}
	
		
		return UIColor(red: r / CGFloat(pixelCount), green: g / CGFloat(pixelCount), blue: b / CGFloat(pixelCount), alpha: 1)
	}
}

