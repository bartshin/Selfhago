//
//  LabAdjustment.swift
//  LabAdjustment
//
//  Created by bart Shin on 2021/09/02.
//

import CoreImage
import Alloy

/// Convert RGB color space to LAB color space
class LabAdjustment: MetalImageFilter {
	
	override var functionName: String {
		"LabAdjustment"
	}
	static let brightnessAmountKey = "inputLValue"
	static let greenToRedAmountKey = "inputAValue"
	static let blueToYellowAmountKey = "inputBValue"
	static let pickedColorKey = "inputPickedColors"
	
	static var defaultLValues: [Float] {
		(0...255).compactMap { Float($0) / 255 }
	}
	@objc private var inputLValue: [Float] = defaultLValues
	@objc private var inputAValue: CGFloat = 0
	@objc private var inputBValue: CGFloat = 0
	@objc private var inputNumberOfColors: CGFloat = 0
	private var inputPickedColors = [SIMD4<Float>]()
	
	override init() {
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey{
			inputImage = (value as! CGImage?)
		}
		else if key == Self.sourceTextureKey ||
					key == Self.destinationTextureKey {
			super.setValue(value, forKey: key)
		}
		else if key == Self.brightnessAmountKey,
				let luma = value as? [Float] {
			inputLValue = luma
		}
		else if key == Self.greenToRedAmountKey,
				let aValue = value as? CGFloat {
			inputAValue = aValue
		}
		else if key == Self.blueToYellowAmountKey,
				let bValue = value as? CGFloat {
			inputBValue = bValue
		}
		else if key == Self.pickedColorKey,
				let colors = value as? [UIColor] {
			inputPickedColors = colors.compactMap {
				let labColor = RGBColor(r: $0.redComponent, g: $0.greenComponent, b: $0.blueComponent, alpha: $0.alphaComponent)
					.toLAB()
				return SIMD4<Float>(Float(labColor.l),
									Float(labColor.a),
									Float(labColor.b),
									Float(labColor.alpha))
			}
			inputNumberOfColors = CGFloat(inputPickedColors.count)
			if inputPickedColors.isEmpty {
				inputPickedColors.append(SIMD4<Float>(0, 0, 0, 0)) // Place holder prevent error
			}
		}
	}
	
	override func value(forKey key: String) -> Any? {
		if key == Self.pickedColorKey {
			return inputPickedColors
		}else {
			return super.value(forKey: key)
		}
	}
	
	override var attributes: [String : Any]
	{
		return [
			kCIAttributeFilterDisplayName: "LAB color space adjustment",
			kCIAttributeFilterName: String(describing: Self.self),
			"inputLValue": [kCIAttributeIdentity: 0,
							   kCIAttributeClass: "FloatArray",
							 kCIAttributeDefault: 0.5,
						 kCIAttributeDisplayName: "L value (Luma)",
								 kCIAttributeMin: 0,
						   kCIAttributeSliderMin: 0,
						   kCIAttributeSliderMax: 1,
								kCIAttributeType: kCIAttributeTypeScalar],
			"inputAValue": [kCIAttributeIdentity: 1,
							   kCIAttributeClass: "NSNumber",
							 kCIAttributeDefault: 0.5,
						 kCIAttributeDisplayName: "A Value (Green to red)",
								 kCIAttributeMin: 0,
						   kCIAttributeSliderMin: 0,
						   kCIAttributeSliderMax: 1,
								kCIAttributeType: kCIAttributeTypeScalar],
			"inputBValue": [kCIAttributeIdentity: 2,
							   kCIAttributeClass: "NSNumber",
							 kCIAttributeDefault: 0.5,
						 kCIAttributeDisplayName: "B Value (Blue to yellow)",
								 kCIAttributeMin: 0,
						   kCIAttributeSliderMin: 0,
						   kCIAttributeSliderMax: 1,
								kCIAttributeType: kCIAttributeTypeScalar],
			"inputNumberOfColors": [kCIAttributeIdentity: 3,
							   kCIAttributeClass: "NSNumber",
							 kCIAttributeDefault: 0,
						 kCIAttributeDisplayName: "Number of color picked",
								 kCIAttributeMin: 0,
						   kCIAttributeSliderMin: 0,
						   kCIAttributeSliderMax: 0,
								kCIAttributeType: kCIAttributeTypeScalar],
			"inputPickedColors": [kCIAttributeIdentity: 4,
							   kCIAttributeClass: "Float4Array",
							 kCIAttributeDefault: 0,
						 kCIAttributeDisplayName: "Colors to adjust",
								 kCIAttributeMin: 0,
						   kCIAttributeSliderMin: 0,
						   kCIAttributeSliderMax: 0,
								kCIAttributeType: kCIAttributeTypeColor],
		]
	}
	
	
}
