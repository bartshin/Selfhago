//
//  TextMask.swift
//  Selfhago
//
//  Created by bart Shin on 23/07/2021.
//

import UIKit
import CoreImage

class TextMask: CIFilter {
	
	static let inputTextKey = "text"
	static let fontKey = "font"
	static let alignmentKey = "alignment"
	private var inputImage: CIImage?
	private var text: String?
	private var font: UIFont = .systemFont(ofSize: 20)
	private var alignment: Alignment = .center
	
	
	override func setValue(_ value: Any?, forKey key: String) {
		if key == kCIInputImageKey,
		   let image = value as? CIImage {
			inputImage = image
		}
		else if key == Self.inputTextKey,
		   let inputText = value as? String {
			text = inputText
		}
		else if key == Self.fontKey,
				let font = value as? UIFont {
			self.font = font
		}
		else if key == Self.alignmentKey,
				let alignment = value as? Alignment{
			self.alignment = alignment
		}
		
	}
	
	override var outputImage: CIImage? {
		guard inputImage != nil,
			text != nil else {
			return nil
		}
		let label = UILabel()
		let normalizeFactor =  min(max(min(inputImage!.extent.size.width, inputImage!.extent.size.height) / 300, 1.0), 20.0)
		
		let normalizedFont = UIFont(
			descriptor: font.fontDescriptor,
			size: font.pointSize * normalizeFactor)
		switch alignment {
			case .topLeft, .bottomLeft:
				label.textAlignment = .left
			case .center:
				label.textAlignment = .center
			case .topRight, .bottomRight:
				label.textAlignment = .right
		}
		label.text = text!
		label.font = normalizedFont
		label.numberOfLines = 0
		label.sizeToFit()
		
		label.textColor = .white
		UIGraphicsBeginImageContextWithOptions(
			label.frame.size,
			true,
			1)
		
		label.layer.render(in: UIGraphicsGetCurrentContext()!)
		
		guard let uiImage = UIGraphicsGetImageFromCurrentImageContext(),
			  let labelImage = CIImage(image: uiImage) else {
			return nil
		}
		UIGraphicsEndImageContext()
		
		let labelSize = labelImage.extent.size
		let textOrigin = getOffset(for: labelSize)
		
		let transformedImage = labelImage.transformed(by: .init(translationX: textOrigin.x, y: textOrigin.y))
		return transformedImage
	}
	
	private func getOffset(for labelSize: CGSize) -> CGPoint {
		switch alignment {
			case .bottomLeft:
				return CGPoint(x: inputImage!.extent.minX,
							   y: inputImage!.extent.minY)
			case .bottomRight:
				return CGPoint(x: inputImage!.extent.maxX - labelSize.width,
							   y: inputImage!.extent.minY)
			case .center:
				return CGPoint(x: inputImage!.extent.midX - labelSize.width/2,
							   y: inputImage!.extent.midY - labelSize.height/2)
			case .topLeft:
				return CGPoint(x: inputImage!.extent.minX,
							   y: inputImage!.extent.maxY - labelSize.height)
			case .topRight:
				return CGPoint(x: inputImage!.extent.maxX - labelSize.width,
							   y: inputImage!.extent.maxY - labelSize.height)
				
		}
	}
	
	enum Alignment: String, CaseIterable {
		case topLeft
		case topRight
		case center
		case bottomLeft
		case bottomRight
	}
}

