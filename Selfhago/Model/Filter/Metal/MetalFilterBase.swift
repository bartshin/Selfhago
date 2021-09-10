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

//#if !arch(i386) && !arch(x86_64)

import Metal
import MetalKit
import Alloy

// MARK: MetalFilter types
class MetalGeneratorFilter: MetalFilter
{
	var inputWidth: CGFloat = 640
	var inputHeight: CGFloat = 640
	
	override func setValue(_ value: Any?, forKey key: String) {
		
		if key == kCIInputExtentKey,
		   let size = value as? CGSize {
			inputWidth = size.width
			inputHeight = size.height
		}
		else if key == Self.sourceTextureKey {
			sourceTexture = value as? MTLTexture
		}
		else if key == Self.destinationTextureKey {
			destinationTexture = value as? MTLTexture
		}
	}
	
	override func textureInvalid() -> Bool
	{
		if let inputTextureSize = sourceTexture?.size,
		   (inputTextureSize.width == Int(inputWidth) ||
			inputTextureSize.height == Int(inputHeight) )
		{
			return false
		}
		
		return true
	}
}

class MetalImageFilter: MetalFilter
{
	var inputImage: CGImage?
	
	override func textureInvalid() -> Bool
	{
		if let inputImageWidth = inputImage?.width,
		   let inputImageHeight = inputImage?.height,
			let inputTextureSize = sourceTexture?.size,
		   (inputTextureSize.width == Int(inputImageWidth) ||
			inputTextureSize.height == Int(inputImageHeight) )
		{
			return false
		}
		
		return true
	}
	
	override func setValue(_ value: Any?, forKey key: String) {
		
		if key == Self.sourceTextureKey {
			sourceTexture = value as? MTLTexture
		}
		else if key == Self.destinationTextureKey {
			destinationTexture = value as? MTLTexture
		}
	}
}

// MARK: Base class
/// `MetalFilter` is a Core Image filter that uses a Metal compute function as its engine.
/// This version supports a single input image and an arbritrary number of `NSNumber` or `CIColor`
/// parameters.  Parameters require a properly set `kCIAttributeIdentity` which
/// defines their buffer index into the Metal kernel.
class MetalFilter: CIFilter, MetalRenderable
{
	
	static let sourceTextureKey = "sourceTexture"
	static let destinationTextureKey = "destinationTexture"
	private let colorSpace = CGColorSpaceCreateDeviceRGB()
	private lazy var pipelineState: MTLComputePipelineState = {
		let constantValues = MTLFunctionConstantValues()
		constantValues.set(deviceSupportsNonuniformThreadgroups, at: 0)
		do {
			return try context.library(for: .main).computePipelineState(function: functionName, constants: constantValues)
		}catch {
			fatalError("Unable to create pipeline state for kernel function \(functionName)")
		}
	}()
	private var deviceSupportsNonuniformThreadgroups = false
	fileprivate var sourceTexture: MTLTexture?
	fileprivate var destinationTexture: MTLTexture?
	open var functionName: String {
		fatalError()
	}
	var context: MTLContext! {
		didSet {
			deviceSupportsNonuniformThreadgroups = context.device.supports(feature: .nonUniformThreadgroups)
		}
	}
	
	override init()
	{
		super.init()
		guard (self is MetalImageFilter) || (self is MetalGeneratorFilter) else
		{
			fatalError("MetalFilters must subclass either MetalImageFilter or MetalGeneratorFilter")
		}
	}
	
	func commit(completion: @escaping (MTLTexture?) -> Void) {
		do {
			try context.schedule { commandBuffer in
				commandBuffer.compute { encoder in
					encoder.label = String(functionName)
					encoder.setTextures(sourceTexture, destinationTexture)
					setFloatArgument(to: encoder)
					setColorArgument(to: encoder)
					setFloatArray(to: encoder)
					setFloat4Array(to: encoder)
					if deviceSupportsNonuniformThreadgroups {
						encoder.dispatch2d(state: pipelineState,
										   exactly: destinationTexture!.size)
					}else {
						encoder.dispatch2d(state: pipelineState,
										   covering: destinationTexture!.size)
					}
					commandBuffer.addScheduledHandler { [weak weakSelf = self] _ in
						completion(weakSelf?.destinationTexture)
					}
				}
			}
		}catch {
			assertionFailure("Fail to excute metal function \(functionName)")
		}
	}
	
	func syncCommit(completion: @escaping (MTLTexture?) -> Void) {
		do {
			try context.scheduleAndWait { commandBuffer in
				commandBuffer.compute { encoder in
					encoder.label = String(functionName)
					encoder.setTextures(sourceTexture, destinationTexture)
					setFloatArgument(to: encoder)
					setColorArgument(to: encoder)
					setFloatArray(to: encoder)
					setFloat4Array(to: encoder)
					if deviceSupportsNonuniformThreadgroups {
						encoder.dispatch2d(state: pipelineState,
										   exactly: destinationTexture!.size)
					}else {
						encoder.dispatch2d(state: pipelineState,
										   covering: destinationTexture!.size)
					}
				}
			}
		}catch {
			assertionFailure("Fail to excute metal function \(functionName)")
		}
		completion(destinationTexture)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	func textureInvalid() -> Bool
	{
		fatalError("textureInvalid() not implemented in MetalFilter")
	}
	
	override var outputImage: CIImage? {
		fatalError("Metal Image Filter create output texture use getOutputTexture instead")
	}
	
	private func setFloatArgument(to encoder: MTLComputeCommandEncoder) {
		
		// populate float buffers using kCIAttributeIdentity as buffer index
		for inputKey in inputKeys
		{
			if let attribute = attributes[inputKey] as? [String:Any],
			   let bufferIndex = attribute[kCIAttributeIdentity] as? Int,
			   let bufferValue = value(forKey: inputKey) as? CGFloat
			{
				encoder.setValue(Float(bufferValue), at: bufferIndex)
			}
		}
	}
	
	private func setColorArgument(to encoder: MTLComputeCommandEncoder) {
		// populate color buffers using kCIAttributeIdentity as buffer index
		for inputKey in inputKeys where (attributes[inputKey] as? [String: Any])?[kCIAttributeClass] as? String == "CIColor"
		{
			if let bufferIndex = (attributes[inputKey] as! [String:AnyObject])[kCIAttributeIdentity] as? Int,
			   let bufferValue = value(forKey: inputKey) as? CIColor
			{
				
				let color = SIMD4<Float>(Float(bufferValue.red),
										 Float(bufferValue.green),
										 Float(bufferValue.blue),
										 Float(bufferValue.alpha))
				encoder.setValue(color, at: bufferIndex)
			}
		}
	}
	
	private func setFloatArray(to encoder: MTLComputeCommandEncoder) {
		
		for inputKey in inputKeys where (attributes[inputKey] as? [String: Any])?[kCIAttributeClass] as? String == "FloatArray"
		{
			if let bufferIndex = (attributes[inputKey] as! [String:AnyObject])[kCIAttributeIdentity] as? Int,
			   let bufferValue = value(forKey: inputKey) as? [Float]
			{
				encoder.setValue(bufferValue, at: bufferIndex)
			}
		}
	}
	
	private func setFloat4Array(to encoder: MTLComputeCommandEncoder) {
		for inputKey in inputKeys where (attributes[inputKey] as? [String: Any])?[kCIAttributeClass] as? String == "Float4Array"
		{
			if let bufferIndex = (attributes[inputKey] as! [String:AnyObject])[kCIAttributeIdentity] as? Int,
			   let bufferValue = value(forKey: inputKey) as? [SIMD4<Float>]
			{
				
				encoder.setValue(bufferValue, at: bufferIndex)
			}
		}
	}
}

protocol MetalRenderable {
	
}
