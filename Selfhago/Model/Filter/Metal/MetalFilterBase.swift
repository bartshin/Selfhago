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

#if !arch(i386) && !arch(x86_64)

import Metal
import MetalKit




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
	}
	
	override func textureInvalid() -> Bool
	{
		if let textureDescriptor = textureDescriptor,
		   (textureDescriptor.width != Int(inputWidth)  ||
			textureDescriptor.height != Int(inputHeight))
		{
			return true
		}
		
		return false
	}
}

class MetalImageFilter: MetalFilter
{
	var inputImage: CIImage?
	

	override func textureInvalid() -> Bool
	{
		if let textureDescriptor = textureDescriptor,
		   let inputImage = inputImage ,
		   (textureDescriptor.width != Int(inputImage.extent.width)  ||
			textureDescriptor.height != Int(inputImage.extent.height))
		{
			return true
		}
		
		return false
	}
	
	override init(functionName: String) {
		super.init(functionName: functionName)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

// MARK: Base class
/// `MetalFilter` is a Core Image filter that uses a Metal compute function as its engine.
/// This version supports a single input image and an arbritrary number of `NSNumber`
/// parameters. Numeric parameters require a properly set `kCIAttributeIdentity` which
/// defines their buffer index into the Metal kernel.
class MetalFilter: CIFilter, MetalRenderable
{
	private let device: MTLDevice = MTLCreateSystemDefaultDevice()!
	private let colorSpace = CGColorSpaceCreateDeviceRGB()
	
	var ciContext: CIContext!
	
	private lazy var commandQueue: MTLCommandQueue =
		{
			[unowned self] in
			
			return self.device.makeCommandQueue()
		}()!
	
	private lazy var defaultLibrary: MTLLibrary =
		{
			[unowned self] in
			return self.device.makeDefaultLibrary()!
		}()
	
	private var pipelineState: MTLComputePipelineState!
	
	private let functionName: String
	
	private var threadsPerThreadgroup: MTLSize!
	
	private var threadgroupsPerGrid: MTLSize?
	
	private(set) var textureDescriptor: MTLTextureDescriptor?
	private var kernelInputTexture: MTLTexture?
	private var kernelOutputTexture: MTLTexture?
	
	override var outputImage: CIImage!
	{
		if textureInvalid()
		{
			self.textureDescriptor = nil
		}
		
		if ciContext == nil {
			ciContext = CIContext(mtlDevice: device, options: [.cacheIntermediates: false])
		}
		
		if let imageFilter = self as? MetalImageFilter,
		   let inputImage = imageFilter.inputImage
		{
			return createImageFromShader(width: inputImage.extent.width,
										  height: inputImage.extent.height,
										  inputImage: inputImage)
		}
		
		if let generatorFilter = self as? MetalGeneratorFilter
		{
			return createImageFromShader(width: generatorFilter.inputWidth,
										  height: generatorFilter.inputHeight,
										  inputImage: nil)
		}
		
		return nil
	}
	
	init(functionName: String)
	{
		self.functionName = functionName
		
		super.init()
		
		guard let kernelFunction = defaultLibrary.makeFunction(name: self.functionName) else {
			fatalError("Fail to find metal function \(functionName)")
		}
		
		do
		{
			pipelineState = try self.device.makeComputePipelineState(function: kernelFunction)
			
			let maxTotalThreadsPerThreadgroup = Double(pipelineState.maxTotalThreadsPerThreadgroup)
			let threadExecutionWidth = Double(pipelineState.threadExecutionWidth)
			
			let threadsPerThreadgroupSide = stride(from: 0, to: Int(sqrt(maxTotalThreadsPerThreadgroup)), by: 1).reduce(16)
				{
				return (Double($1 * $1) / threadExecutionWidth).truncatingRemainder(dividingBy: 1) == 0 ? $1 : $0
				}
			
			threadsPerThreadgroup = MTLSize(width:threadsPerThreadgroupSide,
											height:threadsPerThreadgroupSide,
											depth:1)
		}
		catch
		{
			assertionFailure("Unable to create pipeline state for kernel function \(functionName)")
			return
		}
		
		
		
		if !(self is MetalImageFilter) && !(self is MetalGeneratorFilter)
		{
			fatalError("MetalFilters must subclass either MetalImageFilter or MetalGeneratorFilter")
		}
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	func textureInvalid() -> Bool
	{
		fatalError("textureInvalid() not implemented in MetalFilter")
	}
	
	func createImageFromShader(width: CGFloat, height: CGFloat, inputImage: CIImage?) -> CIImage?
	{
		initTextureDescriptorIfNeeded(width: width,
									  height: height)
		
		guard let commandBuffer = commandQueue.makeCommandBuffer()  else {
			assertionFailure("Fail to make command buffer for \(functionName)")
			return nil
		}
	
		renderInputImageIfNeeded(commandBuffer: commandBuffer)
		guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
			assertionFailure("Fail to create commandEncoder")
			return nil
		}
		commandEncoder.setComputePipelineState(pipelineState)
		setFloatArgument(to: commandEncoder)
		
		setColorArgument(to: commandEncoder)
		
		setTexture(to: commandEncoder)
		
		commandEncoder.dispatchThreadgroups(threadgroupsPerGrid!,
											threadsPerThreadgroup: threadsPerThreadgroup)
		
		commandEncoder.endEncoding()
		
		commandBuffer.commit()
		
		return CIImage(mtlTexture: kernelOutputTexture!,
					   options: [CIImageOption.colorSpace: colorSpace])
			
	}
	
	private func initTextureDescriptorIfNeeded(width: CGFloat, height: CGFloat) {
		if textureDescriptor == nil
		{
			textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
																		 width: Int(width),
																		 height: Int(height),
																		 mipmapped: false)
			textureDescriptor!.usage = [.shaderRead, .shaderWrite]
			kernelInputTexture = device.makeTexture(descriptor: textureDescriptor!)
			kernelOutputTexture = device.makeTexture(descriptor: textureDescriptor!)
			
			threadgroupsPerGrid = MTLSize(
				width: textureDescriptor!.width / threadsPerThreadgroup.width,
				height: textureDescriptor!.height / threadsPerThreadgroup.height,
				depth: 1)
		}
	}
	
	private func renderInputImageIfNeeded(commandBuffer: MTLCommandBuffer) {
		if let imageFilter = self as? MetalImageFilter,
		   let inputImage = imageFilter.inputImage
		{
			ciContext.render(inputImage,
							 to: kernelInputTexture!,
							 commandBuffer: commandBuffer,
							 bounds: inputImage.extent,
							 colorSpace: colorSpace)
		}
		
	}
	
	private func setFloatArgument(to commandEncoder: MTLComputeCommandEncoder) {
		
		// populate float buffers using kCIAttributeIdentity as buffer index
		for inputKey in inputKeys
		{
			if let attribute = attributes[inputKey] as? [String:Any],
			   let bufferIndex = attribute[kCIAttributeIdentity] as? Int,
			   let bufferValue = value(forKey: inputKey) as? CGFloat
			{
				var floatValue = Float(bufferValue)
				commandEncoder.setBytes(&floatValue, length: MemoryLayout<Float>.stride, index: bufferIndex)
			}
		}
	}
	
	private func setColorArgument(to commandEncoder: MTLComputeCommandEncoder) {
		// populate color buffers using kCIAttributeIdentity as buffer index
		for inputKey in inputKeys where (attributes[inputKey] as? [String: Any])?[kCIAttributeClass] as? String == "CIColor"
		{
			if let bufferIndex = (attributes[inputKey] as! [String:AnyObject])[kCIAttributeIdentity] as? Int,
			   let bufferValue = value(forKey: inputKey) as? CIColor
			{
				
				var color = SIMD4<Float>(Float(bufferValue.red),
										 Float(bufferValue.green),
										 Float(bufferValue.blue),
										 Float(bufferValue.alpha))
				
				commandEncoder.setBytes(&color, length: MemoryLayout<simd_float4>.stride, index: bufferIndex)
			}
		}
	}
	
	private func setTexture(to commandEncoder: MTLComputeCommandEncoder) {
		if self is MetalImageFilter
		{
			commandEncoder.setTexture(kernelInputTexture, index: 0)
			commandEncoder.setTexture(kernelOutputTexture, index: 1)
		}
		else if self is MetalGeneratorFilter
		{
			commandEncoder.setTexture(kernelOutputTexture, index: 0)
		}
	}
}

#else
class MetalFilter: CIFilter
{
}

#endif

protocol MetalRenderable {
	
}
