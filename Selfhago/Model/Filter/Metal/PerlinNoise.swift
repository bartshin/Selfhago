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

// MARK: Perlin Noise
class PerlinNoise: MetalGeneratorFilter
{
	override var functionName: String {
		"perlin"
	}
	
	override init() {
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	var inputReciprocalScale = CGFloat(50)
	var inputOctaves = CGFloat(2)
	var inputPersistence = CGFloat(0.5)
	
	var inputColor0 = CIColor(red: 0.5, green: 0.25, blue: 0)
	var inputColor1 = CIColor(red: 0, green: 0, blue: 0.15)
	
	var inputZ = CGFloat(0)
	
	override func setDefaults()
	{
		inputReciprocalScale = 50
		inputOctaves = 2
		inputPersistence = 0.5
		
		inputColor0 = CIColor(red: 0.5, green: 0.25, blue: 0)
		inputColor1 = CIColor(red: 0, green: 0, blue: 0.15)
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "Metal Perlin Noise",
			
			"inputReciprocalScale": [kCIAttributeIdentity: 0,
									 kCIAttributeClass: "NSNumber",
									 kCIAttributeDefault: 50,
									 kCIAttributeDisplayName: "Scale",
									 kCIAttributeMin: 10,
									 kCIAttributeSliderMin: 10,
									 kCIAttributeSliderMax: 100,
									 kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputOctaves": [kCIAttributeIdentity: 1,
							 kCIAttributeClass: "NSNumber",
							 kCIAttributeDefault: 2,
							 kCIAttributeDisplayName: "Octaves",
							 kCIAttributeMin: 1,
							 kCIAttributeSliderMin: 1,
							 kCIAttributeSliderMax: 16,
							 kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputPersistence": [kCIAttributeIdentity: 2,
								 kCIAttributeClass: "NSNumber",
								 kCIAttributeDefault: 0.5,
								 kCIAttributeDisplayName: "Persistence",
								 kCIAttributeMin: 0,
								 kCIAttributeSliderMin: 0,
								 kCIAttributeSliderMax: 1,
								 kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputColor0": [kCIAttributeIdentity: 3,
							kCIAttributeClass: "CIColor",
							kCIAttributeDefault: CIColor(red: 0.5, green: 0.25, blue: 0),
							kCIAttributeDisplayName: "Color One",
							kCIAttributeType: kCIAttributeTypeColor],
			
			"inputColor1": [kCIAttributeIdentity: 4,
							kCIAttributeClass: "CIColor",
							kCIAttributeDefault: CIColor(red: 0, green: 0, blue: 0.15),
							kCIAttributeDisplayName: "Color Two",
							kCIAttributeType: kCIAttributeTypeColor],
			
			"inputZ": [kCIAttributeIdentity: 5,
					   kCIAttributeClass: "NSNumber",
					   kCIAttributeDefault: 1,
					   kCIAttributeDisplayName: "Z Position",
					   kCIAttributeMin: 0,
					   kCIAttributeSliderMin: 0,
					   kCIAttributeSliderMax: 1024,
					   kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputWidth": [kCIAttributeIdentity: 2,
						   kCIAttributeClass: "NSNumber",
						   kCIAttributeDefault: 640,
						   kCIAttributeDisplayName: "Width",
						   kCIAttributeMin: 100,
						   kCIAttributeSliderMin: 100,
						   kCIAttributeSliderMax: 2048,
						   kCIAttributeType: kCIAttributeTypeScalar],
			
			"inputHeight": [kCIAttributeIdentity: 2,
							kCIAttributeClass: "NSNumber",
							kCIAttributeDefault: 640,
							kCIAttributeDisplayName: "Height",
							kCIAttributeMin: 100,
							kCIAttributeSliderMin: 100,
							kCIAttributeSliderMax: 2048,
							kCIAttributeType: kCIAttributeTypeScalar],
		]
	}
}
