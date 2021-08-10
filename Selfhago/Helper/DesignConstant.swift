//
//  DesignConstant.swift
//  Selfhago
//
//  Created by bart Shin on 2021/08/05.
//

import SwiftUI

class DesignConstant: ObservableObject {
	
	var interface: UIUserInterfaceStyle
	var isStatusbarHidden: Bool
	
	static let menuTitleFont = getFont(.init(family: .NotoSansCJKkr, style: .Regular), size: 17)
	static let shared = DesignConstant()
	static let referenceSize = CGSize(width: 375, height: 812)
	static let presetFilterImage = UIImage(named: "filter_icon")!
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
		interface = .light
		isStatusbarHidden = false
		
	}
}
