//
//  MetalFilters.swift
//  Filterpedia
//
//  Created by Simon Gladman on 24/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>


import CoreImage
import Alloy

// MARK: KuwaharaMetal
class KuwaharaMetal: MetalImageFilter
{
	override var functionName: String {
		"kuwahara_metal"
	}
	
	override init() {
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	var inputRadius: CGFloat = 0
	
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey {
			inputImage = (value as! CGImage)
		}
		if key == kCIInputRadiusKey,
		   let radius = value as? CGFloat{
			inputRadius = radius
		}
	}
	
	override func value(forKey key: String) -> Any? {
		if key == kCIInputRadiusKey {
		   return inputRadius
		}
		return nil
	}
	
	override var attributes: [String : Any]
	{
		return [
			
			kCIAttributeFilterName: String(describing: Self.self),
			kCIAttributeFilterDisplayName: "KuwaharaMetal",
			
			"inputImage": [kCIAttributeIdentity: 0,
						   kCIAttributeClass: "CIImage",
						   kCIAttributeDisplayName: "Image",
						   kCIAttributeType: kCIAttributeTypeImage],
			
			"inputRadius": [kCIAttributeIdentity: 0,
							kCIAttributeClass: "NSNumber",
							kCIAttributeDefault: 15,
							kCIAttributeDisplayName: "Radius",
							kCIAttributeMin: 0,
							kCIAttributeSliderMin: 0,
							kCIAttributeSliderMax: 30,
							kCIAttributeType: kCIAttributeTypeScalar],
		]
	}
}
