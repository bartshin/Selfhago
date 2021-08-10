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
				DrawableFilterControl.mask.rawValue
			] +
			OnOffFilter.allCases.compactMap { $0.rawValue }
		return filters.map {
			FilterCategory(rawValue: $0)!
		}
	}
	
	static var categiresForRecording: [Self<Any>] {
		let filters = [SingleSliderFilterControl.brightness,
					   .saturation,
					   .contrast].compactMap{ $0.rawValue } + [
						MultiSliderFilterControl.vignette.rawValue,
						MultiSliderFilterControl.outline.rawValue,
					] +
			OnOffFilter.allCases.compactMap { $0.rawValue }
		return filters.map {
			FilterCategory(rawValue: $0)!
		}
	}
	
	private(set) var control: FT
	let subCategory: String
	private(set) var labelImage: UIImage
	private(set) var labelStrings: [String]
	var hasSourceImage: Bool
	
	var id: String {
		subCategory
	}
	
	static func == (lhs: FilterCategory<FT>, rhs: FilterCategory<FT>) -> Bool {
		lhs.subCategory == rhs.subCategory
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	
	init?(rawValue: String) {
		hasSourceImage = false
		if let drawbleFilter = DrawableFilterControl(rawValue: rawValue) {
			control = drawbleFilter as! FT
			labelImage = drawbleFilter.label
			subCategory = drawbleFilter.rawValue
			labelStrings = drawbleFilter.labelStrings
		}
		else if let multiSliderFilter = MultiSliderFilterControl(rawValue: rawValue) {
			control = multiSliderFilter as! FT
			labelImage = multiSliderFilter.label
			subCategory = multiSliderFilter.rawValue
			labelStrings = multiSliderFilter.labelStrings
		}
		else if let onOffFilter = OnOffFilter(rawValue: rawValue) {
			control = onOffFilter as! FT
			labelImage = onOffFilter.label
			subCategory = onOffFilter.rawValue
			labelStrings = onOffFilter.labelStrings
		}
		else if let sliderControl = SingleSliderFilterControl(rawValue: rawValue) {
			control = sliderControl as! FT
			labelImage = sliderControl.label
			subCategory = sliderControl.rawValue
			labelStrings = sliderControl.labelStrings
			if sliderControl == .backgroundTone {
				hasSourceImage = true
			}
		}
		else {
			return nil
		}
	}
}

enum DrawableFilterControl: String {
	case mask
	
	var label: UIImage {
		switch self {
			case .mask:
				return UIImage(named: "waterdrop")!
		}
	}
	
	var labelStrings: [String] {
		switch self {
			case .mask:
				return ["Blur", "블러"]
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
	
	var label: UIImage {
		switch self {
			case .rgb:
				return UIImage(named: "rgb_circles")!
			case .red:
				return UIImage(systemName: "r.circle")!
			case .green:
				return UIImage(systemName: "g.circle")!
			case .blue:
				return UIImage(systemName: "b.circle")!
			case .bilateral:
				return UIImage(named: "magic_wand")!
			case .vignette:
				return UIImage(named: "vignette")!
			case .outline:
				return UIImage(named: "pencil")!
			case .textStamp:
				return UIImage(named: "textbox")!
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
				return 3
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
					return 10...50
				}else if index == 1 {
					return 0...1
				}else {
					return 0...(2 * .pi)
				}
			
		}
	}
	var labelStrings: [String] {
	
		switch self {
			case .bilateral:
				return ["Denoise", "잡티 제거"]
			case .outline:
				return ["Sketch", "스케치"]
			case .textStamp:
				return ["Text", "문구"]
			case .vignette:
				return ["Vignette", "비네트"]
			case .rgb:
				return ["Brightness(Advanced)", "밝기 세부 조정"]
			case .red:
				return ["Color(Red)", "색상 (빨강)"]
			case .blue:
				return ["Color(Blue)", "색상 (파랑)"]
			case .green:
				return ["Color(Green)", "색상 (초록)"]
		}
	}
}

enum OnOffFilter: String, CaseIterable {
	case presetFiter
	
	var label: UIImage{
		switch self {
			case .presetFiter:
				return UIImage(named: "rgb_circles_invert")!
		}
	}
	var labelStrings: [String] {
		switch self {
			case .presetFiter:
				return ["Preset", "프리셋"]
		}
	}
}
enum PresetFilter: CaseIterable {
	case portraitLut
	case landscapeLut
	
	var lutCode: String {
		switch self {
			case .portraitLut:
				return "P"
			case .landscapeLut:
				return "L"
		}
	}
	
	var label: UIImage {
		switch self {
			case .portraitLut:
				return UIImage(systemName: "p.square")!
			case .landscapeLut:
				return UIImage(systemName: "l.square")!
		}
	}
	
	
	var luts: [String] {
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
	case glitter
	
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
			case .glitter:
				return 0
		}
	}
	func getRange<T>() -> ClosedRange<T> where T: BinaryFloatingPoint {
		switch self {
			case .brightness:
				return -0.5...0.5
			case .saturation, .contrast:
				return 0.5...1.5
			case .painter:
				return 0...20
			case .backgroundTone:
				return 0...0.7
			case .glitter:
				return 0...0.2
		}
	}
	
	var hasAdditionalControl: Bool {
		switch self {
			case .contrast, .painter:
				return false
			case .brightness, .saturation, .backgroundTone, .glitter:
				return true
		}
	}
	
	var label: UIImage {
		switch self {
			case .brightness:
				return UIImage(named: "brightness")!
			case .saturation:
				return UIImage(named: "rgb_circles")!
			case .contrast:
				return UIImage(named: "contrast")!
			case .painter:
				return UIImage(named: "brush")!
			case .backgroundTone:
				return UIImage(systemName: "cloud.moon")!
			case .glitter:
				return UIImage(named: "diamond")!
		}
	}
	var labelStrings: [String] {
		switch self {
			case .brightness:
				return ["Brightness", "밝기"]
			case .saturation:
				return ["Saturation", "채도"]
			case .contrast:
				return ["Contrast", "대비"]
			case .painter:
				return ["Painter", "수채화"]
			case .backgroundTone:
				return ["Tone copy", "배경 톤"]
			case .glitter:
				return ["Glitter", "반짝임"]
		}
	}
}
