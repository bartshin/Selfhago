//
//  FilterParameter.swift
//  moody
//
//  Created by bart Shin on 30/06/2021.
//

import Foundation

struct FilterParameter {
	enum Threshold: Float {
		case black = 0.25
		case shadow = 0.5
		case highlight = 0.75
		case white = 1.0
	}
	
	enum RGBColor: Int, CaseIterable {
		case red 
		case green
		case blue
	}
}
