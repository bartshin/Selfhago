//
//  DesignConstant.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/05.
//

import SwiftUI

class DesignConstant {
	
	static let menuTitleFont = getFont(.init(family: .NotoSansCJKkr, style: .Regular), size: 17)
	static let shared = DesignConstant()
	static let referenceSize = CGSize(width: 375, height: 812)
	static let presetFilterImage = UIImage(named: "filter_icon")!
	fileprivate var colorScheme: Palette.ColorScheme
	static var isDarkMode: Bool {
		shared.colorScheme == .dark
	}
	static func getUIFont(_ font: SelfhagoFont, size: CGFloat) -> UIFont {
		guard let found = UIFont(name: font.name, size: size) else {
			assertionFailure("\(font) is not available")
			return UIFont()
		}
		return found
	}
	
	static func getFont(_ font: SelfhagoFont, size: CGFloat) -> Font {
		Font.custom(font.name, fixedSize: size)
	}
	
	static func setColorScheme(to scheme: Palette.ColorScheme) {
		shared.colorScheme = scheme
	}
	
	static func getUIColor(for palette: Palette, isDimmed: Bool = false) -> UIColor {
		let hexValue: UInt64
		if isDimmed {
			hexValue = palette.dimmedHexValue(for: DesignConstant.shared.colorScheme)
		}
		else {
			hexValue = palette.hexValue(for: DesignConstant.shared.colorScheme)
		}
		return UIColor(hex: hexValue)
	}
	
	static func getColor(for palette: Palette, isDimmed: Bool = false) -> Color {
		Color(getUIColor(for: palette, isDimmed: isDimmed))
	}
	
	static func chooseColor(in colors: (light: UInt64, dark: UInt64)) -> Color {
		DesignConstant.shared.colorScheme == .dark ? Color(hex: colors.dark): Color(hex: colors.light)
	}
	
	
	struct SelfhagoFont {
		
		let family: Family
		let style: Style
		
		enum Family: String {
			case NotoSansCJKkr
		}
		
		enum Style: String {
			case Bold
			case Medium
			case Regular
		}
		
		var name: String {
			"\(family.rawValue)-\(style.rawValue)"
		}
	}
	
	init() {
		colorScheme = .light
	}
	
	enum Palette {
		case primary
		case surface
		case background
		case error
		case success
		case link
		case onPrimary
		case onBackground
		case onSurface
		
		fileprivate func hexValue(for scheme: ColorScheme) -> UInt64 {
			let hexTuple: (UInt64, UInt64)
			switch self {
				case .primary:
					hexTuple = (0xFF2D55, 0xFF375D)
				case .background:
					hexTuple = (0xFFFFFF, 0x000000)
				case .surface:
					hexTuple = (0xFFFFFF, 0x000000)
				case .error:
					hexTuple = (0xFF3B30, 0xFF453A)
				case .success:
					hexTuple = (0x34C759, 0x30D158)
				case .link:
					hexTuple = (0x007AFF, 0x007AFF)
				case .onPrimary:
					hexTuple = (0xFFFFFF, 0xFFFFFF)
				case .onBackground:
					hexTuple = (0x000000, 0xFFFFFF)
				case .onSurface:
					hexTuple = (0x000000, 0xFFFFFF)
			}
			return scheme == .light ? hexTuple.0: hexTuple.1
		}
		
		fileprivate func dimmedHexValue(for scheme: ColorScheme) -> UInt64 {
			let hexTuple: (UInt64, UInt64)
			switch self {
				case .primary:
					hexTuple = (0xFFBFCB, 0x4D101C)
				case .error:
					hexTuple = (0xFFC3C0, 0x4D1511)
				case .success:
					hexTuple = (0xC1EECD, 0x0E3F1A)
				case .link:
					hexTuple = (0xB2D7FF, 0x00254D)
				case .onBackground:
					hexTuple = (0xB2B2B2, 0x4D4D4D)
				case .onSurface:
					hexTuple = (0xB2B2B2, 0x4D4D4D)
				case .background, .surface, .onPrimary:
					assertionFailure("No dimmed color for \(self)")
					return 0
			}
			return scheme == .light ? hexTuple.0: hexTuple.1
		}
		
		enum ColorScheme {
			case light
			case dark
		}
	}
}
