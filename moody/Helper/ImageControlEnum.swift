//
//  ImageControlEnum.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

enum ImageBlurControl: String {
	case mask
	
	var label: Image {
		switch self {
			case .mask:
				return Image(systemName: "lasso")
		}
	}
}

enum ImageSelectiveControl: String {
	case brightness
	
	var label: Image{
		switch self {
			case .brightness:
				return Image(systemName: "dial.max")
		}
	}
}

enum PresetFilter: String {
	case portrait
	case landscape
	
	var code: String {
		switch self {
			case .portrait:
				return "S"
			case .landscape:
				return "P"
		}
	}
	
	var label: Image {
		switch self {
			case .portrait:
				return Image(systemName: "person.crop.circle.fill")
			case .landscape:
				return Image(systemName: "leaf.fill")
		}
	}
	
	var luts: [String] {
		switch self {
			case .portrait:
				return ["LochNess", "Oslo", "Pocatello", "Reykjavik", "Seattle", "Tahoe"]
			case .landscape:
				return ["Boulder", "Everest", "Oaxaca",
				"Prague", "Travelgram"]
		}
	}
}

enum BuiltInColorControl: String, Hashable, CaseIterable {
	
	case brightness = "밝기"
	case saturation = "채도"
	case contrast = "대비"
	
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
