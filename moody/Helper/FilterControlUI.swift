//
//  ImageFilter.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

enum DrawableFilterControl: String {
	case mask
	
	var label: Image {
		switch self {
			case .mask:
				return Image(systemName: "lasso")
		}
	}
}

enum TunableFilterControl: String {
	case rgb
	case bilateral
	case vignette
	
	var label: Image{
		switch self {
			case .rgb:
				return Image(systemName: "dial.max")
			case .bilateral:
				return Image(systemName: "wand.and.stars")
			case .vignette:
				return Image(systemName: "v.circle.fill")
		}
	}
	
	var tunableFactors: Int {
		switch self {
			case .rgb:
				return 4
			case .bilateral:
				return 2
			case .vignette:
				return 3
		}
	}
	
	func getRange<T>(for index: Int) -> ClosedRange<T> where T: BinaryFloatingPoint {
		switch self {
			case .rgb:
				return -0.5...0.5
			case .bilateral:
				return index == 0 ? 0.1...3.0: 0.1...0.3
			case .vignette:
				if index == 0 {
					return 0...2
				}
				else if index == 1 {
					return 0...10
				}
				else {
					return -1...1
				}
		}
	}
}

enum PresetFilterControl: String, CaseIterable {
	case portraitLut
	case landscapeLut
	case outline
	
	var lutCode: String? {
		switch self {
			case .portraitLut:
				return "S"
			case .landscapeLut:
				return "P"
			case .outline:
				return nil
		}
	}
	
	var label: Image {
		switch self {
			case .portraitLut:
				return Image(systemName: "person.crop.circle.fill")
			case .landscapeLut:
				return Image(systemName: "leaf.fill")
			case .outline:
				return Image(systemName: "pencil.and.outline")
		}
	}
	
	var luts: [String]? {
		switch self {
			case .portraitLut:
				return ["LochNess", "Oslo", "Pocatello", "Reykjavik", "Seattle", "Tahoe"]
			case .landscapeLut:
				return ["Boulder", "Everest", "Oaxaca",
				"Prague", "Travelgram"]
			case .outline:
				return nil
		}
	}
}

enum CIColorFilterControl: String, Hashable, CaseIterable {
	
	case brightness
	case saturation
	case contrast
	
	var defaultValue: Double {
		switch self {
			case .brightness:
				return 0
			case .saturation, .contrast:
				return 1
		}
	}
	
	static var defaults: [Self: Double] {
		Self.allCases.reduce(into: [Self: Double]()) {
			$0[$1] = $1.defaultValue
		}
	}
	
	var label: Image {
		switch self {
			case .brightness:
				return Image(systemName: "sun.max")
			case .saturation:
				return Image(systemName: "drop.fill")
			case .contrast:
				return Image(systemName: "circle.lefthalf.fill")
		}
	}
	
}
