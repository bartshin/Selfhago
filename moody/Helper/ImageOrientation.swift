//
//  ImageOrientation.swift
//  moody
//
//  Created by bart Shin on 06/07/2021.
//

import UIKit

extension UIImage.Orientation {
	var cgOrientation: CGImagePropertyOrientation {
		let cgiOrientations : [ CGImagePropertyOrientation ] = [
			.up, .down, .left, .right, .upMirrored, .downMirrored, .leftMirrored, .rightMirrored
		]
		return cgiOrientations[self.rawValue]
	}
}
