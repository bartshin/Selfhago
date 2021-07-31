//
//  FilterControlHelper.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

struct FilterCategory<FT>: Equatable, Identifiable, Hashable{
	
	static var allCategories: [Self<Any>] {
		let filters = SingleSliderFilterControl.allCases.compactMap{ $0.rawValue } +
			[
				MultiSliderFilterControl.bilateral.rawValue, MultiSliderFilterControl.vignette.rawValue,
				MultiSliderFilterControl.outline.rawValue,
				MultiSliderFilterControl.textStamp.rawValue,
				DrawableFilterControl.mask.rawValue, AngleAndSliderFilterControl.glitter.rawValue
			] +
			OnOffFilter.allCases.compactMap { $0.rawValue }
		return filters.map {
			FilterCategory(rawValue: $0)!
		}
	}
	
	private(set) var control: FT
	let subCategory: String
	private(set) var labelImage: Image?
	
	var id: String {
		subCategory
	}
	
	static func == (lhs: FilterCategory<FT>, rhs: FilterCategory<FT>) -> Bool {
		lhs.subCategory == rhs.subCategory
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	var isNeedPreviewImage: Bool
	
	init?(rawValue: String) {
		isNeedPreviewImage = false
		if let drawbleFilter = DrawableFilterControl(rawValue: rawValue) {
			control = drawbleFilter as! FT
			labelImage = drawbleFilter.label
			subCategory = drawbleFilter.rawValue
		}
		else if let multiSliderFilter = MultiSliderFilterControl(rawValue: rawValue) {
			control = multiSliderFilter as! FT
			labelImage = multiSliderFilter.label
			subCategory = multiSliderFilter.rawValue
		}
		else if let angleAndSliderFilter = AngleAndSliderFilterControl(rawValue: rawValue) {
			control = angleAndSliderFilter as! FT
			labelImage = angleAndSliderFilter.label
			subCategory = angleAndSliderFilter.rawValue
		}
		else if let onOffFilter = OnOffFilter(rawValue: rawValue) {
			control = onOffFilter as! FT
			labelImage = onOffFilter.label
			subCategory = onOffFilter.rawValue
		}
		else if let sliderControl = SingleSliderFilterControl(rawValue: rawValue) {
			control = sliderControl as! FT
			labelImage = sliderControl.label
			subCategory = sliderControl.rawValue
			if sliderControl == .backgroundTone {
				isNeedPreviewImage = true
			}
		}
		else {
			return nil
		}
	}
}

enum DrawableFilterControl: String {
	case mask
	
	var label: Image {
		switch self {
			case .mask:
				return Image(systemName: "eye.slash")
		}
	}
}

enum MultiSliderFilterControl: String {
	case bilateral
	case vignette
	case outline
	case textStamp
	case rgb
	case red
	case blue
	case green
	
	var label: Image?{
		switch self {
			case .rgb, .red, .blue, .green:
				return nil
			case .bilateral:
				return Image(systemName: "wand.and.stars")
			case .vignette:
				return Image(systemName: "v.circle.fill")
			case .outline:
				return Image(systemName: "pencil.and.outline")
			case .textStamp:
				return Image(systemName: "textbox")
		}
	}
	
	var tunableFactors: Int {
		switch self {
			case .rgb, .red, .blue, .green:
				return 4
			case .bilateral:
				return 2
			case .vignette:
				return 3
			case .outline:
				return 2
			case .textStamp:
				return 2
		}
	}
	
	func getRange<T>(for index: Int) -> ClosedRange<T> where T: BinaryFloatingPoint {
		switch self {
			case .rgb:
				return -0.5...0.5
			case .red, .blue, .green:
				return -0.8...0.8
			case .bilateral:
				return index == 0 ? 0.1...3.0: 0.1...0.3
			case .vignette:
				if index == 0 {
					return 0...2
				}
				else if index == 1 {
					return 0...5
				}
				else {
					return -0.5...0.5
				}
			case .outline:
				if index == 0 {
					return 0.1...2
				}else {
					return 0.1...4
				}

			case .textStamp:
				if index == 0 {
					return 0...20
				}else {
					return 10...100
				}
			
		}
	}
}

enum AngleAndSliderFilterControl: String, CaseIterable {
	case glitter
	
	var label: Image{
		switch self {
			case .glitter:
				return Image(systemName: "sparkles")
		}
	}
	var scalarFactorCount: Int {
		switch self {
			case .glitter:
				return 1
		}
	}
	func getRange<T>(for index: Int) -> ClosedRange<T> where T: BinaryFloatingPoint {
		switch self {
			case .glitter:
				return 0...0.2
		}
	}
}

enum OnOffFilter: String, CaseIterable {
	case portraitLut
	case landscapeLut
	
	var lutCode: String? {
		switch self {
			case .portraitLut:
				return "P"
			case .landscapeLut:
				return "L"
		}
	}
	
	var label: Image {
		switch self {
			case .portraitLut:
				return Image(systemName: "p.square")
			case .landscapeLut:
				return Image(systemName: "l.square")
		}
	}
	
	
	var luts: [String]? {
		switch self {
			case .portraitLut:
				return ["LochNess", "Oslo", "Pocatello", "Reykjavik", "Seattle", "Tahoe"]
			case .landscapeLut:
				return ["Boulder", "Everest", "Oaxaca",
				"Prague", "Travelgram"]
		}
	}
}

enum SingleSliderFilterControl: String, CaseIterable {
	
	case brightness
	case saturation
	case contrast
	case painter
	case backgroundTone
	
	var defaultValue: CGFloat {
		switch self {
			case .brightness:
				return 0
			case .saturation, .contrast:
				return 1
			case .painter:
				return 0
			case .backgroundTone:
				return 0.5
		}
	}
	func getRange<T>() -> ClosedRange<T> where T: BinaryFloatingPoint {
		switch self {
			case .brightness, .saturation, .contrast:
				return -0.5...0.5
			case .painter:
				return 0...20
			case .backgroundTone:
				return 0...0.7
		}
	}
	
	var hasAdditionalControl: Bool {
		switch self {
			case .contrast, .painter:
				return false
			case .brightness, .saturation, .backgroundTone:
				return true
		}
	}
	
	var label: Image {
		switch self {
			case .brightness:
				return Image(systemName: "sun.max")
			case .saturation:
				return Image(systemName: "dial.min")
			case .contrast:
				return Image(systemName: "circle.lefthalf.fill")
			case .painter:
				return Image(systemName: "paintbrush.pointed.fill")
			case .backgroundTone:
				return Image(systemName: "cloud.moon")
		}
	}
	
}
