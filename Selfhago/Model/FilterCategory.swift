//
//  FilterCategory.swift
//  Selfhago
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

struct FilterCategory<FT>: Equatable, Identifiable, Hashable{
	
	static var allCategories: [FilterCategory<FT>] {
		let filters = SingleSliderFilterControl.allCases.compactMap{ $0.rawValue } +
		[		DistortionFilterControl.crop.rawValue,
				DistortionFilterControl.rotate.rawValue,
				DistortionFilterControl.perspective.rawValue,
				MultiSliderFilterControl.bilateral.rawValue,
				MultiSliderFilterControl.vignette.rawValue,
				MultiSliderFilterControl.outline.rawValue,
				MultiSliderFilterControl.textStamp.rawValue,
				DrawableFilterControl.maskBlur.rawValue,
				DrawableFilterControl.drawing.rawValue
			] +
			OnOffFilter.allCases.compactMap { $0.rawValue }
		
		return filters.map {
			FilterCategory(rawValue: $0)!
		}
	}
	
	static var categiresForRecording: [FilterCategory<FT>] {
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
			labelImage = drawbleFilter.labelImage
			subCategory = drawbleFilter.rawValue
			labelStrings = drawbleFilter.labelStrings
		}
		else if let multiSliderFilter = MultiSliderFilterControl(rawValue: rawValue) {
			control = multiSliderFilter as! FT
			labelImage = multiSliderFilter.labelImage
			subCategory = multiSliderFilter.rawValue
			labelStrings = multiSliderFilter.labelStrings
		}
		else if let onOffFilter = OnOffFilter(rawValue: rawValue) {
			control = onOffFilter as! FT
			labelImage = onOffFilter.labelImage
			subCategory = onOffFilter.rawValue
			labelStrings = onOffFilter.labelStrings
		}
		else if let sliderFilter = SingleSliderFilterControl(rawValue: rawValue) {
			control = sliderFilter as! FT
			labelImage = sliderFilter.labelImage
			subCategory = sliderFilter.rawValue
			labelStrings = sliderFilter.labelStrings
			if sliderFilter == .backgroundTone {
				hasSourceImage = true
			}
		}
		else if let distortionFilter = DistortionFilterControl(rawValue: rawValue) {
			control = distortionFilter as! FT
			labelImage = distortionFilter.labelImage
			subCategory = distortionFilter.rawValue
			labelStrings = distortionFilter.labelStrings
		}
		else {
			return nil
		}
	}
}

enum DrawableFilterControl: String {
	case maskBlur
	case drawing
	
	var labelImage: UIImage {
		switch self {
			case .maskBlur:
				return UIImage(named: "waterdrop")!
			case .drawing:
				return UIImage(named: "scribble")!
		}
	}
	
	var labelStrings: [String] {
		switch self {
			case .maskBlur:
				return ["Blur", "블러"]
			case .drawing:
				return ["Drawing", "그리기"]
		}
	}
}

enum DistortionFilterControl: String {
	case rotate
	case perspective
	case crop
	
	var labelImage: UIImage {
		switch self {
			case .crop:
				return UIImage(named: "crop")!
			case .rotate:
				return UIImage(systemName: "arrow.triangle.2.circlepath")!
			case .perspective:
				return UIImage(systemName: "perspective")!
		}
	}
	
	var labelStrings: [String] {
		switch self {
			case .crop:
				return ["Crop", "자르기"]
			case .rotate:
				return ["Rotate", "회전"]
			case .perspective:
				return ["Perspective", "기울이기"]
		}
	}
	
	enum CropRatioPreset: String, CaseIterable {
		static let originalLabelImage = UIImage(named: "circle")!
		static let orignalLabelStrings = ["Original", "원본 비율"]
		static let freeformLabelImage = UIImage(systemName: "hand.tap")!
		static let freeformLabelStrings = ["Freeform", "자유 비율"]
		case h1v1
		// Horizontal
		case h2v3
		case h3v4
		case h9v16
		// Vertical
		case h3v2
		case h4v3
		case h16v9
		
		static var horizontal: [CropRatioPreset] {
			[.h1v1, .h3v2, .h4v3, .h16v9]
		}
		static var vertical: [CropRatioPreset] {
			[.h1v1, .h2v3, .h3v4, .h9v16]
		}
		
		var labelImage: UIImage {
			UIImage(named: self.rawValue)!
		}
		
		var labelStrings: [String] {
			switch self {
				case .h1v1:
					return ["Square", "정사각형"]
				case .h2v3:
					return ["2:3", "2:3"]
				case .h3v4:
					return ["3:4", "3:4"]
				case .h9v16:
					return ["9:16", "9:16"]
				case .h3v2:
					return ["3:2", "3:2"]
				case .h4v3:
					return ["4:3", "4:3"]
				case .h16v9:
					return ["16:9", "16:9"]
			}
		}
		
		var ratio: CGFloat {
			switch self {
				case .h1v1:
					return 1
				case .h2v3:
					return 2/3
				case .h3v4:
					return 3/4
				case .h9v16:
					return 9/16
				case .h3v2:
					return 3/2
				case .h4v3:
					return 4/3
				case .h16v9:
					return 19/9
			}
		}
	}
}

enum MultiSliderFilterControl: String {
	case bilateral
	case vignette
	case outline
	case textStamp
	case gamma
	case red
	case blue
	case green
	
	var labelImage: UIImage {
		switch self {
			case .gamma:
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
			case .gamma:
				return 7
			case .red, .blue, .green:
				return 4
			case .bilateral:
				return 2
			case .vignette:
				return 3
			case .outline:
				assertionFailure("Outline filter has multiple filters ")
				return 0
			case .textStamp:
				return 3
		}
	}
	
	func getRange<T>(for index: Int) -> ClosedRange<T> where T: BinaryFloatingPoint {
		switch self {
			case .gamma:
				if index == 0 {
					return 0.1...3.0		// Gamma
				}else if index == 1 {
					return 0.5...1.5 	// Exponentail coefficient
				}else if index == 2 {
					return 0...0.5   	// Exponentail coefficient
				}else if	index == 3{
					return -0.2...0.2 	// Exponentail bias
				}else if index == 4 {
					return 0.5...1.5 	// Linear coefficient
				}else if index == 5{
					return -0.5...0.5 	// Linear bias
				}else {
					return 0...1		// Linear boundary
				}
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
				assertionFailure("Outline has multiple filters")
				return 0...1
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
			case .gamma:
				return ["Gamma", "감마"]
			case .red:
				return ["Fine Tunning(R)", "미세 조정 (빨강)"]
			case .blue:
				return ["Fine Tunning(B)", "미세 조정 (파랑)"]
			case .green:
				return ["Fine Tunning(G)", "미세 조정 (초록)"]
		}
	}
	
	enum OutlineFilter {
		case color
		case grayscale
		
		var labelStrings: [String] {
			switch self {
				case .color:
					return ["Color", "컬러"]
				case .grayscale:
					return ["Grayscale", "흑백"]
			}
		}
		
		var labelImage: UIImage {
			switch self {
				case .color:
					return UIImage(systemName: "paintpalette")!
				case .grayscale:
					return UIImage(systemName: "pencil")!
			}
		}
		
		var tunableFactor: Int {
			switch self {
				case .color:
					return 2
				case .grayscale:
					return 3
			}
		}
		
		func getRange<T>(for index: Int) -> ClosedRange<T> where T: BinaryFloatingPoint {
			switch self {
				case .color:
					if index == 0 {
						return 0.1...2
					}else {
						return 0.1...4
					}

				case .grayscale:
					if index == 0 {
						return 0...0.5 // Threshold
					}else if index == 1 {
						return 0...0.1 // Noise
					}else {
						return 0.1...0.5 // EdgeInetnsity
					}
			}
		}
	}
}

enum OnOffFilter: String, CaseIterable {
	case presetFiter
	
	var labelImage: UIImage{
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
	
	var labelImage: UIImage {
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
	
	var labelImage: UIImage {
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
