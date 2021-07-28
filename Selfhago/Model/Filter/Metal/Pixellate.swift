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

// MARK: Pixellate
class Pixellate: MetalImageFilter
{
	init()
	{
		super.init(functionName: "pixellate")
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	var inputPixelWidth: CGFloat = 50
	var inputPixelHeight: CGFloat = 25
	
	override func setDefaults()
	{
		inputPixelWidth = 50
		inputPixelHeight = 25
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "Metal Pixellate",
			
			"inputImage": [kCIAttributeIdentity: 0,
						   kCIAttributeClass: "CIImage",
						   kCIAttributeDisplayName: "Image",
						   kCIAttributeType: kCIAttributeTypeImage],
			
			"inputPixelWidth": [kCIAttributeIdentity: 0,
								kCIAttributeClass: "NSNumber",
								kCIAttributeDefault: 50,
								kCIAttributeDisplayName: "Pixel Width",
								kCIAttributeMin: 0,
								kCIAttributeSliderMin: 0,
								kCIAttributeSliderMax: 100,
								kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputPixelHeight": [kCIAttributeIdentity: 1,
								 kCIAttributeClass: "NSNumber",
								 kCIAttributeDefault: 25,
								 kCIAttributeDisplayName: "Pixel Height",
								 kCIAttributeMin: 0,
								 kCIAttributeSliderMin: 0,
								 kCIAttributeSliderMax: 100,
								 kCIAttributeType: kCIAttributeTypeScalar]
		]
	}
}
