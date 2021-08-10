//
//  NormalizeControlValue.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/06.
//

import SwiftUI

protocol ControlView: View {
}

extension ControlView {
	static func normalizeValue<T>(_ value: T, in range: ClosedRange<T>) -> T where T: BinaryFloatingPoint  {
		(value - range.lowerBound) / (range.upperBound - range.lowerBound)
	}
	
	
	static func deNormalizeValue<T>(_ normalizedValue: T, in range: ClosedRange<T>) -> T where T: BinaryFloatingPoint  {
		range.lowerBound + normalizedValue * (range.upperBound - range.lowerBound)
	}
	
}
