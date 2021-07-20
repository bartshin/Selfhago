//
//  RandomColor.swift
//  moody
//
//  Created by bart Shin on 19/07/2021.
//

import UIKit

extension UIColor {
	static func getRandom() -> UIColor{
		
		let randomRed:CGFloat = CGFloat(drand48())
		
		let randomGreen:CGFloat = CGFloat(drand48())
		
		let randomBlue:CGFloat = CGFloat(drand48())
		
		return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
		
	}
}
