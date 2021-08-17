//
//  RefractedText.swift
//  Selfhago
//
//  Created by bart Shin on 23/07/2021.
//

import CoreImage
import UIKit

class RefractedText: CIFilter {
	
	static var alignmentKey: String {
		TextMask.alignmentKey
	}
	static var fontKey: String {
		TextMask.fontKey
	}
	static var inputTextKey: String {
		TextMask.inputTextKey
	}
	private var inputImage: CIImage?
	private var text: String?
	private var alignment: TextMask.Alignment = .center
	private var font: UIFont?
	private var radius: CGFloat = 30
	private var refractiveIndex: CGFloat = 4
	private var lensScale: CGFloat = 50
	private var lensBlur: CGFloat = 0
	private var lightingAmount: CGFloat = 1.5
	private var backgroundBlur: CGFloat = 2
	private lazy var kernel: CIKernel = findKernel("refract")
	
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey,
		   let image = value as? CIImage {
			self.inputImage = image
		}
		else if key == kCIInputRadiusKey,
		   let radius = value as? CGFloat {
			self.radius = 30 - radius
		}
		else if key == kCIInputScaleKey ,
				let scale = value as? CGFloat {
			self.lensScale = scale
		}
		else if key == Self.fontKey,
				let font = value as? UIFont {
			self.font = font
		}
		else if key == Self.inputTextKey,
				let text = value as? String{
			self.text = text
		}
		else if key == Self.alignmentKey,
				let alignment = value as? TextMask.Alignment {
			self.alignment = alignment
		}
	}
	
	override var outputImage: CIImage? {
		guard text != nil,
			  font != nil,
			  inputImage != nil ,
			  let textImage = createTextImage(),
			  let refractingImage = CIFilter(
				name: "CIHeightFieldFromMask",
				parameters: [
					kCIInputRadiusKey: radius,
					kCIInputImageKey: textImage
				])!.outputImage
		else {
			return nil
		}
		let blurMask = textImage.applyingFilter("CIColorInvert")

		return kernel.apply(extent: inputImage!.extent,
							roiCallback: { index, rect in
								rect
							},
							arguments: [
								inputImage!,
								refractingImage,
								refractiveIndex,
								lensScale,
								lightingAmount
							])?
			.applyingFilter("CIMaskedVariableBlur",
			parameters: [
			kCIInputRadiusKey: backgroundBlur,
			"inputMask": blurMask
			])
			.applyingFilter("CIMaskedVariableBlur",
							parameters: [
								kCIInputRadiusKey: lensBlur,
								"inputMask": textImage
							])
			.cropped(to: inputImage!.extent)
	}
	
	
	private func createTextImage() -> CIImage? {
		let textMaskFilter = TextMask()
		textMaskFilter.setValue(inputImage!, forKey: kCIInputImageKey)
		textMaskFilter.setValue(text!, forKey: TextMask.inputTextKey)
		textMaskFilter.setValue(font!, forKey: TextMask.fontKey)
		textMaskFilter.setValue(alignment, forKey: TextMask.alignmentKey)
		return textMaskFilter.outputImage
			
	}
	
	
}
