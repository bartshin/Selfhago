//
//  CIVector.swift
//  Selfhago
//
//  Created by bart Shin on 16/07/2021.
//

import CoreImage

extension CIVector {
	func multiply(value: CGFloat) -> CIVector
	{
		let n = self.count
		var targetArray = [CGFloat]()
		
		for i in 0 ..< n
		{
			targetArray.append(self.value(at: i) * value)
		}
		
		return CIVector(values: targetArray, count: n)
	}
}
