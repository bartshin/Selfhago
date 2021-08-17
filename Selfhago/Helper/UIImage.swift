//
//  UIImageAlpha.swift
//  Selfhago
//
//  Created by bart Shin on 02/07/2021.
//

import UIKit

extension UIImage {
	func withAlpha(_ alpha: CGFloat) -> UIImage {
		if alpha == 1 {
			return self
		}
		return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { (_) in
			draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: alpha)
		}
	}
}

extension UIImage.Orientation {
	var cgOrientation: CGImagePropertyOrientation {
		let cgiOrientations : [ CGImagePropertyOrientation ] = [
			.up, .down, .left, .right, .upMirrored, .downMirrored, .leftMirrored, .rightMirrored
		]
		return cgiOrientations[self.rawValue]
	}
}
