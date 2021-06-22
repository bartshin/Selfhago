//
//  TuneImage.swift
//  moody
//
//  Created by bart Shin on 21/06/2021.
//

import SwiftUI

enum ImageTuneFactor: String, Hashable, CaseIterable {
	
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
	/// All factor is 0.5 by defaults
	static var defaults: [Self: Double] {
		Self.allCases.reduce(into: [Self: Double]()) {
			$0[$1] = $1.defaultValue
		}
	}
	
	var label: some View {
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

extension View {
	func applyTuning(_ adjustment: [ImageTuneFactor: Double]) -> some View {
		self
			.brightness(adjustment[.brightness] ?? ImageTuneFactor.brightness.defaultValue)
			.contrast(adjustment[.contrast] ?? ImageTuneFactor.contrast.defaultValue)
			.saturation(adjustment[.saturation] ?? ImageTuneFactor.saturation.defaultValue)
	}
}

